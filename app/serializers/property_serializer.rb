class PropertySerializer
  def initialize(property)
    @property = property
  end

  def to_h
    {
      id: @property.id,
      title: @property.title,
      address_text: @property.address_text,
      price: @property.price,
      property_type: @property.property_type,
      deal_type: @property.deal_type,
      area_sqm: @property.area_sqm,
      current_floor: @property.current_floor,
      total_floors: @property.total_floors,
      room_structure: @property.room_structure,
      maintenance_fee: @property.maintenance_fee,
      thumbnail_url: @property.thumbnail_url,
      source: @property.source,
      external_id: @property.external_id
    }
  end
end