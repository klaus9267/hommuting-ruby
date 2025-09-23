class PropertyPersister
  def save_properties_batch(property_data_array)
    return [] if property_data_array.empty?

    saved_properties = []

    property_data_array.each do |property_data|
      begin
        next if property_data.nil?

        saved_property = save_single_property(property_data)
        saved_properties << saved_property.attributes if saved_property
      rescue => e
        Rails.logger.error "매물 저장 실패: #{e.message}"
        Rails.logger.error "매물 데이터: #{property_data.inspect}"
        next
      end
    end

    Rails.logger.info "📊 총 #{property_data_array.size}개 중 #{saved_properties.size}개 매물 저장 완료"
    saved_properties
  end

  def save_geohash_properties(geohash, property_data_array)
    return 0 if property_data_array.empty?

    saved_count = 0

    Property.transaction do
      property_data_array.each do |property_data|
        begin
          next if property_data.nil?

          saved_property = save_single_property(property_data)
          saved_count += 1 if saved_property
        rescue => e
          Rails.logger.error "#{geohash} 매물 저장 실패: #{e.message}"
          next
        end
      end
    end

    Rails.logger.info "🏠 #{geohash}: #{saved_count}개 매물 저장 완료"
    saved_count
  end

  private

  def save_single_property(property_data)
    external_id = property_data[:property][:external_id]
    existing = Property.find_by(external_id: external_id)

    if existing
      update_existing_property(existing, property_data)
      existing.reload
    else
      create_new_property(property_data)
    end
  end

  def create_new_property(property_data)
    Property.transaction do
      property = Property.create!(property_data[:property])

      create_address_if_present(property, property_data[:address])
      create_apartment_detail_if_present(property, property_data[:apartment_detail])

      property
    end
  end

  def update_existing_property(existing_property, property_data)
    Property.transaction do
      existing_property.update!(property_data[:property].except(:external_id))

      update_or_create_address(existing_property, property_data[:address])
      update_or_create_apartment_detail(existing_property, property_data[:apartment_detail])
    end
  end

  def create_address_if_present(property, address_data)
    return unless address_data.present?

    property.create_address!(address_data)
  end

  def create_apartment_detail_if_present(property, apartment_detail_data)
    return unless apartment_detail_data.present?

    property.create_apartment_detail!(apartment_detail_data)
  end

  def update_or_create_address(property, address_data)
    return unless address_data.present?

    if property.address
      property.address.update!(address_data)
    else
      property.create_address!(address_data)
    end
  end

  def update_or_create_apartment_detail(property, apartment_detail_data)
    return unless apartment_detail_data.present?

    if property.apartment_detail
      property.apartment_detail.update!(apartment_detail_data)
    else
      property.create_apartment_detail!(apartment_detail_data)
    end
  end
end