class PropertyPersister
  def save_properties_batch(property_data_array)
    return [] if property_data_array.empty?

    saved_properties = []

    property_data_array.each do |property_data|
      begin
        next if property_data.nil?

        created_property = create_new_property(property_data)
        saved_properties << created_property.attributes if created_property
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
      # 1. 해당 geohash의 기존 매물 모두 삭제
      deleted_count = Property.where(geohash: geohash).delete_all
      Rails.logger.info "🗑️ #{geohash}: 기존 #{deleted_count}개 매물 삭제"

      # 2. 새로운 매물 모두 생성
      property_data_array.each do |property_data|
        begin
          next if property_data.nil?

          created_property = create_new_property(property_data)
          saved_count += 1 if created_property
        rescue => e
          Rails.logger.error "#{geohash} 매물 생성 실패: #{e.message}"
          Rails.logger.error "매물 데이터: #{property_data.inspect}"
          next
        end
      end
    end

    Rails.logger.info "🏠 #{geohash}: #{saved_count}개 매물 저장 완료"
    saved_count
  end

  private


  def create_new_property(property_data)
    Property.transaction do
      property = Property.create!(property_data[:property])

      create_apartment_detail_if_present(property, property_data[:apartment_detail])

      property
    end
  end



  def create_apartment_detail_if_present(property, apartment_detail_data)
    return unless apartment_detail_data.present?

    property.create_apartment_detail!(apartment_detail_data)
  end

end