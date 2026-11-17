# Testing — Focus Areas

Generic baseline. `/agent-review:init` appends this repo's test conventions (runner, layout,
mocking idioms); keep both.

**Prefer pure-function unit tests**

- Business and domain logic should be extracted out of UI/handler code into plain functions and
  tested directly, rather than asserted through a rendered surface or an HTTP round trip
- Look for: new logic that is only reachable through a component or endpoint, with no seam to test

**Use the repo's existing test framework and idioms**

- Match the repo's test runner, assertion style, mocking helpers, and import conventions. Do not
  assume a framework, rendering harness, or helper library that the repo does not already depend on
- Look for: tests introducing a second runner or harness; imports of libraries absent from the
  manifest

**Mock at module/external boundaries**

- External services (databases, third-party APIs, mail, payments, LLMs) are mocked at the module
  boundary, not by patching global network primitives ad hoc
- Look for: real network or filesystem access in unit tests; mocks that drift from the real
  signature; over-mocking that leaves the logic under test unexercised

**Determinism**

- Time-dependent logic uses the runner's fake-timer/clock control rather than real system time.
  Random values are seeded or injected
- Look for: tests that depend on the current date, timezone, ordering of a map/set, or on another
  test having run first

**Coverage of the shape of the input**

- Every new test should exercise: empty, zero / one / many, boundary values, and at least one happy
  path
- Look for: tests that only assert the happy path; parameters whose invalid values are never tested

**Error paths**

- Validation rejections, rejected promises, timeouts, and the failure branches of domain functions
  are tested, not just success
- Look for: `catch` branches with no covering test

**Test placement and naming**

- Follow the repo's convention for where tests live and how they're named
- Test names describe the behavior asserted, not the function name alone

**Quality gates**

