FactoryBot.define do
  factory :issuance do
    association :creator, factory: :user
    association :issuer, factory: :user
    quantity { 100 }
  end
end
