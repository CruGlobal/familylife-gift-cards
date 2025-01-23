FactoryBot.define do
  factory :issuance do
    association :creator, factory: :user
    association :issuer, factory: :user
    association :batch
    quantity { 100 }
  end
end
