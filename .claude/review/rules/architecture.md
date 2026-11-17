# Architecture — Focus Areas

Generic baseline. `/agent-review:init` appends the repo-specific concerns; keep both.

**Layering & boundaries**

- Business logic lives in testable modules, not inline in entry points (route/page/controller/CLI
  handlers). Entry points compose and delegate
- Server-only code stays out of code paths that ship to a client or untrusted runtime
- Look for: domain math embedded in view code; a module reaching across layers it shouldn't know
  about; new circular dependencies

**Placement & structure**

- New files land where the existing convention says they belong; shared code goes to the shared
  location only when it is genuinely used by more than one feature
- Look for: one-off code dropped into a "shared"/"common"/"utils" bucket; parallel structures that
  duplicate an existing module instead of extending it; new top-level directories

**Pattern consistency**

- The change should look like the code around it. Deviating is fine when the existing pattern is
  what's being fixed — but then it should be fixed consistently, not forked
- Look for: a second way of doing something the codebase already does one way (data fetching, error
  handling, configuration, logging); framework features reimplemented by hand

**State & data flow**

- Cached/derived state has a clear owner, and writes invalidate or update what they affect
- Look for: the same state maintained in two places; refetching in an effect what a cache already
  owns; values threaded through three or more layers that would be better read closer to use

**Effects & lifecycle**

- Look for: effects whose dependency list omits referenced values (stale closures); work in an
  effect that belongs in an event handler or a derived value; subscriptions and timers without
  cleanup

**Concurrency & performance shape**

- Look for: sequential awaits on independent work that could run concurrently; N+1 query patterns;
  unbounded loops over remote calls; work done per-item that could be batched

**Error handling & resilience**

- Look for: swallowed errors (empty catch, error logged and ignored); failures that leave state
  half-written; missing error/loading boundaries on user-facing surfaces; retries without backoff or
  idempotency

**Technical debt**

- Weigh debt added against debt removed. A refactor that only moves code without improving clarity
  is neutral, not positive. When a convention is ambiguous, raise it as a question rather than a
  blocking finding

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## Repo-specific: familylife-gift-cards

This is a small Rails 8.1 app. It uses full-stack `ActionController::Base`, ActiveAdmin for all staff screens, and a tiny JSON API. It deploys as one Docker image (Thruster + Puma) to AWS ECS, staging and production. Keep it small.

**Layering: where logic lives**

- Domain rules live in models. `Issuance` owns certificate allocation and gift card creation (`set_allocated_certificates`, `leading_certificate_4_digit_number`, `largest_existing_number_in_certificate`, `create_gift_cards`). `GiftCard#expired?` owns expiry. Controllers and admin blocks compose and delegate.
- `app/admin/*.rb` should hold only ActiveAdmin DSL (`permit_params`, `index`, `form`, `filter`, `member_action`, `action_item`, `before_create`). Look for: money math, certificate building, or state changes inlined in an `index` block or `member_action`. `app/admin/issuances.rb` already has some inline logic (the "used" percentage column, and `member_action :issue` doing `resource.issue!` then a separate `resource.update(issuer_id:, issued_at:)`). Do not add more.
- `Api::V1::GiftCardsController#update` holds the redemption rule inline (the `<= 1` check, expiry check, `- 2`). If this logic grows, move it to a `GiftCard` method such as a `redeem!` that can be locked and unit-tested. Do not copy the rule into a second place.
- `app/admin/active_admin/views_helper.rb` is the only place for admin view helpers, and it reopens `ActiveAdmin::ViewHelpers`. Do not add helpers to `app/helpers` for admin screens.
- `lib/log/logger*` and `config/initializers/lograge.rb` own logging. Do not add a second logger or another JSON format.

**Placement and structure**

