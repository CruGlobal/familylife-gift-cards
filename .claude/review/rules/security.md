# Security — Focus Areas

Generic baseline. `/agent-review:init` appends the repo-specific concerns; keep both.

**Authentication & authorization boundaries**

- Every server endpoint, background job, and privileged action independently verifies the caller's
  identity — never trusts a user id, tenant id, or role passed in from the client
- Authorization is enforced at the data layer (row/tenant scoping, ACL check), not only by hiding UI
- Look for: endpoints added without a session/permission check; ownership checks that compare
  against client-supplied identifiers; policy changes that widen who can read or write a record

**Privileged clients & credentials**

- Admin/service-level clients that bypass normal access control must stay server-only and must never
  be importable from browser or otherwise untrusted code
- Look for: privileged clients imported into client-side modules; secrets read in code that ships to
  the browser; credentials committed to the repo or baked into build artifacts

**Secrets exposure**

- Server-only environment variables must not be exposed through client-visible prefixes, build-time
  inlining, or error payloads
- Look for: new environment-variable references; API keys or tokens in logs, error messages, HTTP
  responses, or analytics events

**Input validation & injection**

- Untrusted input (request bodies, query params, headers, webhooks, third-party payloads, file
  uploads) is validated against an explicit schema before use
- Look for: raw string interpolation into SQL/shell/HTML/templates; parsers fed unvalidated JSON;
  client-side validation with no server-side counterpart; unbounded sizes and counts

**Cross-site and browser-surface risks**

- Look for: raw-HTML injection sinks; unsanitized user content rendered as markup; open redirects
  where a redirect target comes from a query parameter without an allowlist check; missing CSRF
  protection on state-changing requests; weakened CSP or security headers

**Session & cookie handling**

- Look for: session cookies missing `HttpOnly`/`Secure`/`SameSite`; tokens stored where scripts can
  read them; sessions that are not invalidated on logout, password change, or privilege change;
  long-lived or non-rotating credentials

**Webhooks & third-party integrations**

- Look for: webhook handlers that parse and act on a payload before verifying the signature against
  the raw body; missing replay protection; secrets or tokens forwarded to the client

**Supply chain & CI**

- Look for: new dependencies (who maintains them, what they pull in); CI workflow changes that widen
  permission scopes, echo secrets, or let untrusted contributors trigger privileged jobs; changes to
  the review configuration itself that weaken risk scoring or strip checks

<!-- init: extend this file with repo-specific focus areas and evidence links -->

## Repo-specific: familylife-gift-cards

This app has two doors: the Okta-protected ActiveAdmin UI under `/admin`, and the token-protected JSON API under `/api/v1`. It handles no payment card data and calls no payment processor. Gift card "certificates" are internal voucher numbers, so card-data (PCI) rules do not apply here. Treat the certificate as a bearer secret for the API instead (see below).

**Admin door: Okta login and ActiveAdmin**

- `config/initializers/active_admin.rb` sets `authentication_method = :authenticate_active_admin_user!`. That method (`ApplicationController`) only checks that `current_user` exists. `User.find_or_create_from_auth_hash` creates a `User` for any Okta login, so Okta decides who gets in. Every signed-in user is a full admin.
- Look for: a new `app/admin/*.rb` resource, `member_action`, `collection_action`, `batch_action` or `action_item` with no thought about who can reach it. Today the only gate beyond sign-in is `CustomAuthorization` (`app/models/custom_authorization.rb`). Reads are always allowed, anything else on an issued `Issuance` is refused, and everything else is allowed.
- Look for: changes to `CustomAuthorization#authorized?` that loosen the "issued issuances are frozen" rule. The `issue` member action in `app/admin/issuances.rb` is covered because it calls `resource`, and ActiveAdmin 3.2's `resource` runs `authorize_resource!` with the action name (`:issue`) as the permission. A new member action that loads the record another way (`Issuance.find(params[:id])`) skips the adapter.
- Look for: `permit_params` additions on `Batch`, `GiftCard` or `Issuance` that let an admin set money or identity fields by mass assignment. `app/admin/gift_cards.rb` already permits `price`, `certificate`, `expiration_date`, `registrations_available`, `gl_code` and even `created_at`/`updated_at`. Widening it further needs a reason.
- Look for: `app/admin/api_keys.rb` permitting `access_token`. An admin can type any token value, which weakens `SecureRandom.hex` generation in `ApiKey`.
- Look for: a controller that inherits `ApplicationController` but is meant to be private and has no `current_user` check. `ApplicationController` has no global sign-in `before_action`, so every non-admin controller is public unless it adds one. Public on purpose today: `MonitorsController#lb` (health check), `LoginController#new` (the auto-submitting Okta POST form) and the `SessionsController#oktaoauth` callback. Nothing else should be.

**API door: `Api::V1::ApplicationController`**

