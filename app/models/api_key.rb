class ApiKey < ApplicationRecord
  before_create :generate_access_token
  after_initialize :generate_access_token

  def self.ransackable_attributes(auth_object = nil)
    ["access_token", "created_at", "id", "updated_at", "user"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def generate_access_token
    return if !new_record? || access_token.present?

    loop do
      self.access_token ||= SecureRandom.hex
      break unless self.class.exists?(access_token: access_token)
    end
  end
end