- Models in `app/models`, admin resources in `app/admin`, API controllers in `app/controllers/api/v1`. The API base class `Api::V1::ApplicationController` is the one place for token auth. New API versions or namespaces need a clear reason.
- `CustomAuthorization` sits in `app/models/custom_authorization.rb` (not `app/admin`). Keep new ActiveAdmin authorization rules in that one adapter instead of scattering `if` checks across admin files.
- `import.rb` at the repo root is a one-off CSV import that runs `delete_all` on `Batch`, `GiftCard` and `Issuance`. Treat it as a script, not app code. Look for: `require`s of it, or new code that depends on it.
- No new top-level directories, services, or `app/services` layer for what two model methods can do.

**State machine**

- `Issuance` uses AASM on `status`: `configuring`, `previewing`, `issued`. `after_create { preview! }` moves new records to `previewing` and `before_save` recomputes allocated certificates only while `previewing?`. Look for: new states or events that skip this flow; new code that writes `status` with `update_column` outside tests; callbacks that run `set_allocated_certificates` in other states; changes that make `issue` (`transitions from: :issued, to: :issued`) do real work twice.
- `create_gift_cards` runs as an `after:` hook on the `issue` transition and uses `first_or_initialize` per certificate, so a retry does not duplicate cards. Keep it idempotent.

**Concurrency and performance shape**

- Certificate numbers come from `largest_existing_number_in_certificate`: scan `GiftCard` and other previewing `Issuance` rows, take the max, add one. Two people previewing at once can compute the same range. `GiftCard` validates `certificate` uniqueness in Ruby only. There is no unique DB index. Look for: changes that widen the race (longer gap between preview and issue, more writers, background jobs) without a lock or a unique index.
- `Issuance#create_gift_cards` does one `where(...).first_or_initialize` plus one `save!` per card, each with its own uniqueness query. That is fine for the current quantities. Look for: larger batches, or extra queries inside that loop.
- Admin `index` blocks run per-row counts (`issuance.gift_cards.where(registrations_available: 0).count` in `app/admin/issuances.rb`). Look for: new per-row queries on index pages for `GiftCard` (the biggest table). Prefer `includes` or a grouped query.
- `GiftCard.find_by(certificate:)` is hit on every API call and has no index on `certificate`. Look for: new lookups on unindexed columns (`certificate`, `gl_code`, `gift_card_type`).

**Error handling and resilience**

- The API returns JSON errors for 401, 403 and 404 and nothing else. `@gift_card.update(...)` in `#update` ignores its return value, so a failed validation still renders 200 with the lowered count in the body, even though nothing was saved. ERT then books a redemption that did not happen. Look for: new `update` or `save` calls whose result is dropped.
- `member_action :issue` runs `issue!` and then a second `update`. If the second call fails, the issuance is `issued` with no `issuer_id`. Look for: more multi-step writes in admin actions without a transaction.
- `MonitorsController#lb` is the health check and is excluded from lograge by `FamilylifeGiftCards::HEALTHCHECK_ACTION`. Do not add slow work to it.

**Front end**

- JS surface is tiny (importmap + Stimulus + Sprockets). Look for: a bundler, a new JS framework, or a build step. A new Stimulus controller is fine. Anything heavier is an architecture decision.
- The batch form reloads the whole page through inline JS (`reload_js_based_on_gift_card_type`) to swap fields. Keep that pattern for ActiveAdmin forms instead of adding client-side form frameworks.

**Technical debt to not make worse**

- No foreign keys, integer FK columns, and no unique index on `certificate`. New tables or columns should not copy that habit without a reason. Raise a missing FK or index as a question, not a blocker, unless the diff depends on it.

## Mined from PR history

Rules drawn from all 25 merged PRs (the repo's whole history). Each one lists the PRs it came from.

- `MonitorsController#lb` (`/monitors/lb`) is the load-balancer health check. Keep it public, fast, and a plain `"OK"`. It skips the database on staging on purpose (`User.first unless Rails.env.staging?`) so the staging Neon database can scale to zero. Do not "fix" that by adding a query on staging. If the path or action changes, update `FamilylifeGiftCards::HEALTHCHECK_PATH` and `HEALTHCHECK_ACTION` in `config/application.rb` and check every place that uses them (`ssl_options`, `host_authorization`, `silence_healthcheck_path`, lograge, the Datadog span filter).
  <!-- evidence: PR #5, #40, #69 -->
