class ZigbangApiCrawler
  include HTTParty

  base_uri 'https://apis.zigbang.com'

  def initialize
    setup_headers
  end

  def get_property_ids_for_area(property_type, bounds, sales_types = nil)
    Rails.logger.info "🔍 #{property_type} 매물 ID 조회: #{bounds[:geohash]}"

    # 매물 타입에 따른 적절한 거래 유형 설정
    sales_types ||= get_default_sales_types(property_type)
    Rails.logger.info "🏷️ 사용할 거래 유형: #{sales_types.inspect}"

    params = {
      geohash: bounds[:geohash],
      depositMin: 0,
      rentMin: 0,
      salesPriceMin: 0,
      lngEast: bounds[:lng_east],
      lngWest: bounds[:lng_west],
      latSouth: bounds[:lat_south],
      latNorth: bounds[:lat_north],
      domain: 'zigbang',
      checkAnyItemWithoutFilter: true
    }

    # 거래 타입 추가
    sales_types.each_with_index do |type, index|
      params["salesTypes[#{index}]"] = type
    end

    begin
      Rails.logger.info "🔄 API 요청 파라미터: #{params.inspect}"
      Rails.logger.info "🔄 요청 URL: /v2/items/#{property_type}"

      response = self.class.get("/v2/items/#{property_type}",
        query: params,
        headers: @headers,
        timeout: 30
      )

      if response.success?
        Rails.logger.info "✅ API 응답 성공: #{response.code}"
        data = response.parsed_response

        property_ids = data&.dig('items')&.map { |item| item['itemId'] } || []
        Rails.logger.info "📊 #{property_ids.size}개 매물 ID 수집"
        property_ids
      else
        Rails.logger.error "❌ API 요청 실패: #{response.code} #{response.message}"
        Rails.logger.error "❌ 응답 본문: #{response.body}"
        Rails.logger.error "❌ 응답 헤더: #{response.headers}"
        []
      end

    rescue => e
      Rails.logger.error "❌ 요청 오류: #{e.message}"
      []
    end
  end

  def get_property_details(property_ids)
    return [] if property_ids.empty?

    Rails.logger.info "📋 #{property_ids.size}개 매물 상세정보 조회"

    # 배치 처리 (15개씩 - API 제한)
    all_properties = []
    property_ids.each_slice(15).with_index do |batch_ids, batch_index|
      Rails.logger.info "   배치 #{batch_index + 1}: #{batch_ids.size}개 처리"

      begin
        response = self.class.post('/house/v2/property/items/list',
          body: { itemIds: batch_ids }.to_json,
          headers: @headers.merge('Content-Type' => 'application/json'),
          timeout: 30
        )

        if response.success?
          properties = response.parsed_response['items'] || []
          all_properties.concat(properties)
          Rails.logger.info "   ✅ #{properties.size}개 매물 정보 수집"
        else
          Rails.logger.error "   ❌ 배치 #{batch_index + 1} 실패: #{response.code}"
          Rails.logger.error "   ❌ 상세 응답: #{response.body}"
          Rails.logger.error "   ❌ 요청 데이터: #{batch_ids.inspect}"
        end

      rescue => e
        Rails.logger.error "   ❌ 배치 #{batch_index + 1} 오류: #{e.message}"
      end

      # 안티 봇 대기 (배치 간 3-8초 랜덤)
      sleep(rand(3..8)) if batch_index < (property_ids.size / 15.0).ceil - 1
    end

    Rails.logger.info "🎉 총 #{all_properties.size}개 매물 상세정보 수집 완료"
    all_properties
  end

  def crawl_area_properties(area_name, property_type, bounds)
    Rails.logger.info "🏠 #{area_name} #{property_type} 크롤링 시작"
    Rails.logger.info "🏠 bounds: #{bounds.inspect}"

    # 1단계: 매물 ID 목록 조회
    Rails.logger.info "🔍 1단계: 매물 ID 수집 시작"
    property_ids = get_property_ids_for_area(property_type, bounds)
    Rails.logger.info "🔍 1단계 완료: #{property_ids.size}개 ID 수집"
    return [] if property_ids.empty?

    # 2단계: 매물 상세 정보 조회
    Rails.logger.info "📋 2단계: 상세 정보 수집 시작"
    raw_properties = get_property_details(property_ids)
    Rails.logger.info "📋 2단계 완료: #{raw_properties.size}개 상세정보 수집"

    # 3단계: 데이터 변환
    Rails.logger.info "🔄 3단계: 데이터 변환 시작"
    converted_properties = raw_properties.map do |raw_prop|
      convert_api_data_to_property(raw_prop, area_name, property_type)
    end.compact

    Rails.logger.info "✅ #{area_name} #{property_type}: #{converted_properties.size}개 매물 변환 완료"
    converted_properties
  end

  # 지역별 크롤링 메소드들
  def crawl_all_seoul_districts(property_types = ['villa', 'oneroom', 'officetel'])
    results = []

    KoreaRegions.districts_for_region(:seoul).each do |district|
      bounds = KoreaRegions.get_region_bounds(:seoul, district)
      next unless bounds

      property_types.each do |property_type|
        properties = crawl_area_properties(district, property_type, bounds)
        results.concat(properties)

        # 지역간 대기 (안티 봇)
        sleep(rand(5..10))
      end
    end

    results
  end

  def crawl_all_gyeonggi_districts(property_types = ['villa', 'oneroom', 'officetel'])
    results = []

    KoreaRegions.districts_for_region(:gyeonggi).each do |district|
      bounds = KoreaRegions.get_region_bounds(:gyeonggi, district)
      next unless bounds

      property_types.each do |property_type|
        properties = crawl_area_properties(district, property_type, bounds)
        results.concat(properties)

        # 지역간 대기 (안티 봇)
        sleep(rand(5..10))
      end
    end

    results
  end

  def crawl_specific_district(region, district, property_types = ['villa', 'oneroom', 'officetel'])
    Rails.logger.info "🎯 crawl_specific_district 시작: #{region}, #{district}"
    Rails.logger.info "🎯 property_types: #{property_types.inspect}"

    bounds = KoreaRegions.get_region_bounds(region, district)
    if bounds.nil?
      Rails.logger.error "❌ 지역 bounds를 찾을 수 없음: #{region}, #{district}"
      return []
    end
    Rails.logger.info "🎯 bounds: #{bounds.inspect}"

    results = []
    property_types.each do |property_type|
      Rails.logger.info "🎯 매물 타입 처리 시작: #{property_type}"
      properties = crawl_area_properties(district, property_type, bounds)
      Rails.logger.info "🎯 매물 타입 처리 완료: #{property_type}, #{properties.size}개"
      results.concat(properties)

      # 매물 타입간 대기
      sleep_time = rand(3..8)
      Rails.logger.info "⏰ 대기: #{sleep_time}초"
      sleep(sleep_time)
    end

    Rails.logger.info "🎯 crawl_specific_district 완료: 총 #{results.size}개"
    results
  end

  private

  def get_default_sales_types(property_type)
    case property_type.downcase
    when 'oneroom'
      ['전세', '월세'] # 원룸은 매매 불가
    when 'villa'
      ['전세', '월세', '매매']
    when 'officetel'
      ['전세', '월세', '매매']
    when 'apartment'
      ['전세', '월세', '매매']
    else
      ['전세', '월세'] # 기본값으로 안전한 옵션
    end
  end

  def convert_api_data_to_property(api_data, area_name, property_type)
    begin
      # Property 기본 데이터
      property_data = {
        title: api_data['title'] || "#{area_name} #{property_type}",
        address_text: api_data['address'] || area_name,
        price: format_price(api_data),
        property_type: map_api_property_type(property_type),
        deal_type: map_api_deal_type(api_data['salesType']),
        area: "#{api_data['area1'] || 0}㎡",
        floor: "#{api_data['floor'] || 0}층",
        description: api_data['description'] || "직방 API로 수집된 #{area_name} #{property_type} 매물",
        area_description: "#{api_data['area1']}㎡" || "정보없음",
        area_sqm: api_data['area1']&.to_f,
        floor_description: "#{api_data['floor']}층" || "정보없음",
        current_floor: api_data['floor']&.to_i,
        room_structure: api_data['roomType'] || "정보없음",
        maintenance_fee: api_data['managementCost'] || 0,
        latitude: api_data['lat']&.to_f,
        longitude: api_data['lng']&.to_f,
        external_id: "zigbang_api_#{api_data['itemId']}",
        source: 'zigbang_api',
        raw_data: api_data
      }

      {
        property: property_data,
        address: extract_address_data(api_data, area_name),
        property_image: extract_image_data(api_data),
        apartment_detail: extract_apartment_detail_data(api_data, property_type)
      }
    rescue => e
      Rails.logger.error "매물 데이터 변환 실패: #{e.message}"
      nil
    end
  end

  def setup_headers
    @headers = {
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Accept' => 'application/json, text/plain, */*',
      'Accept-Language' => 'ko-KR,ko;q=0.9,en;q=0.8',
      # HTTParty가 자동으로 압축 해제하도록 제거하거나 identity로 설정
      # 'Accept-Encoding' => 'identity',
      'Connection' => 'keep-alive',
      'Sec-Fetch-Dest' => 'empty',
      'Sec-Fetch-Mode' => 'cors',
      'Sec-Fetch-Site' => 'same-site',
      'Referer' => 'https://www.zigbang.com/',
      'Origin' => 'https://www.zigbang.com'
    }
  end

  def extract_address_data(api_data, area_name)
    address_text = api_data['address'] || area_name
    address_parts = address_text.split(' ')

    {
      local1: address_parts[0] || area_name.split(' ').first,
      local2: address_parts[1] || area_name.split(' ').last,
      local3: address_parts[2],
      local4: address_parts[3..-1]&.join(' '),
      short_address: address_parts[1..2]&.compact&.join(' ') || area_name,
      full_address: address_text
    }
  end

  def extract_image_data(api_data)
    {
      thumbnail_url: api_data['imgThumbnail'] || api_data['images']&.first || 'https://via.placeholder.com/300x200',
      image_urls: api_data['images'] || []
    }
  end

  def extract_apartment_detail_data(api_data, property_type)
    return nil unless property_type.downcase == 'apartment'

    {
      area_ho_id: api_data['areaHoId']&.to_i,
      area_danji_id: api_data['areaDanjiId']&.to_i,
      area_danji_name: api_data['areaDanjiName'],
      danji_room_type_id: api_data['danjiRoomTypeId']&.to_i,
      dong: api_data['dong'],
      room_type_title: api_data['roomTypeTitle'],
      size_contract_m2: api_data['sizeContractM2']&.to_f,
      tran_type: api_data['salesType'],
      item_type: map_api_property_type(property_type),
      is_price_range: api_data['isPriceRange'] || false
    }
  end

  def format_price(api_data)
    sales_type = api_data['salesType']
    deposit = api_data['deposit']&.to_i || 0
    rent = api_data['rent']&.to_i || 0
    sales_price = api_data['salesPrice']&.to_i || 0

    case sales_type
    when '월세'
      "#{deposit}/#{rent}"
    when '전세'
      "#{deposit}"
    when '매매'
      "#{sales_price}"
    else
      "정보없음"
    end
  end

  def map_api_property_type(api_type)
    case api_type.downcase
    when 'villa' then '빌라'
    when 'oneroom' then '원룸'
    when 'officetel' then '오피스텔'
    when 'apartment' then '아파트'
    else api_type
    end
  end

  def map_api_deal_type(sales_type)
    case sales_type
    when '월세' then '월세'
    when '전세' then '전세'
    when '매매' then '매매'
    else '기타'
    end
  end

end