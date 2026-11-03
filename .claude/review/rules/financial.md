# Financial: Focus Areas

Gift card value and accounting. A certificate stands for money: paid cards are sold at a price, and department cards are charged to a GL code. ERT (`CruGlobal/ert-api`) redeems them as a payment method at registration and books `price` and `gl_code` from the API response.

Scope: this app handles NO payment card data and calls NO payment processor. Gift card certificates are internal voucher numbers, not card numbers. This lane is about value and accounting correctness, not PCI. Do not raise card-data or payment-processor findings here.

**Certificate numbering and uniqueness**

- A certificate is a string: `<4-char prefix><5-digit sequence>0`. The prefix comes from `Issuance#leading_certificate_4_digit_number`: the first 4 characters of `batch.dept` for `GiftCard::TYPE_DEPT`, otherwise `batch.price.to_i.to_s`, padded with `0` to 4 characters (`ljust(4, "0")`). The sequence is `largest_existing_number_in_certificate + 1`, counting up, left-padded to 5 digits with `rjust(5, "0")`.
- Look for: changes to the prefix, the padding, the trailing `0`, or the regex in `largest_existing_number_in_certificate` that would let two different batches collide or let an old range be reused.
- The prefix is meant to show the value. Today's prices are whole dollars with 3 digits: $350 full price gives `3500` and $175 half price gives `1750` (see the batches in `import.rb`). Look for: a price rule that breaks this. `price.to_i` drops cents ($175.50 also gives `1750`), a 2-digit price shares a prefix with a 3-digit one ($50 and $500 both give `5000`), a price of $10,000 or more is cut to 4 digits, and a price under $1 gives `0000`. Shared prefixes share one number sequence, so certificates stay unique, but the number no longer tells you the value.
- Look for: the sequence passing 99999. `rjust(5, "0")` does not truncate, so the certificate gets a 6-digit sequence. That no longer matches the `(\d\d\d\d\d)0$` regex, so the next issuance computes the same number again and `create_gift_cards` fails on the uniqueness check at `save!`.
- `GiftCard` validates `certificate` uniqueness in Ruby only. There is no unique index. The numbering function reads existing cards plus other `previewing` issuances, so two previews at the same moment can overlap. Look for: any change that makes the overlap window larger, or any path that writes cards without that check.
- Look for: certificates matched case-insensitively. The numbering query uses `~*` (case-insensitive) while the API lookup `find_by(certificate:)` is exact. Dept prefixes are text such as `DEP0`. Keep the two consistent.

**Redemption counts**

- `registrations_available` starts from `Batch` (default `2`, set in `after_initialize`) and is copied to each `GiftCard` when the issuance is issued. The API `#update` subtracts `2` per redemption and refuses when the count is `<= 1`. So one API call uses two "registrations". That is the current rule. Keep it explicit.
- Look for: a change to the `<= 1` check or the `- 2` that is not changed in both places, or a batch with an odd or one-registration count that can never be redeemed.
- The update is a read, then `update(registrations_available: value - 2)`. There is no lock and no `with_lock`, so two simultaneous calls can both read the same number and both succeed. Look for: any change that depends on this being safe, and any new redemption path (admin, import, API) that does not share one atomic method.
- Look for: `update` whose return value is ignored (a failed save still renders a success). A redemption that returns 200 must have been saved.
- The admin Issuances index counts a card as used when `registrations_available` is `0`. Cards left at `1` (odd counts) never show as used. Look for: changes that break that definition. Division by `total` is unguarded: an issuance with zero cards divides by zero (`NaN`).

**Price and value**

- `price` is `decimal(8,2)` on `batches` and `gift_cards`, copied onto each card at issue time. Paid types (`GiftCard::PAID_TYPES`) require a batch price. Dept cards have none. Look for: any `to_f`, `Float`, or rounding mid-calculation on `price`; any change that stops copying `price` from the batch onto the card; a gift card whose `price` is changed after issue by an admin form (`permit_params` on `GiftCard` allows `:price`).
- Look for: code that assumes `gift_card_type` and `price` agree. `TYPE_PAID_HALF_PRICE` does not compute half of anything. The number is whatever an admin typed on the batch.
- Admin display uses `as: :currency` and `unit: "$"`. Only the display rounds. Keep the stored value exact.

