class PropertyDataTransformer
  def transform_batch(raw_properties)
    raw_properties.map { |raw| transform_single(raw) }.compact
  end

  def transform_batch_with_geohash(raw_properties, geohash)
    raw_properties.map { |raw| transform_single_with_geohash(raw, geohash) }.compact
  end

  private

  def transform_single(api_data)
    return nil if api_data.blank?

    {
      property: build_property_data(api_data),
      apartment_detail: build_apartment_detail_data(api_data)
    }
  rescue => e
    Rails.logger.error "데이터 변환 실패: #{e.message}"
    Rails.logger.error "원본 데이터: #{api_data.inspect}"
    nil
  end

  def transform_single_with_geohash(api_data, geohash)
    return nil if api_data.blank?

    {
      property: build_property_data(api_data, geohash),
      apartment_detail: build_apartment_detail_data(api_data)
    }
  rescue => e
    Rails.logger.error "데이터 변환 실패 (geohash: #{geohash}): #{e.message}"
    Rails.logger.error "원본 데이터: #{api_data.inspect}"
    nil
  end

  def build_property_data(data, geohash = nil)
    {
      address: build_address_text(data),
      description: data['title'],
      sales_type: data['sales_type'],
      deposit: data['deposit']&.to_i,
      rent: data['rent']&.to_i,
      service_type: map_property_type(data['service_type']),
      floor: parse_current_floor_from_api(data),
      total_floor: parse_total_floors_from_api(data),
      room_type: data['room_type'],
      maintenance_fee: data['manage_cost']&.to_i,
      thumbnail_url: extract_thumbnail_url(data),
      latitude: extract_latitude(data),
      longitude: extract_longitude(data),
      external_id: data['item_id'].to_s,
      geohash: geohash
    }
  end


  def build_apartment_detail_data(data)
    return nil unless is_apartment_type?(data)

    {
      area_ho_id: data['area_ho_id'],
      area_danji_id: data['area_danji_id'],
      area_danji_name: data['area_danji_name'],
      danji_room_type_id: data['danji_room_type_id'],
      dong: data['dong'],
      room_type_title: data['room_type_title'],
      size_contract_m2: data['size_contract_m2'],
      tran_type: data['tran_type'],
      item_type: data['item_type'],
      is_price_range: data['is_price_range'] || false
    }
  end

  def build_address_text(data)
    # 직방 API 응답에서 주소 텍스트 생성
    if data['addressOrigin'].present?
      data['addressOrigin']['fullText'] || data['addressOrigin']['localText']
    else
      address1 = data['address1'] || data['address']
      address2 = data['address2']
      address_parts = [address1, address2].compact
      address_parts.join(' ').strip
    end
  end

   def map_property_type(service_type)
    case service_type
    when 'oneroom', '원룸'
      '원룸'
    when 'villa', '빌라'
      '빌라'
    when 'officetel', '오피스텔'
      '오피스텔'
    when 'apartment', '아파트'
      '아파트'
    else
      '기타'
    end
  end

  def parse_area_sqm(area_text)
    return nil if area_text.blank?

    # "23.14㎡" 형태에서 숫자 추출
    area_text.to_s.scan(/[\d.]+/).first&.to_f
  end

  def parse_current_floor(floor_text)
    return nil if floor_text.blank?

    # "3층/10층" 형태에서 현재 층 추출
    parts = floor_text.to_s.split('/')
    parts.first&.gsub(/[^0-9-]/, '')&.to_i
  end

  def parse_total_floors(floor_text)
    return nil if floor_text.blank?

    # "3층/10층" 형태에서 총 층수 추출
    parts = floor_text.to_s.split('/')
    parts.last&.gsub(/[^0-9]/, '')&.to_i if parts.size > 1
  end

  def extract_thumbnail_url(data)
    # 직방 API 응답의 실제 이미지 구조에 맞게 수정
    data['images_thumbnail'] || data['image_thumbnail'] || data['thumbnail']
  end


  def is_apartment_type?(data)
    data['service_type'] == 'apartment' || data['area_danji_id'].present?
  end

  def format_amount(amount)
    amount = amount.to_i
    return '0원' if amount == 0

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


  def extract_latitude(data)
    if data['location'].present?
      data['location']['lat']
    elsif data['random_location'].present?
      data['random_location']['lat']
    else
      data['lat']
    end
  end

  def extract_longitude(data)
    if data['location'].present?
      data['location']['lng']
    elsif data['random_location'].present?
      data['random_location']['lng']
    else
      data['lng']
    end
  end

  def parse_current_floor_from_api(data)
    if data['floor'].present?
      floor_text = data['floor'].to_s
      # "저", "중", "고" 등의 경우 숫자가 아니므로 nil 반환
      return nil if floor_text.match?(/[저중고반지]/i)

      floor_text.gsub(/[^0-9-]/, '').to_i if floor_text.match?(/\d/)
    end
  end

  def parse_total_floors_from_api(data)
    data['building_floor']&.to_i if data['building_floor'].present?
  end
end