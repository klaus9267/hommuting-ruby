class Property < ApplicationRecord
  validates :title, presence: true
  validates :external_id, presence: true, uniqueness: { scope: :source }
  validates :source, presence: true
  validates :property_type, inclusion: { in: %w[아파트 빌라 오피스텔 단독주택 다가구 주상복합] }
  validates :deal_type, inclusion: { in: %w[매매 전세 월세] }
  
  scope :by_property_type, ->(type) { where(property_type: type) }
  scope :by_deal_type, ->(type) { where(deal_type: type) }
  scope :by_source, ->(source) { where(source: source) }
  scope :in_area, ->(lat_min, lat_max, lng_min, lng_max) { 
    where(latitude: lat_min..lat_max, longitude: lng_min..lng_max) 
  }
  
  def full_address
    "#{address}"
  end
  
  def price_info
    case deal_type
    when '매매'
      "매매 #{price}"
    when '전세'
      "전세 #{price}"
    when '월세'
      "월세 #{price}"
    else
      price
    end
  end
  
  def coordinate
    [latitude, longitude] if latitude && longitude
  end
end