**GL code and dept coding**

- Dept batches require both `gl_code` and `dept` (`Batch` validation). The form hints show the formats: `gl_code` as `(63301-dept-project)` and `dept` as `(4-digit dept, ex 4240)`. Neither format is validated. Look for: validations added or loosened, a `dept` longer than 4 characters (only the first 4 reach the certificate prefix, so two different depts can share a prefix, such as `42401` and `42402`), or a dept that does not match its `gl_code`.
- Paid batches have no required `gl_code`. `GiftCard#gl_code` is copied from the batch in `create_gift_cards`, so an empty value flows through to accounting. Look for: changes that make `gl_code` required for paid types without a data fix, or that stop copying it.
- Look for: edits to a `Batch` that already has issued cards. The cards keep their copied `gl_code`, `price` and `expiration_date`. That is intended. Flag changes that would update issued cards in place, or that make the batch and its cards disagree silently.

**Expiry and use dates**

- `GiftCard#expired?` is `expiration_date.present? && expiration_date < Date.current`. A card expires after its `expiration_date`, so it is still valid on that date. A card with no expiration date never expires. The API returns 403 `"Gift card has expired"` from `#update`, but `#show` still returns an expired card with a 200.
- `Batch` also has `begin_use_date` and `end_use_date`. They are required but are not checked anywhere in the API or in `GiftCard`. Look for: new code that relies on them, or that treats `end_use_date` and `expiration_date` as the same thing.
- The admin Issuance form only offers batches with `expiration_date > ?` (`Date.today`). Look for: changes that allow issuing cards for an already expired batch.

**Issuance state machine (`Issuance`, AASM on `status`)**

- Flow: `configuring` to `previewing` (`preview!`, called by `after_create`) to `issued` (`issue!`). `issue` also allows `issued` to `issued` (a no-op). `create_gift_cards` runs on the first `issue` and uses `first_or_initialize`, so repeating does not double-create.
- While `previewing`, every save recomputes `allocated_certificates`. After `issued`, the range is fixed. Look for: any save on a previewing issuance that changes the range after someone has written it down; changes to `quantity` or `batch` on an issued issuance (blocked in admin by `CustomAuthorization`, but not at the model or API level).
- `issued_at` and `issuer_id` are set by a second `update` after `issue!` in `app/admin/issuances.rb`. If that second write fails, the cards exist with no issuer. Look for: changes that move these into one transaction (good) or that add more steps outside one.
- `quantity` only needs to be an integer. Look for: zero, negative or very large quantities creating no cards, or a huge in-memory list of certificates.
- `import.rb` loads historical data with `save(validate: false)` and `delete_all` on `Batch`, `GiftCard` and `Issuance`. Look for: any use of it near production data.

**Checklist**

- [ ] Certificate format and padding are unchanged, or the change handles old certificates still in use
- [ ] No new write path creates cards without the numbering and uniqueness checks
- [ ] Redemption rule (`<= 1` and `- 2`) is consistent everywhere and the update result is checked
- [ ] `price` stays `BigDecimal`, copied to the card at issue, and never rounded before display
- [ ] `gl_code` and `dept` rules match what accounting expects, and are copied to the card at issue
- [ ] Expiry uses `Date.current` and `GiftCard#expired?`, with the on-the-day rule unchanged
- [ ] State changes go through AASM events, and `create_gift_cards` stays safe to repeat

## Mined from PR history

Rules drawn from all 25 merged PRs (the repo's whole history). Each one lists the PRs it came from.

- Redemption in `Api::V1::GiftCardsController#update` reads `registrations_available`, checks it, then writes `registrations_available - 2` with no lock. Flag a change to this path that keeps the read-then-write without `with_lock` or an atomic SQL decrement, and flag a new rejection rule (expired, used up, disabled) that runs after the decrement instead of before it. #59 added the expiry check only after an expired card was redeemed on staging.
  <!-- evidence: PR #5, #59 -->
- A gift card validity rule (expiry, registrations left, use dates) lives as a predicate on `GiftCard` (like `GiftCard#expired?`) that the API calls, not as inline logic in a controller or admin block. It compares `date` columns with `Date.current`, and it needs boundary specs: expires today (still valid), expired yesterday, and a nil date.
  <!-- evidence: PR #5, #59 -->
