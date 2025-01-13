class Issuance < ApplicationRecord
  CERTIFICATE_DISPLAY_SEPARATOR = ", "

  include AASM

  belongs_to :creator, class_name: "User"
  belongs_to :issuer, class_name: "User", optional: true
  belongs_to :batch
  has_many :gift_cards

  validates :quantity, numericality: { only_integer: true }
  delegate :price, to: :batch, allow_nil: true
  delegate :gift_card_type, to: :batch, allow_nil: true

  aasm column: :status do
    state :configuring, initial: true
    state :previewing
    state :issued

    event :preview do
      transitions from: :configuring, to: :previewing
    end

    event :issue do
      transitions from: :previewing, to: :issued, after: :create_gift_cards
      transitions from: :issued, to: :issued
    end
  end

  after_create do
    preview!
  end

  before_save do
    set_allocated_certificates if previewing?
  end

  def to_s
    if previewing?
      "Gift Card Issuance (Preview)"
    elsif issued?
      "Issuance by #{issuer.full_name} #{created_at} (#{quantity} @ $#{price})"
    end
  end

  def create_gift_cards
    allocated_certificates.split(CERTIFICATE_DISPLAY_SEPARATOR).each do |certificate|
      gift_card = gift_cards.where(certificate: certificate).first_or_initialize 
      gift_card.registrations_available = batch.registrations_available
      gift_card.price = price
      gift_card.expiration_date = batch.expiration_date
      gift_card.gift_card_type = batch.gift_card_type
      gift_card.issuance = self
      gift_card.batch = batch
      gift_card.isbn = batch.isbn
      gift_card.associated_product = batch.associated_product
      gift_card.gl_code = batch.gl_code
      gift_card.save!
    end
  end

  def set_allocated_certificates
    next_number = largest_existing_number_in_certificate + 1

    allocated_certificates = []
    quantity.times do
      certificate = "#{price}#{next_number.to_s.rjust(5, "0")}0"
      allocated_certificates << certificate
      next_number += 1
    end

    self.allocated_certificates = allocated_certificates.join(CERTIFICATE_DISPLAY_SEPARATOR)
  end

  # largest number in certificates represented in x's in format, for all certificates matching format
  def largest_existing_number_in_certificate
    numbering_regex = /^#{batch.price}(\d\d\d\d\d)0$/
    numbering_regex_str = "^#{batch.price}(\\d\\d\\d\\d\\d)0"

    # look for all numbers that match numbering
    existing_matching_certificates = GiftCard.all.where("certificate ~* ?", numbering_regex_str).pluck(:certificate)

    # pulling all allocated certificate ids instead of a regex isn't ideal, but there shouldn't be many, if any, times there
    # are previewed gift cards issuances while another one is being previewed
    existing_matching_certificates += Issuance.previewing.where.not(id: self.id).pluck(:allocated_certificates).collect do |allocated_certificates|
      allocated_certificates.to_s.split(CERTIFICATE_DISPLAY_SEPARATOR).find_all { |certificate| certificate =~ numbering_regex }
    end.flatten

    existing_matching_certificates.collect{ |certificate|
      certificate =~ numbering_regex
      $1.to_i
    }.max || 0
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(status created_at updated_at creator_id issuer_id quantity allocated_certificates numbering gift_cards_id)
  end

  def self.ransackable_associations(auth_object = nil)
    %w(creator issuer gift_cards)
  end
end
