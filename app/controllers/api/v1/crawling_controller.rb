class Api::V1::CrawlingController < ApplicationController
  # POST /api/v1/crawling/suji
  def suji
    begin
      result = ZigbangTorCrawler.collect_all_properties('수지구')

      render json: {
        status: 'success',
        message: '수지구 매물 수집을 완료했습니다',
        collected_count: result.size,
        timestamp: Time.current
      }
    rescue => e
      render json: {
        status: 'error',
        message: '수지구 매물 수집 중 오류가 발생했습니다',
        error: e.message
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/crawling/zigbang
  def zigbang
    begin
      result = ZigbangTorCrawler.collect_all_properties('수지구')

      render json: {
        status: 'success',
        message: '직방 매물 수집을 완료했습니다',
        collected_count: result.size,
        property_types: result.group_by(&:property_type).transform_values(&:count),
        timestamp: Time.current
      }
    rescue => e
      render json: {
        status: 'error',
        message: '직방 매물 수집 중 오류가 발생했습니다',
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