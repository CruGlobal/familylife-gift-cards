=begin
  create_table "gift_cards", force: :cascade do |t|
    t.integer "certificate"
    t.datetime "expiration_date"
    t.integer "registrations_available"
    t.string "associated_product"
    t.decimal "certificate_value"
    t.string "gl_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "issuances", force: :cascade do |t|
    t.string "status"
    t.integer "initiator_id"
    t.decimal "card_amount"
    t.integer "quantity"
    t.datetime "begin_use_date"
    t.datetime "end_use_date"
    t.datetime "expiration_date"
    t.integer "gift_card_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "allocated_certificates"
    t.string "numbering"
  end

=end

class Issuance < ApplicationRecord
  include AASM

  belongs_to :creator, class_name: "Person"
  belongs_to :issuer, class_name: "Person", optional: true
  belongs_to :gift_card_type
  has_many :gift_cards

  validates :card_amount, numericality: true 
  validates :quantity, numericality: { only_integer: true }

  aasm column: :status do
    state :configure, initial: true
    state :preview
    state :issued

    event :preview do
      transitions from: :configure, to: :preview
    end

    event :issue do
      transitions from: :preview, to: :issued, after: :create_gift_cards
      transitions from: :issued, to: :issued
    end
  end

  before_save do
    unless issued?
      # keep a copy of numbering for posterity if still previewing
      self.numbering = gift_card_type.numbering
      set_allocated_certificates
    end
  end

  after_create do
    preview!
  end

  def to_s
    if preview?
      "Gift Card Issuance (Preview)"
    elsif issued?
      "Gift Card Issuance by #{issuer.full_name} at #{created_at}"
    end
  end

  def create_gift_cards
    byebug
    allocated_certificates.split(", ").each do |certificate|
      gift_card = gift_cards.where(certificate: certificate).first_or_initialize 
      gift_card.expiration_date = expiration_date
    end
  end

  def numbering_regex_str
    numbering.gsub(/x+/) { |xs| "(#{xs.gsub("x", "\\d")})" }
  end

  def numbering_regex
    # add brackets around the x's so that it can be extracted, and use \d instead of x
    @numbering_regex ||= /#{numbering_regex_str}/
  end

  def set_allocated_certificates
    largest_existing_certificate.to_s =~ numbering_regex
    next_number = $1.to_i

    allocated_certificates = []
    quantity.times do
      certificate = numbering.gsub(/x+/) { |xs| next_number.to_s.rjust(xs.length, "0") }
      allocated_certificates << certificate
      next_number += 1
    end

    self.allocated_certificates = allocated_certificates.join(", ")
  end

  def largest_existing_certificate

    # look for all numbers that match numbering
    existing_matching_certificates = GiftCard.all.where("certificate::text LIKE ?", numbering_regex_str).pluck(:certificate)

    # pulling all allocated certificate ids instead of a rergex isn't ideal, but there shouldn't be many, if any, times there
    # are previewed gift cards issuances while another one is being previewed
    existing_matching_certificates += Issuance.preview.pluck(:allocated_certificates).collect do |allocated_certificates|
      allocated_certificates.split(", ").find_all { |certificate| certificate =~ numbering_regex }
    end.flatten

    existing_matching_certificates.collect(&:to_i).max
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(status created_at updated_at creator_id issuer_id gift_card_type_id card_amount quantity allocated_certificates numbering gift_cards_id)
  end

  def self.ransackable_associations(auth_object = nil)
    %w(creator issuer gift_card_type gift_cards)
  end
end
