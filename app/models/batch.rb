class Batch < ApplicationRecord
  validates_presence_of :description, :gift_card_type, :registrations_available, :begin_use_date, :end_use_date, :expiration_date, :associated_product
  validates_presence_of :price, presence: true, if: -> { GiftCard::PAID_TYPES.include?(gift_card_type) }
  validates_presence_of :gl_code, :dept, presence: true, if: -> { gift_card_type == GiftCard::TYPE_DEPT }
  validates :gift_card_type, inclusion: {in: GiftCard::TYPE_DESCRIPTIONS.keys}

  has_many :issuances

  after_initialize do |batch|
    batch.registrations_available ||= 2
  end

  def to_s
    description
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[description gift_card_type price registrations_available begin_use_date end_use_date expiration_date associated_product isbn gl_code dept contact issuances_id_eq]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[issuances]
  end
end
