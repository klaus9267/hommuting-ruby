class Property < ApplicationRecord
  # 관계 설정
  has_one :address, dependent: :destroy
  has_one :property_image, dependent: :destroy
  has_one :apartment_detail, dependent: :destroy

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
    "#{address_text}"
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

  # 새로운 필드들을 위한 메서드
  def area_in_pyeong
    return nil unless area_sqm
    (area_sqm / 3.3058).round(1)
  end

  def floor_info
    if current_floor && total_floors
      "#{current_floor}/#{total_floors}층"
    elsif floor_description.present?
      floor_description
    else
      floor
    end
  end

  def maintenance_fee_formatted
    return nil unless maintenance_fee
    "관리비 #{maintenance_fee.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}원"
  end

  def has_images?
    property_image&.has_images?
  end

  def is_apartment?
    property_type == 'apartment'
  end

  def detailed_address
    address&.full_location || self.address_text
  end

  def with_apartment_details
    return self unless is_apartment?
    includes(:apartment_detail)
  end
end
