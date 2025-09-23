class Api::V1::CrawlingController < ApplicationController
  # POST /api/v1/crawling/seoul
  def seoul
    begin
      Rails.logger.info "🚀 서울 지역 geohash 기반 크롤링 시작"

      dev_mode = params[:dev_mode] == 'true'
      property_types = process_property_types(params[:property_types])

      crawler = ZigbangGeohashCrawler.new

      if dev_mode
        Rails.logger.info "🏠 개발 모드: 제한된 geohash만 테스트"
        # 개발 모드: 서울 일부 geohash만 테스트
        test_geohashes = ['wydm5']
        raw_properties = crawl_specific_geohashes(crawler, test_geohashes, property_types)
      else
        Rails.logger.info "🏠 전체 모드: 서울 전체 geohash 크롤링"
        raw_properties = crawler.crawl_region_by_geohash(:seoul, property_types)
      end

      # DB 저장
      saved_properties = save_properties_to_db(raw_properties)

      render json: {
        status: 'success',
        message: dev_mode ? '서울 테스트 geohash 매물 수집 완료' : '서울 전체 매물 수집 완료',
        collected_count: saved_properties.size,
        property_types: saved_properties.group_by { |p| p['property_type'] }.transform_values(&:count),
        sample_properties: get_sample_properties(saved_properties, 3),
        geohash_count: dev_mode ? 3 : KoreaGeohash.seoul_geohashes.size,
        dev_mode: dev_mode,
        timestamp: Time.current
      }
    rescue => e
      Rails.logger.error "❌ 서울 크롤링 오류: #{e.message}"
      render json: {
        status: 'error',
        message: '서울 매물 수집 중 오류가 발생했습니다',
        error: e.message
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/crawling/gyeonggi
  def gyeonggi
    begin
      Rails.logger.info "🚀 경기도 지역 geohash 기반 크롤링 시작"

      dev_mode = params[:dev_mode] == 'true'
      property_types = process_property_types(params[:property_types])

      crawler = ZigbangGeohashCrawler.new

      if dev_mode
        Rails.logger.info "🏠 개발 모드: 제한된 geohash만 테스트"
        # 개발 모드: 경기도 일부 geohash만 테스트
        test_geohashes = ['wydf3', 'wydk7', 'wydh5']
        raw_properties = crawl_specific_geohashes(crawler, test_geohashes, property_types)
      else
        Rails.logger.info "🏠 전체 모드: 경기도 전체 geohash 크롤링"
        raw_properties = crawler.crawl_region_by_geohash(:gyeonggi, property_types)
      end

      # DB 저장
      saved_properties = save_properties_to_db(raw_properties)

      render json: {
        status: 'success',
        message: dev_mode ? '경기도 테스트 geohash 매물 수집 완료' : '경기도 전체 매물 수집 완료',
        collected_count: saved_properties.size,
        property_types: saved_properties.group_by { |p| p['property_type'] }.transform_values(&:count),
        sample_properties: get_sample_properties(saved_properties, 3),
        geohash_count: dev_mode ? 3 : KoreaGeohash.gyeonggi_geohashes.size,
        dev_mode: dev_mode,
        timestamp: Time.current
      }
    rescue => e
      Rails.logger.error "❌ 경기도 크롤링 오류: #{e.message}"
      render json: {
        status: 'error',
        message: '경기도 매물 수집 중 오류가 발생했습니다',
        error: e.message
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/crawling/all
  def all
    begin
      Rails.logger.info "🚀 서울+경기도 전체 geohash 기반 크롤링 시작"

      dev_mode = params[:dev_mode] == 'true'
      property_types = process_property_types(params[:property_types])

      crawler = ZigbangGeohashCrawler.new

      if dev_mode
        Rails.logger.info "🏠 개발 모드: 제한된 geohash만 테스트"
        # 개발 모드: 서울+경기도 일부 geohash만 테스트
        seoul_test = ['wydm3', 'wydm7']
        gyeonggi_test = ['wydf3', 'wydk7']

        seoul_properties = crawl_specific_geohashes(crawler, seoul_test, property_types)
        sleep(10) # 지역간 대기
        gyeonggi_properties = crawl_specific_geohashes(crawler, gyeonggi_test, property_types)
      else
        Rails.logger.info "🏠 전체 모드: 서울+경기도 전체 geohash 크롤링"
        seoul_properties = crawler.crawl_region_by_geohash(:seoul, property_types)
        sleep(10) # 지역간 대기
        gyeonggi_properties = crawler.crawl_region_by_geohash(:gyeonggi, property_types)
      end

      # DB 저장
      seoul_saved = save_properties_to_db(seoul_properties)
      gyeonggi_saved = save_properties_to_db(gyeonggi_properties)

      total_count = seoul_saved.size + gyeonggi_saved.size

      render json: {
        status: 'success',
        message: dev_mode ? '서울+경기도 테스트 geohash 매물 수집 완료' : '서울+경기도 전체 매물 수집 완료',
        total_collected: total_count,
        breakdown: {
          seoul: {
            count: seoul_saved.size,
            geohash_count: dev_mode ? 2 : KoreaGeohash.seoul_geohashes.size,
            property_types: seoul_saved.group_by { |p| p['property_type'] }.transform_values(&:count),
            sample_properties: get_sample_properties(seoul_saved, 2)
          },
          gyeonggi: {
            count: gyeonggi_saved.size,
            geohash_count: dev_mode ? 2 : KoreaGeohash.gyeonggi_geohashes.size,
            property_types: gyeonggi_saved.group_by { |p| p['property_type'] }.transform_values(&:count),
            sample_properties: get_sample_properties(gyeonggi_saved, 2)
          }
        },
        dev_mode: dev_mode,
        timestamp: Time.current
      }
    rescue => e
      Rails.logger.error "❌ 전체 크롤링 오류: #{e.message}"
      render json: {
        status: 'error',
        message: '전체 매물 수집 중 오류가 발생했습니다',
        error: e.message
      }, status: :internal_server_error
    end
  end

  # GET /api/v1/crawling/geohash
  def geohash_info
    render json: {
      total_geohashes: KoreaGeohash.all_geohashes.size,
      seoul: {
        count: KoreaGeohash.seoul_geohashes.size,
        geohashes: KoreaGeohash.seoul_geohashes.first(10) # 처음 10개만 표시
      },
      gyeonggi: {
        count: KoreaGeohash.gyeonggi_geohashes.size,
        geohashes: KoreaGeohash.gyeonggi_geohashes.first(10) # 처음 10개만 표시
      },
      supported_property_types: ['oneroom', 'villa', 'officetel']
    }
  end

  # GET /api/v1/crawling/status
  def status
    render json: {
      total_properties: Property.count,
      seoul_properties: Property.where("address_text LIKE '%서울%' OR address_text LIKE '%강남%' OR address_text LIKE '%강북%'").count,
      gyeonggi_properties: Property.where("address_text LIKE '%경기%' OR address_text LIKE '%수원%' OR address_text LIKE '%성남%'").count,
      by_property_type: Property.group(:property_type).count,
      by_deal_type: Property.group(:deal_type).count,
      by_source: Property.group(:source).count,
      last_updated: Property.maximum(:updated_at),
      recent_properties: Property.order(created_at: :desc).limit(10).select(:id, :title, :address_text, :property_type, :deal_type, :source, :created_at)
    }
  end

  private

  def process_property_types(params_property_types)
    if params_property_types.present?
      params_property_types.is_a?(Array) ? params_property_types : [params_property_types]
    else
      ['oneroom', 'villa', 'officetel']
    end
  end

  def crawl_specific_geohashes(crawler, geohashes, property_types)
    Rails.logger.info "🗺️ 특정 geohash 크롤링: #{geohashes.inspect}"

    all_property_ids = []

    # 1단계: 지정된 geohash들에서 ID 수집
    geohashes.each do |geohash|
      property_ids = crawler.collect_property_ids_by_geohash(geohash, property_types)
      all_property_ids.concat(property_ids)
      sleep(rand(2..5))
    end

    Rails.logger.info "🔍 ID 수집 완료: 총 #{all_property_ids.size}개"

    # 2단계: 수집된 ID로 상세 정보 조회
    raw_properties = crawler.fetch_property_details(all_property_ids)

    # 3단계: 데이터 변환
    raw_properties.map do |raw_prop|
      crawler.send(:convert_api_data_to_property, raw_prop)
    end.compact
  end

  def save_properties_to_db(raw_properties)
    return [] if raw_properties.empty?

    saved_properties = []

    raw_properties.each do |property_data|
      begin
        next if property_data.nil?

        # 중복 체크 (external_id 기준)
        existing = Property.find_by(external_id: property_data[:property][:external_id])

        if existing
          # 기존 매물 업데이트
          update_existing_property(existing, property_data)
          saved_properties << existing.reload.attributes
        else
          # 신규 매물 생성
          property = create_new_property_with_relations(property_data)
          saved_properties << property.attributes if property
        end

      rescue => e
        Rails.logger.error "매물 저장 실패: #{e.message}"
        Rails.logger.error "매물 데이터: #{property_data.inspect}"
        next
      end
    end

    Rails.logger.info "📊 총 #{raw_properties.size}개 중 #{saved_properties.size}개 매물 저장 완료"
    saved_properties
  end

  def create_new_property_with_relations(property_data)
    Property.transaction do
      # Property 생성
      property = Property.create!(property_data[:property])

      # Address 생성
      if property_data[:address].present?
        property.create_address!(property_data[:address])
      end

      # PropertyImage 생성
      if property_data[:property_image].present?
        property.create_property_image!(property_data[:property_image])
      end

      # ApartmentDetail 생성 (아파트인 경우에만)
      if property_data[:apartment_detail].present?
        property.create_apartment_detail!(property_data[:apartment_detail])
      end

      property
    end
  end

  def update_existing_property(existing, property_data)
    Property.transaction do
      # Property 업데이트
      existing.update!(property_data[:property].except(:external_id))

      # Address 업데이트 또는 생성
      if property_data[:address].present?
        if existing.address
          existing.address.update!(property_data[:address])
        else
          existing.create_address!(property_data[:address])
        end
      end

      # PropertyImage 업데이트 또는 생성
      if property_data[:property_image].present?
        if existing.property_image
          existing.property_image.update!(property_data[:property_image])
        else
          existing.create_property_image!(property_data[:property_image])
        end
      end

      # ApartmentDetail 업데이트 또는 생성 (아파트인 경우에만)
      if property_data[:apartment_detail].present?
        if existing.apartment_detail
          existing.apartment_detail.update!(property_data[:apartment_detail])
        else
          existing.create_apartment_detail!(property_data[:apartment_detail])
        end
      end
    end
  end

  def get_sample_properties(saved_properties, limit = 3)
    return [] if saved_properties.empty?

    # 저장된 매물 중에서 샘플을 가져옴
    property_ids = saved_properties.first(limit).map { |p| p['id'] }
    Property.includes(:address, :property_image, :apartment_detail)
            .where(id: property_ids)
            .map do |property|
      {
        id: property.id,
        title: property.title,
        address_text: property.address_text,
        price: property.price,
        property_type: property.property_type,
        deal_type: property.deal_type,
        area_sqm: property.area_sqm,
        current_floor: property.current_floor,
        total_floors: property.total_floors,
        room_structure: property.room_structure,
        maintenance_fee: property.maintenance_fee,
        source: property.source,
        external_id: property.external_id
      }
    end
  end
end