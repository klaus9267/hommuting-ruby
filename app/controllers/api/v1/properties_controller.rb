class Api::V1::PropertiesController < ApplicationController
  def map
    begin
      # 지도 경계 파라미터 검증 (직방 API 형식)
      bounds = {
        'ne_lat' => params[:latNorth],
        'ne_lng' => params[:lngEast],
        'sw_lat' => params[:latSouth],
        'sw_lng' => params[:lngWest]
      }
      validate_bounds_params(bounds)

      # 필터 조건 구성
      properties = build_filtered_query

      # 응답 데이터 구성
      result = {
        properties: serialize_properties(properties),
        total_count: properties.count,
        filters_applied: applied_filters_summary,
        bounds: bounds
      }

      render json: result
    rescue => e
      Rails.logger.error "지도 매물 조회 오류: #{e.message}"
      render json: { error: '매물 조회 중 오류가 발생했습니다', message: e.message }, status: 500
    end
  end

  def room_types
    render json: {
      room_types: Property.room_type_options
    }
  end

  private

  def validate_bounds_params(bounds)
    required_params = %w[ne_lat ne_lng sw_lat sw_lng]
    missing_params = required_params.select { |param| bounds[param].blank? }

    if missing_params.any?
      raise ArgumentError, "필수 지도 경계 파라미터가 누락되었습니다: #{missing_params.join(', ')}"
    end

    # 좌표 유효성 검증
    ne_lat, ne_lng = bounds['ne_lat'].to_f, bounds['ne_lng'].to_f
    sw_lat, sw_lng = bounds['sw_lat'].to_f, bounds['sw_lng'].to_f

    if ne_lat <= sw_lat || ne_lng <= sw_lng
      raise ArgumentError, "잘못된 지도 경계 좌표입니다"
    end
  end

  def build_filtered_query
    properties = Property.includes(:apartment_detail)

    # 지도 경계 내 매물 필터링 (PostGIS 사용) - 직방 API 형식
    if params[:latNorth].present? && params[:lngEast].present? && params[:latSouth].present? && params[:lngWest].present?
      properties = properties.in_bounds(
        params[:latNorth].to_f,   # ne_lat
        params[:lngEast].to_f,    # ne_lng
        params[:latSouth].to_f,   # sw_lat
        params[:lngWest].to_f     # sw_lng
      )
    end

    # 매물 유형 필터링
    if params[:service_types].present?
      service_types = Array(params[:service_types])
      properties = properties.where(service_type: service_types)
    end

    # 거래 유형 필터링
    if params[:sales_types].present?
      sales_types = Array(params[:sales_types])
      properties = properties.where(sales_type: sales_types)
    end

    # 방 구조 필터링
    if params[:room_types].present?
      room_types = Array(params[:room_types])
      properties = properties.where(room_type: room_types)
    end

    # 보증금 범위 필터링
    if params[:deposit_min].present? || params[:deposit_max].present?
      deposit_min = params[:deposit_min]&.to_i
      deposit_max = params[:deposit_max]&.to_i

      properties = properties.where(deposit: deposit_min..) if deposit_min
      properties = properties.where(deposit: ..deposit_max) if deposit_max
    end

    # 월세 범위 필터링
    if params[:rent_min].present? || params[:rent_max].present?
      rent_min = params[:rent_min]&.to_i
      rent_max = params[:rent_max]&.to_i

      properties = properties.where(rent: rent_min..) if rent_min
      properties = properties.where(rent: ..rent_max) if rent_max
    end

    # 관리비 범위 필터링
    if params[:maintenance_fee_max].present?
      properties = properties.where(maintenance_fee: ..params[:maintenance_fee_max].to_i)
    end

    # 페이지네이션
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 15, 15].min # 최대 15개 제한

    properties.offset((page - 1) * per_page).limit(per_page)
  end

  def serialize_properties(properties)
    properties.map do |property|
      {
        id: property.id,
        address: property.address,
        sales_type: property.sales_type,
        deposit: property.deposit,
        rent: property.rent,
        service_type: property.service_type,
        room_type: property.room_type,
        room_type_name: property.room_type_name,
        floor: property.floor,
        total_floor: property.total_floor,
        maintenance_fee: property.maintenance_fee,
        thumbnail_url: property.thumbnail_url,
        latitude: property.latitude,
        longitude: property.longitude,
        geohash: property.geohash,
        price_info: property.price_info,
        floor_info: property.floor_info,
        created_at: property.created_at
      }
    end
  end

  def applied_filters_summary
    {
      service_types: params[:service_types],
      sales_types: params[:sales_types],
      room_types: params[:room_types],
      deposit_range: [params[:deposit_min], params[:deposit_max]].compact,
      rent_range: [params[:rent_min], params[:rent_max]].compact,
      maintenance_fee_max: params[:maintenance_fee_max]
    }.compact
  end
end