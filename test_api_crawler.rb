#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🚀 직방 API 크롤러 테스트"
puts "=" * 40

crawler = ZigbangApiCrawler.new

# 강남구 빌라 테스트 (KoreaRegions 사용)
puts "\n📍 강남구 빌라 테스트 시작"
properties = crawler.crawl_specific_district(:seoul, '강남구', ['villa'])

puts "\n📊 결과:"
puts "수집된 매물: #{properties.size}개"

# 첫 3개 매물 출력
properties.take(3).each_with_index do |prop, idx|
  puts "\n#{idx + 1}. #{prop[:title]}"
  puts "   가격: #{prop[:price]}"
  puts "   주소: #{prop[:address]}"
  puts "   URL: #{prop[:zigbang_url]}"
end

puts "\n🎉 테스트 완료!"