class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:oktaoauth]

  strip_attributes only: %i[username first_name last_name email]

  def self.ransackable_attributes(auth_object = nil)
    ["first_name", "last_name"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.find_or_create_from_auth_hash(auth_hash)
    existing = find_by(sso_guid: auth_hash.extra.raw_info.ssoguid)
    return existing.apply_auth_hash(auth_hash) if existing

    pending = find_by("lower(username) = ?", auth_hash.extra.raw_info.preferred_username.downcase)
    return pending.apply_auth_hash(auth_hash) if pending

    new.apply_auth_hash(auth_hash)
  end

  def apply_auth_hash(auth_hash)
    self.sso_guid = auth_hash.extra.raw_info.ssoguid
    self.username = auth_hash.extra.raw_info.preferred_username
    self.first_name = auth_hash.info.first_name
    self.last_name = auth_hash.info.last_name
    self.email = auth_hash.info.email
    save!
    self
  end

  def name
    [first_name, last_name].join(" ")
  end
  alias_method :full_name, :name
end
