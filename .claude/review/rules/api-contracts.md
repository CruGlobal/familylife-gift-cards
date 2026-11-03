# API Contracts: Focus Areas

The v1 JSON gift card API and the callers that depend on it.

The only public API is `GET /api/v1/gift_cards/:id` and `PUT|PATCH /api/v1/gift_cards/:id` (`config/routes.rb`: `resources :gift_cards, only: [:show, :update]` inside `namespace :api do namespace :v1`). `:id` is the gift card `certificate`, not the database id. Code lives in `app/controllers/api/v1/gift_cards_controller.rb` and `app/controllers/api/v1/application_controller.rb`. Callers outside this repo depend on it, so a "harmless" change can break registrations. Treat the current behavior as the contract.

**Who calls it**

- ERT (`CruGlobal/ert-api`, Java): `FlGiftCardServiceImpl#redeem` sends `PUT /api/v1/gift_cards/<certificate>` with `Authorization: Bearer <token>` and an empty JSON body, while a registrant pays with a gift card. It does not call `GET`.
- On 200 it parses the body into `FlGiftCardResponse` (`@JsonIgnoreProperties(ignoreUnknown = true)`, so new keys are safe) and books `certificate`, `price`, `associated_product` and `gl_code`. Those four keys must not be renamed, dropped or emptied.
- On 403 and 404 it reads the `error` key and shows the registrant "We're sorry, but there was a problem processing your gift card. " followed by that text. The `error` strings are user-facing copy, which is why #60 reworded one at FamilyLife's request. Any other status, or a body with no `error`, shows a generic failure.
- moa (`CruGlobal/moa`) has a stub `Payments::Strategies::FlGiftCard` that will redeem through this API later. It is not live yet.
  <!-- evidence: CruGlobal/ert-api@69b6357 eventhub-api-webapp/src/main/java/org/cru/crs/service/FlGiftCardServiceImpl.java and api/model/FlGiftCard/FlGiftCardResponse.java; CruGlobal/moa app/services/payments/strategies/fl_gift_card.rb -->


**Routes and verbs**

- Only `show` and `update` exist. Look for: new routes, a new version namespace, `resources` with the `only:` removed, or changes to the `:id` meaning (it is the certificate string).
- Look for: any new action added to `Api::V1::GiftCardsController` without a `config/routes.rb` entry and a spec in `spec/controllers/api/v1/gift_cards_controller_spec.rb`.
- `#update` takes no body fields. A PUT means "redeem once". It is not idempotent, so a retry by the caller uses up another redemption. Look for: changes that make it look like a normal field update, or that start reading body params.

**Response shape**

- Success returns `render json: @gift_card`, which is every column of `gift_cards` serialized by `GiftCard#as_json`: `id`, `issuance_id`, `batch_id`, `price`, `gift_card_type`, `certificate`, `expiration_date`, `registrations_available`, `associated_product`, `gl_code`, `created_at`, `updated_at`, `isbn`. The spec compares the body to `JSON.parse(gift_card.to_json)`.
- Because the body is the whole record, a new column in `db/migrate/` changes the API automatically. Look for: new `GiftCard` columns (they leak to callers), renamed or dropped columns (they break callers), a change of column type (`price` is `decimal`, which Rails serializes as a string like `"300.0"`), and added `as_json`, `only:`, `except:`, `include:` or serializers.
- Dates serialize as ISO strings (`expiration_date` as `YYYY-MM-DD`, timestamps in ISO 8601 with milliseconds). Look for: format changes through a locale, `config.time_zone`, or `ActiveSupport::JSON::Encoding` settings.
- `registrations_available` after a redemption is the new value (the spec checks `8` after starting at `10`). Look for: returning the old value, or a count other than the stored one.

**Status codes and error bodies**

