FactoryBot.define do
  factory :property do
    title { "서울 강남구 신축 아파트" }
    address { "서울특별시 강남구 역삼동" }
    price { "8억 5천만원" }
    property_type { "아파트" }
    deal_type { "매매" }
    area { "84㎡" }
    floor { "15층" }
    description { "신축 아파트로 교통이 편리하고 학군이 우수합니다." }
    latitude { 37.4979 }
    longitude { 127.0276 }
    external_id { sequence(:external_id) { |n| "prop_#{n}" } }
    source { "test_source" }
    raw_data { { original_price: "850000000", source_url: "http://example.com" } }

    trait :villa do
      title { "서울 마포구 빌라" }
      property_type { "빌라" }
      price { "4억원" }
    end

    trait :officetel do
      title { "강남 오피스텔" }
      property_type { "오피스텔" }
      area { "25㎡" }
    end

    trait :rental do
      deal_type { "월세" }
      price { "보증금 5천만원/월 120만원" }
    end

    trait :jeonse do
      deal_type { "전세" }
      price { "전세 6억원" }
    end
  end
end