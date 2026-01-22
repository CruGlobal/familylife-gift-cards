class GiftCard < ApplicationRecord
  TYPE_PAID_HALF_PRICE = "paid_half_price"
  TYPE_PAID_FULL_PRICE = "paid_full_price"
  TYPE_PAID_OTHER = "paid_other"
  TYPE_DEPT = "type_dept"
  PAID_TYPES = [TYPE_PAID_HALF_PRICE, TYPE_PAID_FULL_PRICE, TYPE_PAID_OTHER]

  TYPE_DESCRIPTIONS = {
    TYPE_PAID_HALF_PRICE => "Paid, Half",
    TYPE_PAID_FULL_PRICE => "Paid, Full",
    TYPE_PAID_OTHER => "Paid, Other",
    TYPE_DEPT => "Department"
  }

  belongs_to :issuance
  belongs_to :batch

  validates :certificate, uniqueness: true

  def expired?
    expiration_date.present? && expiration_date < Date.current
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[certificate expiration_date registrations_available associated_product gl_code created_at updated_at
      issuance_id gift_card_type isbn batch_id price gift_card_type]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[batch batch_id issuance issuance_id gift_card_type]
  end
end
