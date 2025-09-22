#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🗺️ 지역 정보 테스트"
puts "=" * 30

# 전체 지역 수
all_regions = KoreaRegions.all_districts
puts "총 지역 수: #{all_regions.size}개"

# 서울 구 목록
seoul_districts = KoreaRegions.districts_for_region(:seoul)
puts "\n서울특별시: #{seoul_districts.size}개 구"
seoul_districts.first(5).each { |d| puts "  - #{d}" }

# 경기도 시/구 목록
gyeonggi_districts = KoreaRegions.districts_for_region(:gyeonggi)
puts "\n경기도: #{gyeonggi_districts.size}개 시/구"
gyeonggi_districts.first(5).each { |d| puts "  - #{d}" }

# 강남구 좌표 테스트
gangnam_bounds = KoreaRegions.get_region_bounds(:seoul, '강남구')
puts "\n강남구 좌표 정보:"
puts "  geohash: #{gangnam_bounds[:geohash]}"
puts "  중심: #{gangnam_bounds[:center_lat]}, #{gangnam_bounds[:center_lng]}"
puts "  범위: #{gangnam_bounds[:lat_south]}~#{gangnam_bounds[:lat_north]}"

puts "\n✅ 지역 정보 시스템 정상 작동!"