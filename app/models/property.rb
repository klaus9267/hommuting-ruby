class Property < ApplicationRecord
  validates :title, presence: true
  validates :external_id, presence: true, uniqueness: true
  enum :property_type, {
    아파트: 'apartment',
    빌라: 'villa',
    오피스텔: 'officetel',
    단독주택: 'single_house',
    다가구: 'multi_house',
    주상복합: 'mixed_use'
  }

  enum :deal_type, {
    매매: 'sale',
    전세: 'jeonse',
    월세: 'monthly_rent'
  }
  
  scope :by_property_type, ->(type) { where(property_type: type) }
  scope :by_deal_type, ->(type) { where(deal_type: type) }
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
