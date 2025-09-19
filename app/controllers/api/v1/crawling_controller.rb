class Api::V1::CrawlingController < ApplicationController
  # POST /api/v1/crawling/seoul
  def seoul
    begin
      result = CrawlingService.collect_seoul_properties

      render json: {
        status: 'success',
        message: '서울 매물 수집을 시작했습니다',
        collected_count: result[:count],
        areas: result[:areas],
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
      result = CrawlingService.collect_gyeonggi_properties

      render json: {
        status: 'success',
        message: '경기도 매물 수집을 시작했습니다',
        collected_count: result[:count],
        areas: result[:areas],
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
      seoul_result = CrawlingService.collect_seoul_properties
      gyeonggi_result = CrawlingService.collect_gyeonggi_properties

      total_count = seoul_result[:count] + gyeonggi_result[:count]
      all_areas = seoul_result[:areas] + gyeonggi_result[:areas]

      render json: {
        status: 'success',
        message: '서울 및 경기도 매물 수집을 시작했습니다',
        collected_count: total_count,
        areas: all_areas,
        breakdown: {
          seoul: seoul_result,
          gyeonggi: gyeonggi_result
        },
        timestamp: Time.current
      }
    rescue => e
      render json: {
        status: 'error',
        message: '매물 수집 중 오류가 발생했습니다',
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