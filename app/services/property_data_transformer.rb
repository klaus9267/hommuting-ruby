class PropertyDataTransformer
  def transform_batch(raw_properties)
    raw_properties.map { |raw| transform_single(raw) }.compact
  end

  private

  def transform_single(api_data)
    return nil if api_data.blank?

    {
      property: build_property_data(api_data),
      address: build_address_data(api_data),
      apartment_detail: build_apartment_detail_data(api_data)
    }
  rescue => e
    Rails.logger.error "데이터 변환 실패: #{e.message}"
    Rails.logger.error "원본 데이터: #{api_data.inspect}"
    nil
  end

  def build_property_data(data)
    {
      title: data['title'],
      address_text: build_address_text(data),
      price: format_price(data),
      property_type: map_property_type(data['service_type']),
      deal_type: map_deal_type(data['sales_type']),
      area_description: data['area1'],
      area_sqm: parse_area_sqm(data['area1']),
      floor_description: data['floor'],
      current_floor: parse_current_floor(data['floor']),
      total_floors: parse_total_floors(data['floor']),
      room_structure: data['room_type_str'],
      maintenance_fee: data['manage_cost'],
      thumbnail_url: extract_thumbnail_url(data),
      latitude: data['lat'],
      longitude: data['lng'],
      external_id: data['item_id'].to_s,
      source: 'zigbang_api',
      raw_data: data
    }
  end

  def build_address_data(data)
    return nil unless data['address1'].present?

    local_parts = parse_address_parts(data['address1'])

    {
      local1: local_parts[0],
      local2: local_parts[1],
      local3: local_parts[2],
      local4: local_parts[3],
      short_address: data['address1'],
      full_address: [data['address1'], data['address2']].compact.join(' ')
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
    address_parts = [data['address1'], data['address2']].compact
    address_parts.join(' ').strip
  end

  def format_price(data)
    if data['rent'].to_i > 0 && data['deposit'].to_i > 0
      "전세 #{format_amount(data['deposit'])} / 월세 #{format_amount(data['rent'])}"
    elsif data['deposit'].to_i > 0
      "전세 #{format_amount(data['deposit'])}"
    elsif data['rent'].to_i > 0
      "월세 #{format_amount(data['rent'])}"
    elsif data['sales_price'].to_i > 0
      "매매 #{format_amount(data['sales_price'])}"
    else
      '가격정보없음'
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

  def map_deal_type(sales_type)
    case sales_type
    when 'R'
      '월세'
    when 'J'
      '전세'
    when 'S'
      '매매'
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
    if data['images'].present? && data['images'].is_a?(Array)
      data['images'].first
    elsif data['image_thumbnail'].present?
      data['image_thumbnail']
    else
      nil
    end
  end

  def parse_address_parts(address)
    # "서울특별시 강남구 역삼동" 형태를 파싱
    parts = address.split(' ')

    # 최대 4개 레벨까지 저장
    result = Array.new(4)
    parts.each_with_index do |part, index|
      result[index] = part if index < 4
    end

    result
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
end