class ZigbangApiClient
  include HTTParty
  base_uri 'https://apis.zigbang.com'

  def initialize
    @random_delay_range = (1..8)
  end

  def crawl_region_by_geohash(region, property_types)
    geohashes = get_geohashes_for_region(region)

    result = {
      total_saved: 0,
      successful_geohashes: 0,
      failed_geohashes: []
    }

    geohashes.each_with_index do |geohash, index|
      begin
        Rails.logger.info "🗺️ 처리 중: #{geohash} (#{index + 1}/#{geohashes.size})"

        property_ids = collect_property_ids_by_geohash(geohash, property_types)

        if property_ids.any?
          raw_properties = fetch_property_details(property_ids)
          converted_properties = PropertyDataTransformer.new.transform_batch(raw_properties)
          saved_count = PropertyPersister.new.save_geohash_properties(geohash, converted_properties)

          result[:total_saved] += saved_count
          result[:successful_geohashes] += 1

          Rails.logger.info "✅ #{geohash}: #{saved_count}개 매물 저장 완료"
        else
          Rails.logger.info "ℹ️ #{geohash}: 매물 없음"
          result[:successful_geohashes] += 1
        end

        sleep(rand(@random_delay_range))

      rescue => e
        Rails.logger.error "❌ #{geohash} 처리 실패: #{e.message}"
        result[:failed_geohashes] << geohash
        next
      end
    end

    Rails.logger.info "🎯 #{region} 크롤링 완료: 총 #{result[:total_saved]}개 매물 수집"
    result
  end

  def collect_property_ids_by_geohash(geohash, property_types = ['oneroom', 'villa', 'officetel'])
    all_ids = []

    property_types.each do |property_type|
      ids = fetch_property_ids_for_type(geohash, property_type)
      all_ids.concat(ids)

      Rails.logger.info "🔍 #{geohash} - #{property_type}: #{ids.size}개 ID 수집"
      sleep(rand(1..3))
    end

    all_ids.uniq
  end

  def fetch_property_details(property_ids)
    return [] if property_ids.empty?

    Rails.logger.info "📋 매물 상세정보 조회 시작: #{property_ids.size}개"

    all_properties = []
    property_ids.each_slice(15) do |batch_ids|
      begin
        properties = fetch_batch_property_details(batch_ids)
        all_properties.concat(properties)

        Rails.logger.info "📦 배치 조회 완료: #{properties.size}개"
        sleep(rand(@random_delay_range))

      rescue => e
        Rails.logger.error "❌ 배치 조회 실패: #{e.message}"
        next
      end
    end

    Rails.logger.info "✅ 전체 상세정보 조회 완료: #{all_properties.size}개"
    all_properties
  end

  private

  def get_geohashes_for_region(region)
    case region
    when :seoul
      KoreaGeohash.seoul_geohashes
    when :gyeonggi
      KoreaGeohash.gyeonggi_geohashes
    else
      raise ArgumentError, "Unknown region: #{region}"
    end
  end

  def fetch_property_ids_for_type(geohash, property_type)
    url = "/v2/items/#{property_type}"

    params = {
      geohash: geohash,
      deposit_range: '0,999999',
      rent_range: '0,999999',
      salesTypes: sales_types_for_property(property_type),
      domain: 'zigbang',
      checkAnyItemWithoutFilter: true
    }

    # 오피스텔인 경우 추가 파라미터
    if property_type == 'officetel'
      params[:withBuildings] = true
    end

    response = make_api_request(url, params)

    if response&.dig('items')
      response['items'].map { |item| item['itemId'] }.compact
    else
      []
    end
  end

  def fetch_batch_property_details(property_ids)
    url = "/house/v2/property/items/list"

    payload = {
      'itemIds' => property_ids
    }

    response = make_api_request(url, payload, :post)

    if response&.dig('items')
      response['items']
    else
      []
    end
  end

  def make_api_request(url, params, method = :get)
    headers = {
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Accept' => 'application/json',
      'Accept-Language' => 'ko-KR,ko;q=0.9,en;q=0.8',
      'Referer' => 'https://www.zigbang.com/',
      'X-Requested-With' => 'XMLHttpRequest'
    }

    begin
      case method
      when :get
        response = self.class.get(url, query: params, headers: headers, timeout: 30)
      when :post
        response = self.class.post(url, body: params.to_json, headers: headers.merge('Content-Type' => 'application/json'), timeout: 30)
      end

      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error "API 요청 실패: #{response.code} - #{response.message}"
        nil
      end
    rescue => e
      Rails.logger.error "API 요청 예외: #{e.message}"
      nil
    end
  end

  def sales_types_for_property(property_type)
    case property_type
    when 'oneroom'
      ['전세', '월세']
    when 'villa'
      ['전세', '월세', '매매']
    when 'officetel'
      ['전세', '월세', '매매']
    else
      ['전세', '월세']
    end
  end
end