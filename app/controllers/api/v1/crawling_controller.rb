class Api::V1::CrawlingController < ApplicationController
  # POST /api/v1/crawling/seoul
  def seoul
    begin
      result = CrawlingOrchestrator.new.execute_region_crawling(:seoul, crawling_params)
      render json: result.to_h
    rescue => e
      Rails.logger.error "❌ 서울 크롤링 오류: #{e.message}"
      render_error('서울 매물 수집 중 오류가 발생했습니다', e.message)
    end
  end

  # POST /api/v1/crawling/gyeonggi
  def gyeonggi
    begin
      result = CrawlingOrchestrator.new.execute_region_crawling(:gyeonggi, crawling_params)
      render json: result.to_h
    rescue => e
      Rails.logger.error "❌ 경기도 크롤링 오류: #{e.message}"
      render_error('경기도 매물 수집 중 오류가 발생했습니다', e.message)
    end
  end

  # POST /api/v1/crawling/all
  def all
    begin
      result = CrawlingOrchestrator.new.execute_multi_region_crawling(crawling_params)
      render json: result.to_h
    rescue => e
      Rails.logger.error "❌ 전체 크롤링 오류: #{e.message}"
      render_error('전체 매물 수집 중 오류가 발생했습니다', e.message)
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

  def crawling_params
    {
      dev_mode: params[:dev_mode] == 'true',
      property_types: process_property_types(params[:property_types])
    }
  end

  def process_property_types(params_property_types)
    if params_property_types.present?
      params_property_types.is_a?(Array) ? params_property_types : [params_property_types]
    else
      ['oneroom']
    end
  end

  def render_error(message, error_detail)
    render json: {
      status: 'error',
      message: message,
      error: error_detail
    }, status: :internal_server_error
  end
end