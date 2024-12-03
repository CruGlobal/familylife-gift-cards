#=> GiftCardType(id: integer, label: string, numbering: string, contact: string, prod_id: string, isbn: string, gl_acct: string, department_number: string, created_at: datetime, updated_at: datetime)

GiftCardType.delete_all

t = GiftCardType.where(label: "Regular Rate (Green) Paid Gift Card").first_or_initialize
t.numbering = "3500xxxxx0"
t.prod_id = "CER21842"
t.isbn = "978-1602005761"
t.save!

t = GiftCardType.where(label: "Half Price (Blue) Paid Gift Card").first_or_initialize
t.numbering = "1750xxxxx0"
t.prod_id = "CER21841"
t.isbn = "978-1602006676"
t.save!

t = GiftCardType.where(label: "Marketing Department Card").first_or_initialize
t.numbering = "4240xxxxx0"
t.gl_acct = "63301"
t.department_number = "4240-15999"
t.contact = "Taylor"
t.save!

t = GiftCardType.where(label: "Donor Dept. Department Card").first_or_initialize
t.numbering = "3210xxxxx0"
t.gl_acct = "63301"
t.department_number = "3210-38100"
t.contact = "Quinton/Gene"
t.save!

t = GiftCardType.where(label: "Partners Department Card").first_or_initialize
t.numbering = "3215xxxxx0"
t.gl_acct = "63301"
t.department_number = "3215-38116"
t.contact = "Quinton/Gene"
t.save!

t = GiftCardType.where(label: "President Department Card").first_or_initialize
t.numbering = "1100xxxxx0"
t.gl_acct = "63301"
t.department_number = "1100-50050"
t.contact = "Brian Borger"
t.save!

t = GiftCardType.where(label: "Field Core Department Card").first_or_initialize
t.numbering = "4710xxxxx0"
t.gl_acct = "63301"
t.department_number = "4710-15999"
t.contact = "Brandon"
t.save!

t = GiftCardType.where(label: "Innovative Events Department Card").first_or_initialize
t.numbering = "4228xxxxx0"
t.gl_acct = "63301"
t.department_number = "4228-14400"
t.contact = "Tim Bell/Tanya"
t.save!

t = GiftCardType.where(label: "Speaker Dept. Card").first_or_initialize
t.numbering = "1470xxxxx0"
t.gl_acct = "63301"
t.department_number = "1470-34998"
t.contact = "Jennifer Abbott"
t.save!

t = GiftCardType.where(label: "Corporate Department Card").first_or_initialize
t.numbering = "4241xxxx0"
t.gl_acct = "63301"
t.department_number = "4241-45100"
t.contact = "Glen Flagerstrom"
t.save!

t = GiftCardType.where(label: "Station Relations Card").first_or_initialize
t.numbering = "1420xxxxx0"
t.gl_acct = "63301"
t.department_number = "1420-34001"
t.contact = "Maddison Villafane"
t.save!

t = GiftCardType.where(label: "Unknown").first_or_initialize
t.numbering = "xxxxx"
t.contact = "This is for initial import cards with a certificate id that doesn't match any gift card numbering"
t.save!

#=> GiftCardType(id: integer, label: string, numbering: string, contact: string, prod_id: string, isbn: string, gl_acct: string, department_number: string, created_at: datetime, updated_at: datetime)

#=> GiftCard(id: integer, certificate: integer, expiration_date: datetime, registrations_available: integer, associated_product: string, certificate_value: decimal, gl_code: string, created_at: datetime, updated_at: datetime, issuance_id: integer)

total = `wc -l "FL_EventCertificate_202411261112.csv"`.split(" ").first.to_i
unknown_gct = GiftCardType.last

system = Person.where(first_name: "Initial", last_name: "Import").first_or_create

GiftCard.delete_all
Issuance.delete_all

initial_issuances = GiftCardType.all.collect do |gct|
  issuance = Issuance.where(creator_id: system, issuer_id: system, gift_card_type: gct).first_or_create
  issuance.card_amount = 0
  issuance.quantity = 0
  issuance.save!
  [ gct, issuance ]
end.to_h

all_types = GiftCardType.all
batch = []

i = 0
CSV.foreach("FL_EventCertificate_202411261112.csv", headers: true) do |row|
  puts("[#{i += 1}/#{total}, #{(i / total.to_f * 100).round(2)}%]")

  # ex: #<CSV::Row "certificateId":"1200033120" "expirationDate":"2014-12-31 00:00:00.000" "motivationCode":"EW8000CERT" "kinteraPriceCode":"850179" "familyLifePriceCode":"FLRATE    " "numberRegistrations":"2" "associatedProduct":"PAS16653" "certificateValue":"0.0000" "priceToGuest":"0.0000" "payeeAmount":"150.0000" "glCode":"63301.4210.25000" "accountNumber":"8257008.0" "addDate":"2012-06-15 16:38:54.180" "modifiedDate":nil "payType":"GL">
  #
  gct = all_types.detect{ |gtt| gtt.numbering_regex.match(row["certificateId"]) } || unknown_gct
  issuance = initial_issuances[gct]

  #gc = GiftCard.where(certificate_id: row["certificateId"]).first_or_initialize
  gc = GiftCard.new
  gc.certificate = row["certificateId"]
  gc.issuance = issuance
  gc.gift_card_type = gct
  gc.expiration_date = DateTime.parse(row["expirationDate"])
  gc.registrations_available = row["numberRegistrations"].to_i
  gc.certificate_value = row["certificateValue"].to_d
  gc.gl_code = row["glCode"].to_d
  gc.created_at = row["addDate"].to_d
  gc.updated_at = row["modifiedDate"].to_d
  gc.associated_product = row["associatedProduct"].to_d
  
  batch << gc

  if batch.length >= 1000
    GiftCard.import(batch)
    batch = []
  end
end
