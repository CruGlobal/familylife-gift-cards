class GiftCard < ApplicationRecord
  belongs_to :issuance
  belongs_to :gift_card_type

  validates :certificate, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
   %w(certificate expiration_date registrations_available associated_product certificate_value gl_code created_at updated_at 
        issuance_id gift_card_type_id isbn department_number)
  end

  def self.ransackable_associations(auth_object = nil)
    %w(issuance issuance_id gift_card_type gift_card_type_id)
  end
end
