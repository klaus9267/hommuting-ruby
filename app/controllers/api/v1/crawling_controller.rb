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
      ['oneroom', 'villa', 'officetel']
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