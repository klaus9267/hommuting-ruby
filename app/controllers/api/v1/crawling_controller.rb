class Api::V1::CrawlingController < ApplicationController
  # POST /api/v1/crawling/seoul
  def seoul
    begin
      dev_mode = params[:dev_mode] == 'true'
      result = MultiRegionCrawler.crawl_seoul_properties(dev_mode: dev_mode)

      render json: {
        status: 'success',
        message: dev_mode ? '서울 테스트 지역 매물 수집을 완료했습니다' : '서울 전체 매물 수집을 완료했습니다',
        collected_count: result.size,
        property_types: result.group_by(&:property_type).transform_values(&:count),
        areas_completed: dev_mode ? MultiRegionCrawler::DEV_SEOUL.size : MultiRegionCrawler::SEOUL_DISTRICTS.size,
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
      result = MultiRegionCrawler.crawl_gyeonggi_properties(dev_mode: dev_mode)

      render json: {
        status: 'success',
        message: dev_mode ? '경기도 테스트 지역 매물 수집을 완료했습니다' : '경기도 전체 매물 수집을 완료했습니다',
        collected_count: result.size,
        property_types: result.group_by(&:property_type).transform_values(&:count),
        areas_completed: dev_mode ? MultiRegionCrawler::DEV_GYEONGGI.size : MultiRegionCrawler::GYEONGGI_CITIES.size,
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

      seoul_result = MultiRegionCrawler.crawl_seoul_properties(dev_mode: dev_mode)
      sleep(10) # 지역간 대기
      gyeonggi_result = MultiRegionCrawler.crawl_gyeonggi_properties(dev_mode: dev_mode)

      total_count = seoul_result.size + gyeonggi_result.size

      render json: {
        status: 'success',
        message: dev_mode ? '서울 및 경기도 테스트 지역 매물 수집을 완료했습니다' : '서울 및 경기도 전체 매물 수집을 완료했습니다',
        total_collected: total_count,
        breakdown: {
          seoul: {
            count: seoul_result.size,
            areas: dev_mode ? MultiRegionCrawler::DEV_SEOUL.size : MultiRegionCrawler::SEOUL_DISTRICTS.size,
            property_types: seoul_result.group_by(&:property_type).transform_values(&:count)
          },
          gyeonggi: {
            count: gyeonggi_result.size,
            areas: dev_mode ? MultiRegionCrawler::DEV_GYEONGGI.size : MultiRegionCrawler::GYEONGGI_CITIES.size,
            property_types: gyeonggi_result.group_by(&:property_type).transform_values(&:count)
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
end