- The repo's test, type-check, lint, and format commands must all pass
- Look for: skipped or `.only` tests left behind; loosely-typed mocks that defeat type checking;
  assertions that can never fail (e.g. asserting on the mock's own return)

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## Repo-specific: familylife-gift-cards

**Runner and layout**

- RSpec only (no Minitest). `spec/rails_helper.rb` loads `rspec/rails`, runs `ActiveRecord::Migration.maintain_test_schema!` and includes `FactoryBot::Syntax::Methods` (so write `create(:issuance)`, not `FactoryBot.create`). `spec/spec_helper.rb` uses DatabaseCleaner (`:transaction`, truncation before the suite), WebMock (`webmock/rspec`) and `verify_partial_doubles = true`.
- Layout: `spec/models/<model>_spec.rb`, `spec/controllers/*_spec.rb`, `spec/controllers/admin/<resources>_controller_spec.rb` for ActiveAdmin, `spec/controllers/api/v1/<name>_controller_spec.rb` for the API, `spec/factories/*.rb` for factories. There are no request, system, view or job specs. Look for: a new test type or folder without a reason.
- Type is inferred from the folder (`infer_spec_type_from_file_location!`). `Devise::Test::ControllerHelpers` is included for `type: :controller` and `type: :view`. Controller specs sign in with `sign_in @user` (see `spec/controllers/admin/issuances_controller_spec.rb`). Do not stub `current_user` instead.

**Admin (ActiveAdmin) specs**

- Pattern: `RSpec.describe Admin::IssuancesController, type: :controller` with `render_views`, `require "capybara/rails"`, `sign_in`, then `get :index` and Capybara matchers on `response.body` (`have_content`, `have_field("Batch")`). Match this for new admin resources and pages.
- Each admin screen should have at least `index`, `new`/`edit` form fields, and any `member_action`. The `issue` action is tested with `post :issue, params: {id: ...}` and checks `change(GiftCard, :count).by(quantity)`.
- Look for: a new `member_action`, `action_item`, custom `index` column or `form` input in `app/admin/*.rb` with no spec. Look for: new `app/admin/*.rb` files with no matching `spec/controllers/admin/*_spec.rb` (today `batches`, `dashboard`, `gift_cards` and `issuances` have one; `api_keys` has none, so new work there should add one).
- Look for: leftover `puts response.body` debug lines (they exist in `issuances_controller_spec.rb`). Do not copy them into new specs.
- `CustomAuthorization` is tested in `spec/models/custom_authorization_spec.rb` with `CustomAuthorization.new(Issuance, create(:user))` and `authorized?(:write, ...)`. Any change to the adapter needs a case for each branch: `:read`, issued `Issuance`, unissued `Issuance`, other model.

**API specs**

- `spec/controllers/api/v1/gift_cards_controller_spec.rb` is the model to copy: `request.env["HTTP_ACCEPT"] = "application/json"`, `get :show` / `put :update` with `params: {access_token: ..., id: certificate, format: :json}`, then `have_http_status` and `JSON.parse(response.body)`.
- Every API change should test: valid token as a param, valid token in `HTTP_AUTHORIZATION` (`token ...` and `Bearer ...`), missing token (401), bad token (401), unknown certificate (404), and the exact `error` string for 403 cases. Compare success bodies to `JSON.parse(gift_card.to_json)`, and assert specific keys for any new field.
- Look for: a changed error message or status without the matching test edit. Contract details belong to `rules/api-contracts.md`.

**Model specs**

- Each model has `spec/models/<model>_spec.rb`. Each one asserts `ransackable_attributes` are real columns (`column_names`) and `ransackable_associations` are real methods. Look for: a new column or association added to a ransackable list with no change to the spec if the model is new. Keep both assertions for new models.
- `spec/models/issuance_spec.rb` covers the AASM transitions (`preview!`, `issue!`), `#to_s`, `#create_gift_cards`, `#set_allocated_certificates` (stubbing `largest_existing_number_in_certificate`), and `#leading_certificate_4_digit_number`. The `#largest_existing_number_in_certificate` context is empty. Look for: certificate numbering changes that do not fill it in. Cover: no existing cards (starts at 1), existing cards with the same prefix, other prefixes ignored, and another `previewing` issuance with allocated numbers.

**Factories**

- Factories are in `spec/factories` (files are named `api_key.rb`, `batches.rb`, `gift_cards.rb`, `issuances.rb`, `user.rb`). Batches use child factories `:batch_paid` (type `paid_full_price`, price 300) and `:batch_dept` (type `type_dept`, `gl_code`, `dept`). `:gift_card` builds an `issuance` and takes the batch from it. `:user` uses Faker with `Faker::Internet.unique.username`.
- Look for: inline `GiftCard.create!` / `Batch.new(...)` in specs when a factory exists; new factory traits for a state that a child factory already covers; new fixtures (the app has none).

**Determinism**

- Dates in factories use relative times (`1.month.from_now`). Expiry tests set `1.day.ago`. Look for: hard-coded dates, or tests that rely on the real clock near midnight. Use `travel_to` for any new date boundary (expiry day, `Date.current`).
- Certificate numbers in specs depend on database contents. Look for: tests that assume the first certificate is `...00010` without a clean table. The transaction strategy covers it, so do not break it with `before(:all)` data.
- WebMock is on, so any real HTTP call fails. The app makes none today. Okta is not hit in specs. Look for: stubs that skip `OmniAuth`'s test mode in new session specs (`spec/controllers/sessions_controller_spec.rb` is the pattern).

**Commands (the repo's real gates)**

- CI (`.github/workflows/ruby.yml`): `bundle exec brakeman -A -q --no-pager`, `bundle exec standardrb --format simple`, `bundle exec rails db:create`, `bundle exec rails db:schema:load`, `bundle exec rspec --color`, then a Codecov upload with `fail_ci_if_error: true`. Non-required: `bin/bundler-audit check --update` and `bin/importmap audit`.
- Local (`bin/ci` runs `config/ci.rb`): `env CI=true RAILS_ENV=test bundle exec rspec --color`.
- Coverage uses simplecov with the Cobertura formatter only when `CI=true`. Look for: large new code paths with no spec (Codecov will show it).

## Mined from PR history

Rules drawn from all 25 merged PRs (the repo's whole history). Each one lists the PRs it came from.

- API specs assert the status and the exact JSON `error` string, as `spec/controllers/api/v1/gift_cards_controller_spec.rb` has done since #59, never the status alone. Certificate numbering changes in `app/models/issuance.rb` need specs: the reviewer asked for them in #5, and the `#largest_existing_number_in_certificate` context in `spec/models/issuance_spec.rb` is still empty.
  <!-- evidence: PR #5, #59 -->
