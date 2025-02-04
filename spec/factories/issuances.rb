FactoryBot.define do
  factory :issuance do
    association :creator, factory: :user
    association :issuer, factory: :user
    association :batch, factory: :batch_paid
    quantity { 100 }
  end
end