- 401: `{"error": "You either didn't pass in an access token, or the token you did pass in was wrong."}` from `restrict_access`.
- 404: `{"error": "No gift card found by that number", "status": 404}`.
- 403: `{"error": "No registrations available", "status": 403}` when `registrations_available.to_i <= 1`. `{"error": "Gift card has expired", "status": 403}` when `expired?`. Not-enough-registrations is checked before expiry, so a card that is both returns "No registrations available".
- The `error` text is shown to registrants by ERT and asserted by specs (`JSON.parse(response.body)["error"]`). A wording change is a copy change for FamilyLife, so it needs their sign-off, not just a spec edit. Look for: reworded messages, a new `message` or `errors` key replacing `error`, a changed status (for example 404 to 422, 403 to 409), or `status` removed from the body. The 401 body has no `status` key, and the other errors do. Do not "fix" that without a version plan.
- Look for: new failure paths that return 500 or an HTML page instead of JSON (the base class is `ActionController::Base`, so unhandled errors render HTML). New code must render JSON errors in the same shape.
- Look for: the 403 and 404 branches order. `before_action :load_gift_card_from_certificate` runs after `restrict_access`, so a bad token returns 401 even for a missing card. Keep that order so callers cannot probe certificates without a token.

**Token authentication**

- `Api::V1::ApplicationController#restrict_access` accepts the token from `params[:access_token]` first, then from `Authorization: token <t>` or `Authorization: Bearer <t>` (regexes `^token\s(.*)` and `^Bearer\s(.*)`). Missing and wrong tokens both give 401 with the same message. The 401 is rendered with `callback: params[:callback]`.
- Look for: dropping the query-param form or either header form (existing callers may use any of them), changing the header regex, tokens being compared another way, or splitting the 401 into two messages (that would tell callers which tokens exist).
- Look for: a new action that does not inherit from `Api::V1::ApplicationController`. Also look for `skip_before_action :restrict_access`.
- Tokens come from `ApiKey` (`SecureRandom.hex`, 32 hex characters), managed in `app/admin/api_keys.rb`. Look for: rotation or expiry added without telling callers, and key length or format changes.
- `skip_forgery_protection` stays on this base class only. `respond_to :json` is declared here, so keep JSON as the response format.

**Backward compatibility**

- Additive changes (a new key in the JSON) are usually safe. Removed keys, renamed keys, changed types, new required inputs, new status codes on existing paths, and changed messages are breaking. Look for: PRs that make any of those without a new `/api/v2` namespace or a written note that the caller was updated first.
- Look for: certificate lookup changing (case, trimming, leading zeros). `find_by(certificate: params[:id])` is exact. Certificates are strings like `3000000010`. Never cast to integer. A route `:id` with a `.` in it can be treated as a format (`format: :json` in specs), so certificates must not contain dots.
- Look for: redemption semantics changing: one PUT uses 2 registrations, refused at `<= 1`, expired cards refused. These numbers are part of the contract with the registration system.
- `#show` returns expired cards and cards with no registrations left with 200. The caller may rely on that to show a reason. Do not start returning 403 or 404 there without a plan.

**Spec expectations**

- Contract changes need edits in `spec/controllers/api/v1/gift_cards_controller_spec.rb`: token as param, token as `token` header, missing/invalid token (401), unknown certificate (404), no registrations (403 + exact message), expired (403 + exact message), success body equal to the record JSON, and the `registrations_available` value after a redemption.

**Checklist**

- [ ] Routes, verbs and the meaning of `:id` (certificate) are unchanged, or a new version is added
- [ ] Success JSON keys and value types are unchanged, and new columns were checked for API exposure
- [ ] Status codes and `error` strings are unchanged for 401, 403 and 404
- [ ] Every failure path returns JSON, never HTML or a bare 500
- [ ] Token auth still accepts `access_token` param, `token` header and `Bearer` header, with one generic 401
- [ ] Redemption rule (`<= 1` refuse, subtract 2, expired refuse) is unchanged or versioned
- [ ] Specs cover the changed behavior with exact status and message assertions

## Mined from PR history

Rules drawn from all 25 merged PRs (the repo's whole history). Each one lists the PRs it came from.

- Treat every `error:` string, the `status` field and the HTTP status in `app/controllers/api/v1/*.rb` as both contract and user-facing copy. ERT shows the `error` text to registrants, and FamilyLife asked for the 404 wording change in #60 ("No gift card found by that certificate" to "No gift card found by that number"). A PR that changes one must say ERT was checked and must update the exact-string assertion in `spec/controllers/api/v1/gift_cards_controller_spec.rb`.
  <!-- evidence: PR #59, #60 -->
