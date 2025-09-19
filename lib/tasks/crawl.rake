namespace :crawl do
  desc "Crawl Zigbang properties for Seoul districts"
  task zigbang: :environment do
    puts "🚀 Starting Zigbang crawl task..."
    
    crawler = ZigbangCrawlerService.new
    results = crawler.run_comprehensive_crawl
    
    if results[:success]
      puts "✅ Crawl completed successfully!"
      puts "📊 Properties crawled: #{results[:properties_count]}"
      puts "⏱️  Duration: #{results[:duration]} seconds"
      
      if results[:errors].any?
        puts "⚠️  #{results[:errors].length} errors encountered"
      end
    else
      puts "❌ Crawl failed: #{results[:error]}"
      puts "📊 Partial results: #{results[:properties_count]} properties"
    end
  end
  
  desc "Test Zigbang crawler with single district"
  task test_zigbang: :environment do
    puts "🧪 Testing Zigbang crawler with Gangnam district..."
    
    crawler = ZigbangCrawlerService.new
    crawler.get_session_cookie
    
    # 강남구만 테스트
    count = crawler.crawl_district('강남구', { lat: 37.4979, lng: 127.0276 })
    
    puts "📊 Test results: #{count} properties found"
    puts "💾 Database count: #{Property.count} total properties"
    
    if Property.any?
      puts "\n🏠 Sample properties:"
      Property.last(3).each do |prop|
        puts "   - #{prop.title} (#{prop.property_type}) - #{prop.price_info}"
      end
    end
  end
  
  desc "Show crawling statistics"
  task stats: :environment do
    puts "📊 Zigbang Crawling Statistics"
    puts "="*40
    
    total = Property.count
    puts "Total properties: #{total}"
    
    if total > 0
      puts "\nBy source:"
      Property.group(:source).count.each do |source, count|
        puts "  #{source}: #{count}"
      end
      
      puts "\nBy property type:"
      Property.group(:property_type).count.each do |type, count|
        puts "  #{type}: #{count}"
      end
      
      puts "\nBy deal type:"
      Property.group(:deal_type).count.each do |deal, count|
        puts "  #{deal}: #{count}"
      end
      
      puts "\nRecent properties:"
      Property.order(created_at: :desc).limit(5).each do |prop|
        puts "  #{prop.created_at.strftime('%Y-%m-%d %H:%M')} - #{prop.title}"
      end
    end
  end
  
  desc "Clean up duplicate properties"
  task cleanup: :environment do
    puts "🧹 Cleaning up duplicate properties..."
    
    initial_count = Property.count
    
    # external_id와 source가 같은 중복 제거
    duplicates = Property.group(:external_id, :source).having('count(*) > 1')
    
    removed_count = 0
    duplicates.each do |duplicate_group|
      # 가장 최근 것을 제외하고 나머지 삭제
      properties = Property.where(
        external_id: duplicate_group.external_id,
        source: duplicate_group.source
      ).order(created_at: :desc)
      
      properties.offset(1).destroy_all
      removed_count += properties.offset(1).count
    end
    
    final_count = Property.count
    
    puts "✅ Cleanup completed"
    puts "   Before: #{initial_count} properties"
    puts "   After: #{final_count} properties"
    puts "   Removed: #{removed_count} duplicates"
  end
end