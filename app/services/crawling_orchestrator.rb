class CrawlingOrchestrator
  def initialize
    @api_client = ZigbangApiClient.new
    @transformer = PropertyDataTransformer.new
    @persister = PropertyPersister.new
  end

  def execute_region_crawling(region, options = {})
    Rails.logger.info "🚀 #{region_name(region)} 지역 geohash 기반 크롤링 시작"

    if options[:dev_mode]
      execute_dev_mode_crawling(region, options)
    else
      execute_full_mode_crawling(region, options)
    end
  end

  def execute_multi_region_crawling(options = {})
    Rails.logger.info "🚀 서울+경기도 전체 geohash 기반 크롤링 시작"

    if options[:dev_mode]
      seoul_result = execute_dev_mode_crawling(:seoul, options.merge(test_geohashes: ['wydm3', 'wydm7']))
      sleep(10)
      gyeonggi_result = execute_dev_mode_crawling(:gyeonggi, options.merge(test_geohashes: ['wydf3', 'wydk7']))
    else
      seoul_result = execute_full_mode_crawling(:seoul, options)
      sleep(10)
      gyeonggi_result = execute_full_mode_crawling(:gyeonggi, options)
    end

    CrawlingResult.new(
      total_collected: seoul_result.collected_count + gyeonggi_result.collected_count,
      breakdown: {
        seoul: seoul_result,
        gyeonggi: gyeonggi_result
      },
      dev_mode: options[:dev_mode],
      timestamp: Time.current
    )
  end

  private

  def execute_dev_mode_crawling(region, options)
    Rails.logger.info "🏠 개발 모드: 제한된 geohash만 테스트"

    test_geohashes = options[:test_geohashes] || default_test_geohashes(region)
    raw_properties = crawl_specific_geohashes(test_geohashes, options[:property_types])
    saved_properties = @persister.save_properties_batch(raw_properties)

    build_dev_mode_result(region, saved_properties, test_geohashes.size, options[:dev_mode])
  end

  def execute_full_mode_crawling(region, options)
    Rails.logger.info "🏠 전체 모드: #{region_name(region)} 전체 geohash 크롤링"

    result = @api_client.crawl_region_by_geohash(region, options[:property_types])
    recent_properties = Property.order(created_at: :desc).limit(3)

    build_full_mode_result(region, result, recent_properties, options[:dev_mode])
  end

  def crawl_specific_geohashes(geohashes, property_types)
    Rails.logger.info "🗺️ 특정 geohash 크롤링: #{geohashes.inspect}"

    all_transformed_properties = []

    geohashes.each do |geohash|
      property_ids = @api_client.collect_property_ids_by_geohash(geohash, property_types)

      if property_ids.any?
        raw_properties = @api_client.fetch_property_details(property_ids)
        transformed_properties = @transformer.transform_batch_with_geohash(raw_properties, geohash)
        all_transformed_properties.concat(transformed_properties)
      end

      sleep(rand(2..5))
    end

    Rails.logger.info "🔍 변환 완료: 총 #{all_transformed_properties.size}개"
    all_transformed_properties
  end

  def build_dev_mode_result(region, saved_properties, geohash_count, dev_mode)
    CrawlingResult.new(
      status: 'success',
      message: "#{region_name(region)} 테스트 geohash 매물 수집 완료",
      collected_count: saved_properties.size,
      property_types: saved_properties.group_by { |p| p['property_type'] }.transform_values(&:count),
      sample_properties: get_sample_properties(saved_properties, 3),
      geohash_count: geohash_count,
      dev_mode: dev_mode,
      timestamp: Time.current
    )
  end

  def build_full_mode_result(region, crawler_result, recent_properties, dev_mode)
    CrawlingResult.new(
      status: 'success',
      message: "#{region_name(region)} 전체 매물 수집 완료",
      collected_count: crawler_result[:total_saved],
      successful_geohashes: crawler_result[:successful_geohashes],
      failed_geohashes: crawler_result[:failed_geohashes].size,
      property_types: recent_properties.group_by(&:property_type).transform_values(&:count),
      sample_properties: format_sample_properties(recent_properties),
      geohash_count: geohash_count_for_region(region),
      dev_mode: dev_mode,
      timestamp: Time.current
    )
  end

  def default_test_geohashes(region)
    case region
    when :seoul
      ['wydm5']
    when :gyeonggi
      ['wydf3', 'wydk7', 'wydh5']
    end
  end

  def region_name(region)
    case region
    when :seoul
      '서울'
    when :gyeonggi
      '경기도'
    end
  end

  def geohash_count_for_region(region)
    case region
    when :seoul
      KoreaGeohash.seoul_geohashes.size
    when :gyeonggi
      KoreaGeohash.gyeonggi_geohashes.size
    end
  end

  def get_sample_properties(saved_properties, limit = 3)
    return [] if saved_properties.empty?

    property_ids = saved_properties.first(limit).map { |p| p['id'] }
    Property.includes(:apartment_detail)
            .where(id: property_ids)
            .map { |property| PropertySerializer.new(property).to_h }
  end

  def format_sample_properties(properties)
    properties.map { |property| PropertySerializer.new(property).to_h }
  end
end