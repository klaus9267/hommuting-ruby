class CrawlingResult
  attr_accessor :status, :message, :collected_count, :successful_geohashes,
                :failed_geohashes, :property_types, :sample_properties,
                :geohash_count, :dev_mode, :timestamp, :total_collected,
                :breakdown

  def initialize(attributes = {})
    attributes.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end
  end

  def to_h
    {
      status: status || 'success',
      message: message,
      collected_count: collected_count,
      successful_geohashes: successful_geohashes,
      failed_geohashes: failed_geohashes,
      property_types: property_types,
      sample_properties: sample_properties,
      geohash_count: geohash_count,
      dev_mode: dev_mode,
      timestamp: timestamp,
      total_collected: total_collected,
      breakdown: breakdown
    }.compact
  end

  def success?
    status == 'success'
  end

  def has_failures?
    failed_geohashes.present? && failed_geohashes > 0
  end
end