class Issuance < ApplicationRecord
  CERTIFICATE_DISPLAY_SEPARATOR = ", "

  include AASM
  include HasNumbering

  belongs_to :creator, class_name: "Person"
  belongs_to :issuer, class_name: "Person", optional: true
  belongs_to :gift_card_type
  has_many :gift_cards

  validates :card_amount, numericality: true 
  validates :quantity, numericality: { only_integer: true }

  aasm column: :status do
    state :configuring, initial: true
    state :previewing
    state :issued

    event :preview do
      transitions from: :configuring, to: :previewing
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
      "Issuance by #{issuer.full_name} #{created_at}"
    end
  end

  def create_gift_cards
    allocated_certificates.split(CERTIFICATE_DISPLAY_SEPARATOR).each do |certificate|
      gift_card = gift_cards.where(certificate: certificate).first_or_initialize 
      gift_card.expiration_date = expiration_date
      gift_card.gift_card_type = gift_card_type
      gift_card.issuance = self
      gift_card.save!
    end
  end

  def set_allocated_certificates
    next_number = largest_existing_number_in_certificate + 1

    allocated_certificates = []
    quantity.times do
      certificate = numbering.gsub(/x+/) { |xs| next_number.to_s.rjust(xs.length, "0") }
      allocated_certificates << certificate
      next_number += 1
    end

    self.allocated_certificates = allocated_certificates.join(CERTIFICATE_DISPLAY_SEPARATOR)
  end

  # largest number in certificates represented in x's in format, for all certificates matching format
  def largest_existing_number_in_certificate
    # look for all numbers that match numbering
    existing_matching_certificates = GiftCard.all.where("certificate ~* ?", numbering_regex_str).pluck(:certificate)

    # pulling all allocated certificate ids instead of a regex isn't ideal, but there shouldn't be many, if any, times there
    # are previewed gift cards issuances while another one is being previewed
    existing_matching_certificates += Issuance.previewing.pluck(:allocated_certificates).collect do |allocated_certificates|
      allocated_certificates.split(CERTIFICATE_DISPLAY_SEPARATOR).find_all { |certificate| certificate =~ numbering_regex }
    end.flatten

    existing_matching_certificates.collect{ |certificate|
      certificate =~ numbering_regex
      $1.to_i
    }.max || 1
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(status created_at updated_at creator_id issuer_id gift_card_type_id card_amount quantity allocated_certificates numbering gift_cards_id)
  end

  def self.ransackable_associations(auth_object = nil)
    %w(creator issuer gift_card_type gift_cards)
  end
end
