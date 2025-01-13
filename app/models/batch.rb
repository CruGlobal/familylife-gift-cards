class Batch < ApplicationRecord
  validates_presence_of :description, :gift_card_type, :price, :registrations_available, :begin_use_date, :end_use_date, :expiration_date,
    :associated_product, :isbn
  validates_presence_of :gl_code, :dept, presence: true, if: -> { GiftCard::PAID_TYPES.include?(gift_card_type) }

  def new
    self.registrations_available ||= 2
  end

  def to_s
    description
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[description gift_card_type price registrations_available begin_use_date end_use_date expiration_date associated_product isbn gl_code dept contact]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[issuances]
  end
end
