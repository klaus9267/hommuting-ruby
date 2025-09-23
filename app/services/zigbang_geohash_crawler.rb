class ZigbangGeohashCrawler
  include HTTParty

  base_uri 'https://apis.zigbang.com'

  def initialize
    setup_headers
  end

  # 1단계: 특정 geohash 영역의 매물 ID 수집
  def collect_property_ids_by_geohash(geohash, property_types = ['oneroom'])
    all_ids = []

    property_types.each do |property_type|
      Rails.logger.info "🔍 #{geohash} 영역의 #{property_type} ID 수집 시작"

      ids = fetch_property_ids_for_type(geohash, property_type)
      Rails.logger.info "📊 #{geohash} #{property_type}: #{ids.size}개 ID 수집"

      all_ids.concat(ids.map { |id| { id: id, property_type: property_type, geohash: geohash } })

      # 요청 간 대기 (안티 봇)
      sleep(rand(1..3))
    end

    Rails.logger.info "✅ #{geohash} 총 #{all_ids.size}개 ID 수집 완료"
    all_ids
  end

  # 2단계: 수집된 ID들로 상세 정보 조회 (15개씩 배치)
  def fetch_property_details(property_id_data_array)
    return [] if property_id_data_array.empty?

    Rails.logger.info "📋 총 #{property_id_data_array.size}개 매물 상세정보 조회 시작"

    all_properties = []
    property_id_data_array.each_slice(15).with_index do |batch_data, batch_index|
      Rails.logger.info "   배치 #{batch_index + 1}: #{batch_data.size}개 처리"

      # ID만 추출
      batch_ids = batch_data.map { |data| data[:id] }

      begin
        response = self.class.post('/house/v2/property/items/list',
          body: { itemIds: batch_ids }.to_json,
          headers: @headers.merge('Content-Type' => 'application/json'),
          timeout: 30
        )

        if response.success?
          properties = response.parsed_response['items'] || []

          # 원본 property_type과 geohash 정보 추가
          properties.each do |property|
            property_data = batch_data.find { |data| data[:id] == property['item_id'] }
            if property_data
              property['original_property_type'] = property_data[:property_type]
              property['geohash'] = property_data[:geohash]
            end
          end

          all_properties.concat(properties)
          Rails.logger.info "   ✅ #{properties.size}개 매물 정보 수집"
        else
          Rails.logger.error "   ❌ 배치 #{batch_index + 1} 실패: #{response.code}"
          Rails.logger.error "   ❌ 응답: #{response.body}"
        end

      rescue => e
        Rails.logger.error "   ❌ 배치 #{batch_index + 1} 오류: #{e.message}"
      end

      # 배치 간 대기 (안티 봇)
      sleep(rand(3..8)) if batch_index < (property_id_data_array.size / 15.0).ceil - 1
    end

    Rails.logger.info "🎉 총 #{all_properties.size}개 매물 상세정보 수집 완료"
    all_properties
  end

  # 전체 지역별 크롤링 (새로운 geohash 기반)
  def crawl_region_by_geohash(region, property_types = ['oneroom', 'villa', 'officetel'])
    Rails.logger.info "🚀 #{region} 지역 geohash 기반 크롤링 시작"

    geohashes = KoreaGeohash.geohashes_for_region(region)
    Rails.logger.info "📍 총 #{geohashes.size}개 geohash 영역 처리"

    all_property_ids = []

    # 1단계: 모든 geohash 영역에서 ID 수집
    geohashes.each_with_index do |geohash, index|
      Rails.logger.info "🗺️ [#{index + 1}/#{geohashes.size}] #{geohash} 영역 처리"

      property_ids = collect_property_ids_by_geohash(geohash, property_types)
      all_property_ids.concat(property_ids)

      # geohash 간 대기
      sleep(rand(2..5))
    end

    Rails.logger.info "🔍 1단계 완료: 총 #{all_property_ids.size}개 ID 수집"

    # 2단계: 수집된 모든 ID로 상세 정보 조회
    Rails.logger.info "📋 2단계 시작: 상세 정보 수집"
    raw_properties = fetch_property_details(all_property_ids)

    # 3단계: 데이터 변환
    Rails.logger.info "🔄 3단계: 데이터 변환 시작"
    converted_properties = raw_properties.map do |raw_prop|
      convert_api_data_to_property(raw_prop)
    end.compact

    Rails.logger.info "✅ #{region} 지역 크롤링 완료: #{converted_properties.size}개 매물"
    converted_properties
  end

  private

  def fetch_property_ids_for_type(geohash, property_type)
    case property_type
    when 'oneroom'
      fetch_oneroom_ids(geohash)
    when 'villa'
      fetch_villa_ids(geohash)
    when 'officetel'
      fetch_officetel_ids(geohash)
    else
      []
    end
  end

  def fetch_oneroom_ids(geohash)
    params = {
      geohash: geohash,
      depositMin: 0,
      rentMin: 0,
      salesTypes: ['전세', '월세'],
      domain: 'zigbang',
      checkAnyItemWithoutFilter: true
    }

    response = self.class.get('/v2/items/oneroom', query: params, headers: @headers, timeout: 30)

    if response.success?
      data = response.parsed_response
      data&.dig('items')&.map { |item| item['itemId'] } || []
    else
      Rails.logger.error "❌ 원룸 ID 수집 실패: #{response.code}"
      []
    end
  end

  def fetch_villa_ids(geohash)
    params = {
      geohash: geohash,
      depositMin: 0,
      rentMin: 0,
      salesPriceMin: 0,
      salesTypes: ['전세', '월세', '매매'],
      domain: 'zigbang',
      checkAnyItemWithoutFilter: true
    }

    response = self.class.get('/v2/items/villa', query: params, headers: @headers, timeout: 30)

    if response.success?
      data = response.parsed_response
      data&.dig('items')&.map { |item| item['itemId'] } || []
    else
      Rails.logger.error "❌ 빌라 ID 수집 실패: #{response.code}"
      []
    end
  end

  def fetch_officetel_ids(geohash)
    params = {
      geohash: geohash,
      depositMin: 0,
      rentMin: 0,
      salesPriceMin: 0,
      salesTypes: ['전세', '월세', '매매'],
      domain: 'zigbang',
      checkAnyItemWithoutFilter: true,
      withBuildings: true
    }

    response = self.class.get('/v2/items/officetel', query: params, headers: @headers, timeout: 30)

    if response.success?
      data = response.parsed_response
      data&.dig('items')&.map { |item| item['itemId'] } || []
    else
      Rails.logger.error "❌ 오피스텔 ID 수집 실패: #{response.code}"
      []
    end
  end

  def setup_headers
    @headers = {
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Accept' => 'application/json, text/plain, */*',
      'Accept-Language' => 'ko-KR,ko;q=0.9,en;q=0.8',
      'Connection' => 'keep-alive',
      'Sec-Fetch-Dest' => 'empty',
      'Sec-Fetch-Mode' => 'cors',
      'Sec-Fetch-Site' => 'same-site',
      'Referer' => 'https://www.zigbang.com/',
      'Origin' => 'https://www.zigbang.com'
    }
  end

  def convert_api_data_to_property(api_data)
    begin
      # API 응답에서 주소 정보 추출
      address_info = api_data['addressOrigin'] || {}
      area_name = address_info['localText'] || api_data['address'] || '정보없음'

      # Property 기본 데이터
      property_data = {
        title: api_data['title'] || "#{area_name} #{api_data['service_type']}",
        address_text: api_data['address'] || area_name,
        price: format_price_from_api(api_data),
        property_type: map_service_type(api_data['service_type']),
        deal_type: map_sales_type(api_data['sales_type']),
        area: "#{api_data['size_m2'] || 0}㎡",
        floor: api_data['floor_string'] || "#{api_data['floor'] || 0}층",
        description: api_data['title'] || "직방 API로 수집된 #{area_name} 매물",
        area_description: "#{api_data['size_m2']}㎡" || "정보없음",
        area_sqm: api_data['size_m2']&.to_f,
        floor_description: api_data['floor_string'] || "정보없음",
        current_floor: parse_floor(api_data['floor']),
        total_floors: api_data['building_floor']&.to_i,
        room_structure: api_data['room_type'] || "정보없음",
        maintenance_fee: api_data['manage_cost']&.to_i || 0,
        latitude: api_data.dig('location', 'lat')&.to_f,
        longitude: api_data.dig('location', 'lng')&.to_f,
        external_id: "zigbang_api_#{api_data['item_id']}",
        source: 'zigbang_api',
        raw_data: api_data
      }

      {
        property: property_data,
        address: extract_address_from_api(api_data),
        property_image: extract_image_from_api(api_data),
        apartment_detail: extract_apartment_detail_from_api(api_data)
      }
    rescue => e
      Rails.logger.error "매물 데이터 변환 실패: #{e.message}"
      nil
    end
  end

  def format_price_from_api(api_data)
    sales_type = api_data['sales_type']
    deposit = api_data['deposit']&.to_i || 0
    rent = api_data['rent']&.to_i || 0

    case sales_type
    when '월세'
      "#{deposit}/#{rent}"
    when '전세'
      "#{deposit}"
    when '매매'
      # sales_price가 있다면 사용, 없다면 deposit 사용
      price = api_data['sales_price']&.to_i || deposit
      "#{price}"
    else
      "정보없음"
    end
  end

  def map_service_type(service_type)
    case service_type
    when '원룸' then '원룸'
    when '빌라' then '빌라'
    when '오피스텔' then '오피스텔'
    when '아파트' then '아파트'
    else service_type || '기타'
    end
  end

  def map_sales_type(sales_type)
    case sales_type
    when '월세' then '월세'
    when '전세' then '전세'
    when '매매' then '매매'
    else '기타'
    end
  end

  def parse_floor(floor_string)
    return nil if floor_string.nil?

    case floor_string.to_s
    when '반지하'
      -1
    when '옥탑방', '옥상'
      999
    else
      floor_string.to_i
    end
  end

  def extract_address_from_api(api_data)
    address_info = api_data['addressOrigin'] || {}

    {
      local1: address_info['local1'] || '정보없음',
      local2: address_info['local2'] || '정보없음',
      local3: address_info['local3'],
      local4: address_info['local4'],
      short_address: address_info['localText'] || api_data['address'] || '정보없음',
      full_address: address_info['fullText'] || api_data['address'] || '정보없음'
    }
  end

  def extract_image_from_api(api_data)
    {
      thumbnail_url: api_data['images_thumbnail'] || 'https://via.placeholder.com/300x200',
      image_urls: api_data['images'] || []
    }
  end

  def extract_apartment_detail_from_api(api_data)
    return nil unless api_data['service_type'] == '아파트'

    {
      area_ho_id: nil,
      area_danji_id: nil,
      area_danji_name: nil,
      danji_room_type_id: nil,
      dong: nil,
      room_type_title: api_data['room_type_title'],
      size_contract_m2: api_data['size_m2']&.to_f,
      tran_type: api_data['sales_type'],
      item_type: map_service_type(api_data['service_type']),
      is_price_range: false
    }
  end
end