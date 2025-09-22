class Api::V1::PropertiesController < ApplicationController
  before_action :set_property, only: [:show]
  
  # GET /api/v1/properties
  def index
    @properties = Property.all
    
    # 필터링
    @properties = @properties.by_property_type(params[:property_type]) if params[:property_type].present?
    @properties = @properties.by_deal_type(params[:deal_type]) if params[:deal_type].present?
    @properties = @properties.by_source(params[:source]) if params[:source].present?
    
    # 지역 필터링
    if params[:lat_min] && params[:lat_max] && params[:lng_min] && params[:lng_max]
      @properties = @properties.in_area(
        params[:lat_min].to_f,
        params[:lat_max].to_f,
        params[:lng_min].to_f,
        params[:lng_max].to_f
      )
    end
    
    # 페이지네이션
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min
    
    @properties = @properties.offset((page - 1) * per_page).limit(per_page)
    
    render json: {
      properties: @properties.map { |property| property_json(property) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: Property.count
      }
    }
  end
  
  # GET /api/v1/properties/:id
  def show
    render json: {
      property: property_detail_json(@property)
    }
  end
  
  # GET /api/v1/properties/search
  def search
    query = params[:q]
    
    if query.blank?
      return render json: { error: "Search query is required" }, status: :bad_request
    end
    
    @properties = Property.where(
      "title LIKE ? OR address_text LIKE ? OR description LIKE ?",
      "%#{query}%", "%#{query}%", "%#{query}%"
    )
    
    # 추가 필터링 적용
    @properties = @properties.by_property_type(params[:property_type]) if params[:property_type].present?
    @properties = @properties.by_deal_type(params[:deal_type]) if params[:deal_type].present?
    
    # 페이지네이션
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 50].min
    
    @properties = @properties.offset((page - 1) * per_page).limit(per_page)
    
    render json: {
      query: query,
      properties: @properties.map { |property| property_json(property) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: @properties.count
      }
    }
  end
  
  # GET /api/v1/properties/stats
  def stats
    render json: {
      total_properties: Property.count,
      by_property_type: Property.group(:property_type).count,
      by_deal_type: Property.group(:deal_type).count,
      by_source: Property.group(:source).count,
      recent_properties: Property.order(created_at: :desc).limit(5).map { |p| 
        {
          id: p.id,
          title: p.title,
          property_type: p.property_type,
          deal_type: p.deal_type,
          created_at: p.created_at
        }
      }
    }
  end
  
  # GET /api/v1/properties/by_area
  def by_area
    unless params[:lat] && params[:lng]
      return render json: { error: "Latitude and longitude are required" }, status: :bad_request
    end
    
    lat = params[:lat].to_f
    lng = params[:lng].to_f
    radius = params[:radius]&.to_f || 0.01 # 기본 반경 약 1km
    
    @properties = Property.in_area(
      lat - radius,
      lat + radius,
      lng - radius,
      lng + radius
    )
    
    # 추가 필터링
    @properties = @properties.by_property_type(params[:property_type]) if params[:property_type].present?
    @properties = @properties.by_deal_type(params[:deal_type]) if params[:deal_type].present?
    
    render json: {
      center: { lat: lat, lng: lng },
      radius: radius,
      properties: @properties.map { |property| property_json(property) },
      count: @properties.count
    }
  end
  
  private
  
  def set_property
    @property = Property.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Property not found" }, status: :not_found
  end
  
  def property_json(property)
    {
      id: property.id,
      title: property.title,
      address_text: property.address_text,
      price: property.price,
      price_info: property.price_info,
      property_type: property.property_type,
      deal_type: property.deal_type,
      area: property.area,
      floor: property.floor,
      area_description: property.area_description,
      area_sqm: property.area_sqm,
      floor_description: property.floor_description,
      current_floor: property.current_floor,
      total_floors: property.total_floors,
      room_structure: property.room_structure,
      maintenance_fee: property.maintenance_fee,
      coordinate: property.coordinate,
      latitude: property.latitude,
      longitude: property.longitude,
      source: property.source,
      created_at: property.created_at,
      updated_at: property.updated_at
    }
  end
  
  def property_detail_json(property)
    # 관련 데이터를 함께 로드
    property_with_relations = Property.includes(:address, :property_image, :apartment_detail).find(property.id)

    property_json(property_with_relations).merge({
      description: property_with_relations.description,
      external_id: property_with_relations.external_id,
      raw_data: property_with_relations.raw_data,
      address: property_with_relations.address&.as_json(except: [:created_at, :updated_at]),
      property_image: property_with_relations.property_image&.as_json(except: [:created_at, :updated_at]),
      apartment_detail: property_with_relations.apartment_detail&.as_json(except: [:created_at, :updated_at])
    })
  end
end
