class Person < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    [:first_name, :last_name]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