- `restrict_access` looks up `ApiKey.find_by(access_token: ...)` from `params[:access_token]` or an `Authorization: token ...` / `Bearer ...` header. The token in the query string lands in access logs and proxy logs. `:token` in `config/initializers/filter_parameter_logging.rb` covers `access_token`, so keep that filter entry.
- Look for: any new API action that does not inherit from `Api::V1::ApplicationController`, or that adds `skip_before_action :restrict_access`. `skip_forgery_protection` is correct for a token API but must not leak into the admin controllers.
- Look for: token comparison changes. Lookup is by exact match in SQL. Do not switch to a loose or prefix match.
- Look for: new JSON endpoints that return `render json: @gift_card` style whole-record output. That dumps every column. For new fields on `GiftCard`, ask whether an external caller should see them (`gl_code`, `price`, `batch_id`, `issuance_id` are already exposed).
- `GiftCard.find_by(certificate: params[:id])` is the only access control on a card. There is no per-key scoping. Anyone holding any valid API key can read and redeem any certificate. Flag changes that make certificate numbers easier to guess (see `Issuance#set_allocated_certificates`: a 4-digit prefix, a 5-digit sequence and a trailing `0`, so numbers are sequential and guessable).

**Secrets and logging**

- `config/initializers/filter_parameter_logging.rb` deliberately does NOT filter `certificate`. Its comment says to keep it visible and not let an `app:update` re-add it. Do not flag its absence. Do flag any new filter edit that removes `:token`, `:secret`, `:_key` or `:passw`.
- `config/initializers/lograge.rb` logs `params` (minus controller, action, format, id) and `user_id`. Look for: new log lines or `custom_payload` entries that add `session[:id_token]`, `request.headers`, or the raw `Authorization` header.
- Look for: Okta env vars (`OKTA_CLIENT_ID`, `OKTA_CLIENT_SECRET`, `OKTA_ISSUER`, `OKTA_REDIRECT_URI`, `OKTA_AUTH_SERVER_ID`) read anywhere except `config/initializers/omniauth.rb` and `ApplicationController#after_sign_out_path_for`.

**Session and sign-out**

- `config/initializers/session_store.rb` keeps sessions in Redis for 30 days (`expire_after: 30.days`). Look for: changes that lengthen this, or that store more than the user id and `id_token` in `session`.
- `ApplicationController#after_sign_out_path_for` puts `id_token_hint` and `post_logout_redirect_uri=#{request.base_url}` into the Okta logout URL. `config/initializers/devise_sign_out_monkeypatch.rb` allows `allow_other_host: true` for this redirect. Look for: any other redirect that reuses `allow_other_host: true`, or that builds a redirect target from `params`.
- `omniauth-rails_csrf_protection` is in the stack, so OmniAuth login must stay a POST. Look for: a GET login link or a removed CSRF gem.
- `redirect_to("/login/new") && return unless current_user` is the unauthenticated path. Keep redirect targets fixed strings.

**Injection and unsafe output**

- `Issuance#largest_existing_number_in_certificate` interpolates `leading_certificate_4_digit_number` into a Postgres regex (`"certificate ~* ?"` and the Ruby `numbering_regex`). The prefix comes from `batch.dept` or `batch.price`, which an admin types. A `dept` containing regex characters (`.`, `(`, `*`) changes the match. Look for: any change that stops truncating to 4 characters or stops going through the bound `?` parameter.
- `app/admin/issuances.rb` builds the "used" column with `raw("... #{...}<br/>(...)")`. It only interpolates numbers today. Look for: any `raw`, `html_safe` or `.html_safe` that gets a string field (`description`, `contact`, `associated_product`, `allocated_certificates`).
- `app/admin/active_admin/views_helper.rb` returns a JavaScript string used in an `onchange` attribute. Look for: user data added to that string.

**Supply chain and CI**

- `.github/workflows/ruby.yml` runs Brakeman (`bundle exec brakeman -A -q --no-pager`), `bin/bundler-audit` and `bin/importmap audit`. The `audit` job is not a required check. Look for: Brakeman flags being weakened, new `config/brakeman.ignore` entries, or `CVE_IGNORES` growth.
- `.github/workflows/build-deploy-ecs.yml` and `dependabot-auto-merge.yml` handle deploy and auto-merge. Look for: widened `permissions:`, new `pull_request_target` triggers, secrets echoed in steps.
- `omniauth-oktaoauth` is a CruGlobal fork. Look for: a swap back to the upstream gem or to a different OmniAuth strategy.

## Mined from PR history

Rules drawn from all 25 merged PRs (the repo's whole history). Each one lists the PRs it came from.

- Keep the security gates as strict as they are. Brakeman runs with `-A -q` in both the `lint` job of `.github/workflows/ruby.yml` and `bin/brakeman`. Flag a confidence filter (`-w2`, `-w3`) or a dropped `-A` in either. #99 added `-w2` and #104 added an EOLRails ignore as stopgaps, and #103 removed both. There is no `config/brakeman.ignore` today. A new one needs a `note` per entry, and a deadline warning such as EOLRails is fixed by upgrading, not ignored. Flag workflow edits that hard-code CVE ids instead of using the `CVE_IGNORES` repo variable.
  <!-- evidence: PR #99, #103, #104 -->
- A `Gemfile.lock` change that moves `devise`, `omniauth`, `omniauth-oktaoauth`, `omniauth-rails_csrf_protection` or `activeadmin` across a major version needs proof that Okta sign-in, sign-out and the ActiveAdmin session still work: `spec/controllers/sessions_controller_spec.rb` passing plus a stage sign-in noted in the PR. #62 took `devise` from 4.9 to 5.0 inside a grouped Dependabot bump with no review.
  <!-- evidence: PR #62, #64 -->
