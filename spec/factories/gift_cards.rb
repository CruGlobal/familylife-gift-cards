FactoryBot.define do
  factory :gift_card do
    association :issuance
    batch { issuance.batch }
  end
end
