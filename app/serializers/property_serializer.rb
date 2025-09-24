class PropertySerializer
  def initialize(property)
    @property = property
  end

  def to_h
    {
      id: @property.id,
      address: @property.address,
      sales_type: @property.sales_type,
      deposit: @property.deposit,
      rent: @property.rent,
      service_type: @property.service_type,
      floor: @property.floor,
      total_floor: @property.total_floor,
      room_type: @property.room_type,
      maintenance_fee: @property.maintenance_fee,
      thumbnail_url: @property.thumbnail_url,
      external_id: @property.external_id,
      latitude: @property.latitude,
      longitude: @property.longitude,
      geohash: @property.geohash
    }
  end
end