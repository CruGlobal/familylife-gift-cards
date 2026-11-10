# Simplification & Reuse — Focus Areas

Generic baseline. `/agent-review:init` appends the repo-specific concerns; keep both.

This is an advisory lane. Its job is to make this diff smaller and simpler — not to restyle the
codebase, and not to propose generalizations. Report only cleanups the author can act on inside
this PR.

**Lane boundary** — neighboring lanes own the adjacent ground:

- Layering, placement, and pattern-consistency judgments belong to `architecture`
- Lint-level hygiene (unused imports, debug output, commented-out code) belongs to `standards`
- This lane owns code that need not exist: additions duplicating something the repo already has,
  abstractions with no second caller, computation the data path doesn't need, and code the PR
  adds but never exercises

**Severity cap — cleanups never block**

- Rate pure reuse/simplification/efficiency findings 1–4
- Use 5–6 only for substantial reimplementation of an existing, tested helper, or a demonstrable
  algorithmic problem on a data path that grows with users or records
- Never rate a pure cleanup ≥ 7 — the blocker machinery is for defects. The cross-cutting duty
  still applies: a real bug noticed while reading is reported at its honest severity

**Proof requirements** — every finding cites evidence the author can check, using your discovery
grep budget:

- A reuse claim names the existing helper at file:line, after you have read it and confirmed its
  semantics actually match this call site (arguments, edge cases, error behavior). A name-alike
  with different behavior is not a finding
- A duplication claim points at duplication this diff introduces; pre-existing duplication the
  change does not worsen is out of scope
- An efficiency claim names where the data comes from and why it can be large; no
  micro-optimizations, no complexity pedantry on collections that are bounded in practice
- A dependency-reuse claim cites the manifest entry for a library the repo already ships that
  does what the new code hand-rolls

**Reuse**

- Look for: a new helper, validator, formatter, or client wrapper that reimplements one that
  already exists in the repo's shared locations; a sibling file copy-pasted and lightly edited
  instead of extended; utility code hand-rolled despite an already-carried dependency that
  provides it

**Simplification**

- Look for: an abstraction with exactly one caller or one implementation (interface, base class,
  factory, registry) introduced by this diff; boolean parameters or config options no current
  caller sets; indirection added for cases that do not exist; a hand-rolled mechanism where the
  language or framework has a direct construct

**Efficiency**

- Look for: invariant work recomputed inside a loop; a query or fetch issued per item where the
  surrounding code already batches; a full-collection load used to read one row; repeated linear
  scans that a single keyed lookup structure would remove — on data that actually grows

**Dead weight**

- Look for: exports nothing imports, parameters no caller passes, branches no current input can
  reach — when this PR introduces them. Confirm with a repo-wide grep before flagging; absence
  from the diff is not absence from the codebase

**Finding budget.** Report at most 5 findings — the ones with the largest net line savings or
clearest wins. Suggestion density is what gets an advisory lane dismissed; if you found more than
5, keep the best and drop the rest silently.

<!-- init: extend this file with the repo's shared-helper locations (where utilities, validators, and formatters live — the directories to grep before accepting new ones) -->

## Repo-specific: familylife-gift-cards

This is a small app. Before accepting a new helper, grep these places first.

**Shared-helper locations to grep before accepting new ones**

- `app/models/gift_card.rb`: the type constants (`TYPE_PAID_HALF_PRICE`, `TYPE_PAID_FULL_PRICE`, `TYPE_PAID_OTHER`, `TYPE_DEPT`), `PAID_TYPES`, `TYPE_DESCRIPTIONS` (type to label) and `#expired?`. A new type list, label map, or "is it expired" check should reuse these.
- `app/models/issuance.rb`: `CERTIFICATE_DISPLAY_SEPARATOR`, `leading_certificate_4_digit_number`, `largest_existing_number_in_certificate`, `set_allocated_certificates`, `create_gift_cards`. Certificate building, splitting and numbering already live here.
- `app/models/batch.rb`: `#to_s` (description) is the admin display name, and the `after_initialize` default for `registrations_available`.
- `app/models/custom_authorization.rb`: the only ActiveAdmin authorization rule set.
- `app/admin/active_admin/views_helper.rb`: admin view helpers (`reload_js_based_on_gift_card_type`, `reload_js_hint`).
- `app/controllers/api/v1/application_controller.rb`: token lookup (`restrict_access`, `oauth_access_token`, `oauth_access_token_from_header`). `app/controllers/application_controller.rb`: `authenticate_active_admin_user!`, `after_sign_out_path_for`.
- `spec/factories/*.rb`: `:batch_paid`, `:batch_dept`, `:issuance`, `:gift_card`, `:user`, `:api_key`. New specs should use these.
- Gems already carried (see `Gemfile`): `activeadmin` and `activeadmin_addons` (currency, date picker, tag and number columns), `aasm` (state machine), `strip_attributes` (used in `User`), `faker`, `webmock`, `database_cleaner`. Hand-rolled versions of these are reuse findings.

**Reuse**

- Look for: a new string split on `", "` instead of `Issuance::CERTIFICATE_DISPLAY_SEPARATOR` (the min and max certificate columns in `app/admin/issuances.rb` already split it twice, so a third copy is a reuse finding).
- Look for: a new copy of the "no registrations" or "expired" checks in `Api::V1::GiftCardsController` or admin code, instead of one model method. Use `GiftCard#expired?` for expiry.
- Look for: a second token extraction in a new controller instead of `Api::V1::ApplicationController#restrict_access`.
- Look for: new admin column formatting that rebuilds what `activeadmin_addons` already gives (`as: :currency`, `tag_column`, `number_column`, `date_picker`).
- Look for: a new spec that builds records by hand when `:batch_paid`, `:batch_dept`, `:issuance` or `:gift_card` fit.

**Simplification**

- Look for: a service object, concern, decorator or presenter introduced for one caller. The app is models plus ActiveAdmin blocks plus one API controller.
- Look for: a new state in AASM or a status string column when the existing `configuring` / `previewing` / `issued` states or the `issued_at` timestamp would do.
- Look for: new settings or flags for gift card types no `GiftCard::TYPE_*` constant supports.
- Look for: redundant lookups. `Api::V1::GiftCardsController#show` already has `@gift_card` from the `before_action`. A re-query in the action is a cleanup (if the diff touches it).

**Efficiency**

- Look for: a new per-row query inside `app/admin/*.rb` `index` blocks on `GiftCard` or `Issuance` (those tables grow with every issuance). Prefer `includes`, a grouped count, or `counter_cache`.
- Look for: `GiftCard.all.where(...).pluck(:certificate)` style loads in new code. `largest_existing_number_in_certificate` already pulls all matching certificates to Ruby and takes the max. A cleanup could use a SQL aggregate, but only when the diff touches that method.
- Look for: loops that call `save!` per record when the existing `create_gift_cards` pattern (idempotent per certificate) is the right shape. Do not suggest `insert_all` here without noting that it skips the Ruby uniqueness validation.

**Dead weight**

- Look for: new `ransackable_attributes` or `permit_params` entries no admin screen uses, new `filter` lines for columns that do not exist, and new constants no code reads. Confirm with a repo-wide grep.
- Do not flag the existing scaffold comments in `app/admin/*.rb` or the `import.rb` script as dead weight. They are not part of the diff.
