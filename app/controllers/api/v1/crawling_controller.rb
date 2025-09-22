class Api::V1::CrawlingController < ApplicationController
  # POST /api/v1/crawling/seoul
  def seoul
    begin
      Rails.logger.info "🚀 서울 크롤링 시작"

      dev_mode = params[:dev_mode] == 'true'
      Rails.logger.info "📋 개발 모드: #{dev_mode}"
      Rails.logger.info "📋 원본 params[:property_types]: #{params[:property_types].inspect}"

      # property_types 파라미터 처리 (배열 형태로 확실하게 변환)
      property_types = if params[:property_types].present?
        params[:property_types].is_a?(Array) ? params[:property_types] : [params[:property_types]]
      else
        ['villa', 'oneroom', 'officetel']
      end
      Rails.logger.info "📋 처리된 property_types: #{property_types.inspect}"

      crawler = ZigbangApiCrawler.new
      Rails.logger.info "🔧 크롤러 초기화 완료"

      if dev_mode
        Rails.logger.info "🏠 개발 모드: 강남구, 서초구 테스트 시작"
        # 개발 모드: 강남구, 서초구만 테스트
        test_districts = ['강남구', '서초구']
        raw_properties = []

        test_districts.each do |district|
          Rails.logger.info "🏠 #{district} 크롤링 시작"
          district_properties = crawler.crawl_specific_district(:seoul, district, property_types)
          Rails.logger.info "🏠 #{district} 크롤링 완료: #{district_properties.size}개"
          raw_properties.concat(district_properties)
        end
      else
        Rails.logger.info "🏠 전체 모드: 서울 25개 구 크롤링 시작"
        # 전체 모드: 서울 25개 구 전체
        raw_properties = crawler.crawl_all_seoul_districts(property_types)
      end

      Rails.logger.info "📊 총 수집된 매물: #{raw_properties.size}개"
      # DB 저장
      Rails.logger.info "💾 DB 저장 시작"
      saved_properties = save_properties_to_db(raw_properties)
      Rails.logger.info "💾 DB 저장 완료: #{saved_properties.size}개"

      render json: {
        status: 'success',
        message: dev_mode ? '서울 테스트 지역 매물 수집을 완료했습니다' : '서울 전체 매물 수집을 완료했습니다',
        collected_count: saved_properties.size,
        property_types: saved_properties.group_by { |p| p['property_type'] }.transform_values(&:count),
        sample_properties: get_sample_properties(saved_properties, 3),
        areas_completed: dev_mode ? 2 : 25,
        dev_mode: dev_mode,
        timestamp: Time.current
      }
    rescue => e
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
      dev_mode = params[:dev_mode] == 'true'

      # property_types 파라미터 처리 (배열 형태로 확실하게 변환)
      property_types = if params[:property_types].present?
        params[:property_types].is_a?(Array) ? params[:property_types] : [params[:property_types]]
      else
        ['villa', 'oneroom', 'officetel']
      end

      crawler = ZigbangApiCrawler.new

      if dev_mode
        # 개발 모드: 수원시 영통구, 성남시 분당구만 테스트
        test_districts = ['수원시 영통구', '성남시 분당구']
        raw_properties = []

        test_districts.each do |district|
          district_properties = crawler.crawl_specific_district(:gyeonggi, district, property_types)
          raw_properties.concat(district_properties)
        end
      else
        # 전체 모드: 경기도 48개 시/구 전체
        raw_properties = crawler.crawl_all_gyeonggi_districts(property_types)
      end

      # DB 저장
      saved_properties = save_properties_to_db(raw_properties)

      render json: {
        status: 'success',
        message: dev_mode ? '경기도 테스트 지역 매물 수집을 완료했습니다' : '경기도 전체 매물 수집을 완료했습니다',
        collected_count: saved_properties.size,
        property_types: saved_properties.group_by { |p| p['property_type'] }.transform_values(&:count),
        sample_properties: get_sample_properties(saved_properties, 3),
        areas_completed: dev_mode ? 2 : KoreaRegions.districts_for_region(:gyeonggi).size,
        dev_mode: dev_mode,
        timestamp: Time.current
      }
    rescue => e
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
      dev_mode = params[:dev_mode] == 'true'

      # property_types 파라미터 처리 (배열 형태로 확실하게 변환)
      property_types = if params[:property_types].present?
        params[:property_types].is_a?(Array) ? params[:property_types] : [params[:property_types]]
      else
        ['villa', 'oneroom', 'officetel']
      end

      crawler = ZigbangApiCrawler.new

      # 서울 크롤링
      if dev_mode
        seoul_districts = ['강남구', '서초구']
        seoul_properties = []
        seoul_districts.each do |district|
          seoul_properties.concat(crawler.crawl_specific_district(:seoul, district, property_types))
        end
      else
        seoul_properties = crawler.crawl_all_seoul_districts(property_types)
      end

      sleep(10) # 지역간 대기

      # 경기도 크롤링
      if dev_mode
        gyeonggi_districts = ['수원시 영통구', '성남시 분당구']
        gyeonggi_properties = []
        gyeonggi_districts.each do |district|
          gyeonggi_properties.concat(crawler.crawl_specific_district(:gyeonggi, district, property_types))
        end
      else
        gyeonggi_properties = crawler.crawl_all_gyeonggi_districts(property_types)
      end

      # DB 저장
      seoul_saved = save_properties_to_db(seoul_properties)
      gyeonggi_saved = save_properties_to_db(gyeonggi_properties)

      total_count = seoul_saved.size + gyeonggi_saved.size

      render json: {
        status: 'success',
        message: dev_mode ? '서울 및 경기도 테스트 지역 매물 수집을 완료했습니다' : '서울 및 경기도 전체 매물 수집을 완료했습니다',
        total_collected: total_count,
        breakdown: {
          seoul: {
            count: seoul_saved.size,
            areas: dev_mode ? 2 : 25,
            property_types: seoul_saved.group_by { |p| p['property_type'] }.transform_values(&:count),
            sample_properties: get_sample_properties(seoul_saved, 2)
          },
          gyeonggi: {
            count: gyeonggi_saved.size,
            areas: dev_mode ? 2 : KoreaRegions.districts_for_region(:gyeonggi).size,
            property_types: gyeonggi_saved.group_by { |p| p['property_type'] }.transform_values(&:count),
            sample_properties: get_sample_properties(gyeonggi_saved, 2)
          }
        },
        dev_mode: dev_mode,
        timestamp: Time.current
      }
    rescue => e
      render json: {
        status: 'error',
        message: '전체 매물 수집 중 오류가 발생했습니다',
        error: e.message
      }, status: :internal_server_error
    end
  end

  # GET /api/v1/crawling/status
  def status
    render json: {
      total_properties: Property.count,
      seoul_properties: Property.where("address LIKE '%서울%'").count,
      gyeonggi_properties: Property.where("address LIKE '%경기%'").count,
      by_property_type: Property.group(:property_type).count,
      by_deal_type: Property.group(:deal_type).count,
      last_updated: Property.maximum(:updated_at),
      recent_properties: Property.order(created_at: :desc).limit(10).select(:id, :title, :address, :property_type, :deal_type, :created_at)
    }
  end

  private

  def save_properties_to_db(raw_properties)
    return [] if raw_properties.empty?

    saved_properties = []

    raw_properties.each do |property_data|
      begin
        next if property_data.nil?

        # 중복 체크 (external_id 기준)
        existing = Property.find_by(external_id: property_data[:property][:external_id])

        if existing
          # 기존 매물 및 관련 데이터 업데이트
          update_existing_property(existing, property_data)
          saved_properties << existing.reload.attributes
        else
          # 신규 매물 및 관련 데이터 생성
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

    # 저장된 매물 중에서 샘플을 가져옴 (ID 기반으로 실제 Property 객체 조회)
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
        address: property.address&.as_json(except: [:created_at, :updated_at]),
        property_image: property.property_image&.as_json(except: [:created_at, :updated_at]),
        apartment_detail: property.apartment_detail&.as_json(except: [:created_at, :updated_at])
      }
    end
  end
end