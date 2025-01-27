# fn = "FL_EventCertificate_202411261112.csv"
fn = "FL_EventCertificate_202501241219.csv"

#=> Batch(id: integer, description: string, regex: string, contact: string, associated_product: string, isbn: string, gl_code: string, dept: string, created_at: datetime, updated_at: datetime)

# User(id: integer, sso_guid: uuid, username: string, first_name: string, last_name: string, email: string, has_access: boolean, created_at: datetime, updated_at: datetime)
system = User.where(sso_guid: "initial", first_name: "Initial", last_name: "Import").first_or_create

Batch.class_eval do
  attr_accessor :regex
end

Batch.delete_all
regexes = {}

t = Batch.where(description: "Initial - Regular Rate (Green) Paid Gift Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_PAID_FULL_PRICE
t.regex = "3500xxxxx0"
regexes[t.description] = t.regex
t.associated_product = "CER21842"
t.isbn = "978-1602005761"
t.save(validate: false)

t = Batch.where(description: "Initial - Half Price (Blue) Paid Gift Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_PAID_HALF_PRICE
t.regex = "1750xxxxx0"
regexes[t.description] = t.regex
t.associated_product = "CER21841"
t.isbn = "978-1602006676"
t.save(validate: false)

t = Batch.where(description: "Initial - Marketing Department Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_DEPT
t.regex = "4240xxxxx0"
regexes[t.description] = t.regex
t.gl_code = "63301"
t.dept = "4240-15999"
t.contact = "Taylor"
t.save(validate: false)

t = Batch.where(description: "Initial - Donor Dept. Department Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_DEPT
t.regex = "3210xxxxx0"
regexes[t.description] = t.regex
t.gl_code = "63301"
t.dept = "3210-38100"
t.contact = "Quinton/Gene"
t.save(validate: false)

t = Batch.where(description: "Initial - Partners Department Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_DEPT
t.regex = "3215xxxxx0"
regexes[t.description] = t.regex
t.gl_code = "63301"
t.dept = "3215-38116"
t.contact = "Quinton/Gene"
t.save(validate: false)

t = Batch.where(description: "Initial - President Department Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_DEPT
t.regex = "1100xxxxx0"
regexes[t.description] = t.regex
t.gl_code = "63301"
t.dept = "1100-50050"
t.contact = "Brian Borger"
t.save(validate: false)

t = Batch.where(description: "Initial - Field Core Department Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_DEPT
t.regex = "4710xxxxx0"
regexes[t.description] = t.regex
t.gl_code = "63301"
t.dept = "4710-15999"
t.contact = "Brandon"
t.save(validate: false)

t = Batch.where(description: "Initial - Innovative Events Department Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_DEPT
t.regex = "4228xxxxx0"
regexes[t.description] = t.regex
t.gl_code = "63301"
t.dept = "4228-14400"
t.contact = "Tim Bell/Tanya"
t.save(validate: false)

t = Batch.where(description: "Initial - Speaker Dept. Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_DEPT
t.regex = "1470xxxxx0"
regexes[t.description] = t.regex
t.gl_code = "63301"
t.dept = "1470-34998"
t.contact = "Jennifer Abbott"
t.save(validate: false)

t = Batch.where(description: "Initial - Corporate Department Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_DEPT
t.regex = "4241xxxxx0"
regexes[t.description] = t.regex
t.gl_code = "63301"
t.dept = "4241-45100"
t.contact = "Glen Flagerstrom"
t.save(validate: false)

t = Batch.where(description: "Initial - Station Relations Card").first_or_initialize
t.gift_card_type = GiftCard::TYPE_DEPT
t.regex = "1420xxxxx0"
regexes[t.description] = t.regex
t.gl_code = "63301"
t.dept = "1420-34001"
t.contact = "Maddison Villafane"
t.save(validate: false)

t = Batch.where(description: "Initial - Unknown").first_or_initialize
t.gift_card_type = GiftCard::TYPE_PAID_OTHER
t.regex = "xxxxx"
regexes[t.description] = t.regex
t.contact = "This is for initial import cards with a certificate id that doesn't match any gift card regex"
t.save(validate: false)

#=> Batch(id: integer, description: string, regex: string, contact: string, associated_product: string, isbn: string, gl_code: string, dept: string, created_at: datetime, updated_at: datetime)

#=> GiftCard(id: integer, certificate: integer, expiration_date: datetime, registrations_available: integer, associated_product: string, gl_code: string, created_at: datetime, updated_at: datetime, issuance_id: integer)

total = `wc -l "#{fn}"`.split(" ").first.to_i
unknown_batch = Batch.last

GiftCard.delete_all
Issuance.delete_all

initial_issuances = Batch.all.collect do |batch|
  issuance = Issuance.where(creator_id: system, issuer_id: system, batch: batch).first_or_create
  issuance.quantity = 0
  issuance.save!

  issuance.update_column(:status, "issued")
  issuance = Issuance.find(issuance.id)

  [batch, issuance]
end.to_h

all_batches = Batch.all
gift_cards = []

regexes.each_pair do |k, v|
  regexes[k] = v.gsub(/x+/) { |xs| "(#{xs.gsub("x", "\\d")})" }
end

i = 0
CSV.foreach(fn, headers: true) do |row|
  puts("[#{i += 1}/#{total}, #{(i / total.to_f * 100).round(2)}%]")

  # ex: #<CSV::Row "certificateId":"1200033120" "expirationDate":"2014-12-31 00:00:00.000" "motivationCode":"EW8000CERT" "kinteraPriceCode":"850179" "familyLifePriceCode":"FLRATE    " "numberRegistrations":"2" "associatedProduct":"PAS16653" "certificateValue":"0.0000" "priceToGuest":"0.0000" "payeeAmount":"150.0000" "glCode":"63301.4210.25000" "accountNumber":"8257008.0" "addDate":"2012-06-15 16:38:54.180" "modifiedDate":nil "payType":"GL">
  #
  # byebug
  batch = all_batches.detect { |batch| /#{regexes[batch.description]}/.match(row["certificateId"]) } || unknown_batch
  issuance = initial_issuances[batch]

  # gc = GiftCard.where(certificate_id: row["certificateId"]).first_or_initialize
  gc = GiftCard.new
  gc.certificate = row["certificateId"]
  gc.issuance = issuance
  gc.batch = batch
  gc.expiration_date = DateTime.parse(row["expirationDate"])
  gc.registrations_available = row["numberRegistrations"].to_i
  gc.price = row["certificateValue"].to_d
  gc.gl_code = row["glCode"]
  gc.created_at = DateTime.parse(row["addDate"]) if row["addDate"]
  gc.updated_at = DateTime.parse(row["modifiedDate"]) if row["modifiedDate"]
  gc.associated_product = row["associatedProduct"]

  gift_cards << gc

  if gift_cards.length >= 10000
    GiftCard.import(gift_cards)
    gift_cards = []
  end
end

GiftCard.import(gift_cards)

Issuance.where(quantity: [nil, 0]).each do |i|
  i.update(quantity: i.gift_cards.count)
end
