FactoryBot.define do
  factory :batch do
    description { "Description" }
    begin_use_date { 1.month.from_now }
    end_use_date { 2.months.from_now }
    expiration_date { 3.months.from_now }
    associated_product { "prod123" }

    factory :batch_paid do
      gift_card_type { GiftCard::TYPE_PAID_FULL_PRICE }
      price { 300.00 }
    end

    factory :batch_dept do
      description { "Description Batch Dept" }
      gift_card_type { GiftCard::TYPE_DEPT }
      gl_code { "gl_code" }
      dept { "DEP" }
    end
  end
end
