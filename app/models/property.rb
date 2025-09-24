class Property < ApplicationRecord
  # 관계 설정
  has_one :apartment_detail, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :address, presence: true

  scope :by_service_type, ->(type) { where(service_type: type) }
  scope :by_sales_type, ->(type) { where(sales_type: type) }
  # PostGIS 기반 지역 검색 스코프
  scope :in_bounds, ->(ne_lat, ne_lng, sw_lat, sw_lng) {
    bbox = "POLYGON((#{sw_lng} #{sw_lat}, #{ne_lng} #{sw_lat}, #{ne_lng} #{ne_lat}, #{sw_lng} #{ne_lat}, #{sw_lng} #{sw_lat}))"
    where("ST_Within(location, ST_GeogFromText(?))", bbox)
  }

  # 반경 내 검색
  scope :within_distance, ->(lat, lng, distance_meters = 1000) {
    point = "POINT(#{lng} #{lat})"
    where("ST_DWithin(location, ST_GeogFromText(?), ?)", point, distance_meters)
  }

  # 기존 호환성 유지 (deprecated)
  scope :in_area, ->(lat_min, lat_max, lng_min, lng_max) {
    in_bounds(lat_max, lng_max, lat_min, lng_min)
  }

  def full_address
    address
  end
  
  def price_info
    case sales_type
    when '매매'
      "매매 #{format_currency(deposit)}"
    when '전세'
      "전세 #{format_currency(deposit)}"
    when '월세'
      if deposit && deposit > 0
        "월세 #{format_currency(deposit)}/#{format_currency(rent)}"
      else
        "월세 #{format_currency(rent)}"
      end
    else
      "#{sales_type} #{format_currency(deposit || rent)}"
    end
  end

  private

  def format_currency(amount)
    return '0원' if amount.nil? || amount == 0

    if amount >= 100_000_000
      eok = amount / 100_000_000
      remainder = amount % 100_000_000
      if remainder == 0
        "#{eok}억원"
      else
        man = remainder / 10_000
        "#{eok}억#{man}만원"
      end
    elsif amount >= 10_000
      man = amount / 10_000
      remainder = amount % 10_000
      if remainder == 0
        "#{man}만원"
      else
        "#{man}만#{remainder}원"
      end
    else
      "#{amount}원"
    end
  end
  
  def coordinate
    if respond_to?(:location) && location
      [location.y, location.x]  # [latitude, longitude]
    elsif latitude && longitude
      [latitude, longitude]     # 기존 데이터 사용
    end
  end

  # PostGIS location 설정 헬퍼
  def set_location(lat, lng)
    self.location = "POINT(#{lng} #{lat})" if respond_to?(:location)
    self.latitude = lat
    self.longitude = lng
  end

  def floor_info
    if floor && total_floor
      "#{floor}/#{total_floor}층"
    elsif floor.present?
      "#{floor}층"
    else
      nil
    end
  end

  def maintenance_fee_formatted
    return nil unless maintenance_fee
    "관리비 #{maintenance_fee.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}원"
  end

  def has_images?
    thumbnail_url.present?
  end

  def is_apartment?
    service_type == '아파트'
  end

  def detailed_address
    address
  end

  def with_apartment_details
    return self unless is_apartment?
    includes(:apartment_detail)
  end
end
