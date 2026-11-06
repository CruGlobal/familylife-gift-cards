# Data Integrity — Focus Areas

Generic baseline. This is where domain-specific data invariants belong once `/agent-review:init`
appends them; keep both.

**Access scoping at the data layer**

- Every query and mutation is scoped to the authenticated user/tenant/household. New tables,
  columns, or collections need matching access policies
- Look for: policy changes that widen a `where`/`using`/`with check` clause; queries filtered only
  in application code where a shared or admin connection bypasses the policy

**Validation at external boundaries**

- Payloads from HTTP requests, webhooks, queues, and third-party APIs are parsed against an explicit
  schema before use
- Look for: external JSON consumed without validation; fields read off an untyped/`any` value; types
  that have drifted from the actual storage shape

**Cache correctness**

- Every write that changes displayed data invalidates or updates the cache entry that serves it
- Look for: mutations with no invalidation; cache keys that omit an input which changes the result
  (filter, tenant/account id, date range), which serves stale or cross-scope data; optimistic
  updates that don't match the server's response shape or don't roll back on error

**Idempotency & retries**

- Sync jobs, webhook handlers, and queue consumers must not double-apply work on retry or replay
- Look for: blind inserts where an upsert on a stable external id is needed; no dedupe key; partial
  writes with no transaction or compensating action

**Numeric precision**

- Values where exactness matters (money, quantities, percentages) must not accumulate floating-point
  drift; round at the display boundary, never mid-calculation
- Look for: repeated rounding inside a pipeline; mixing units or currencies without conversion;
  aggregate totals recomputed differently in two places

**Date & time handling**

- Look for: non-deterministic "now" inside calculations (makes behavior untestable and
  timezone-fragile); naive local-time arithmetic across DST; inconsistent serialization formats
  across boundaries

**Null, undefined, and partial writes**

- An omitted field, an explicit null, and an empty string are three different writes. Be intentional
- Look for: whole objects spread into an insert/update without an explicit field allowlist; defaults
  applied in one code path but not another

**Aggregation over partial data**

- Look for: totals summed client-side over a paginated or filtered subset, silently ignoring rows
  beyond the page — prefer a server-computed aggregate

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## Repo-specific: familylife-gift-cards

Data lives in PostgreSQL 17 (`db/schema.rb`, Ruby format, `Schema[8.1]`). There are 5 app tables: `batches`, `gift_cards`, `issuances`, `users`, `api_keys` (plus `active_admin_comments`). There are no foreign keys. Relationship columns (`batch_id`, `issuance_id`, `creator_id`, `issuer_id`) are plain integers. Value and accounting rules for gift cards are in `rules/financial.md`. This file covers storage, schema and write safety.

**Schema and migrations**

- Migrations are in `db/migrate/` and use `ActiveRecord::Migration[7.2]` with `db/schema.rb` committed. Look for: a migration with no matching `db/schema.rb` change in the same PR, a `schema.rb` edit with no migration, or hand-edited schema versions.
- Look for: new relationship columns with no index (`gift_cards.batch_id`, `gift_cards.issuance_id` and `issuances.batch_id` are indexed; `issuances.creator_id` and `issuer_id` are not). Missing foreign keys are existing debt. Raise a new missing FK as a question, not a blocker.
- Look for: destructive migrations (`remove_column`, `drop_table`, `change_column` that narrows a type) on `gift_cards` or `issuances`. Issued data is the product. A card that was sold cannot be regenerated.

**Certificate uniqueness has no database backing**

- `GiftCard` has `validates :certificate, uniqueness: true` but there is no unique index on `gift_cards.certificate` (and no index on `certificate` at all). Two concurrent writers can both pass the validation.
- Look for: any new write path that creates `GiftCard` rows (admin, import, console task, API) without going through `Issuance#create_gift_cards`; `save(validate: false)` or `insert_all` / `upsert_all` on `GiftCard`; a change to `set_allocated_certificates` or `largest_existing_number_in_certificate` that could produce a duplicate or skip the "other previewing issuances" check.
- A PR that adds the unique index should deal with existing duplicates first (migration must check, not fail halfway).
- `certificate` is a string with a fixed shape: `<4-char prefix><5 digits>0`. Look for: code that treats it as an integer, strips leading zeros, or compares it after `to_i`.

**Issuance flow writes**

- `before_save { set_allocated_certificates if previewing? }` recomputes the whole `allocated_certificates` text on every save while previewing. Look for: extra `save` or `update` calls on a previewing issuance that would silently re-number its certificates (the admin could have copied the old range elsewhere).
- `allocated_certificates` is one text column joined with `CERTIFICATE_DISPLAY_SEPARATOR` (`", "`). Look for: code that splits on a different separator, or stores anything else in that column.
- `create_gift_cards` copies fields from `Batch` onto each `GiftCard` (`registrations_available`, `price`, `expiration_date`, `gift_card_type`, `isbn`, `associated_product`, `gl_code`). The copy is a snapshot. Editing a `Batch` later must not rewrite issued cards. Look for: new `Batch` fields that `GiftCard` should snapshot but `create_gift_cards` does not copy (or the reverse).
- `app/admin/issuances.rb` `member_action :issue` does `issue!` and then a separate `update(issuer_id:, issued_at: Time.now)`. Look for: more steps added without a transaction. Prefer `Time.current`.
- `quantity` is only validated with `numericality: {only_integer: true}`. Zero, negative, and huge values pass. Look for: code that depends on `quantity` being positive and bounded (`quantity.times` builds the whole list in memory).

**Mass assignment and field allowlists**

- Admin writes go through `permit_params` in `app/admin/*.rb`. `app/admin/gift_cards.rb` permits money and identity fields (`price`, `certificate`, `registrations_available`, `gl_code`, `expiration_date`, and `created_at`/`updated_at`). Look for: new columns added to a permit list by habit, and `permit_params :access_token, :user` style entries.
- API writes: `Api::V1::GiftCardsController#update` takes no body fields. It only changes `registrations_available`. Look for: anything that starts reading `params` for updates (`update(params...)`).
- `ransackable_attributes` and `ransackable_associations` on each model are a read allowlist for admin filters and search. Look for: sensitive columns added to them (`access_token` is already listed on `ApiKey`) and names that are not real columns (model specs check `column_names`).

**Defaults and nulls**

- `Batch` sets `registrations_available ||= 2` in `after_initialize`. `GiftCard` has no such default. Look for: nil `registrations_available` on a card. `GiftCard#expired?` already guards a nil `expiration_date`, and the API uses `registrations_available.to_i`. Keep that nil-safety.
- `price` is `decimal(8,2)` and nullable on both tables. Dept batches have a nil price. Look for: arithmetic or display on `price` with no nil check (`Issuance#to_s` guards it with `if price`).
- `ApiKey#generate_access_token` runs on `after_initialize` and `before_create` and skips when a token is present. Look for: changes that regenerate a token for a persisted key.
- `api_keys.user` is a plain string column, not a `belongs_to`. `Api::V1::ApplicationController` copies it to `@current_user`. Do not treat it as a `User` record.

**Dates and time**

- `expiration_date`, `begin_use_date`, `end_use_date` are `date` columns. `GiftCard#expired?` compares with `Date.current` (app time zone). Look for: `Date.today`, `Time.now` or `Time.zone.now` mixed in for these comparisons (the admin batch picker uses `Date.today`, and `issued_at: Time.now`). New code should use `Date.current` and `Time.current`.

**Destructive scripts**

- `import.rb` calls `Batch.delete_all` and more. Look for: any PR that runs it, wires it into a rake task, seed or deploy step, or copies its `delete_all` pattern into app code.
