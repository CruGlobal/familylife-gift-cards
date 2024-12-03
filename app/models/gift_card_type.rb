class GiftCardType < ApplicationRecord
  include HasNumbering

  validates :numbering, presence: true, format: { with: /\d*x+\d*/ }

  def to_s
    label
  end

  def self.ransackable_attributes(auth_object = nil)
    [:label, :numbering, :contact, :prod_id, :isbn, :gl_acct, :department_number]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
