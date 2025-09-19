#!/usr/bin/env ruby

require_relative 'config/environment'

puts "Testing new property fields..."

begin
  # Test creating property with new fields
  test_property = Property.create!(
    title: "테스트 매물",
    address: "경기도 용인시 수지구",
    price: "50만원",
    property_type: "villa",
    deal_type: "monthly_rent",
    area_description: "55.02㎡",
    area_sqm: 55.02,
    floor_description: "3/6층",
    current_floor: 3,
    total_floors: 6,
    room_structure: "쓰리룸(복실 2개)",
    maintenance_fee: "30만원",
    latitude: 37.3257,
    longitude: 127.1041,
    external_id: "test_new_fields_#{Time.current.to_i}",
    description: "새로운 필드 테스트용 매물"
  )

  puts "✅ 새로운 필드로 매물 생성 성공!"
  puts "ID: #{test_property.id}"
  puts "면적(㎡): #{test_property.area_sqm}"
  puts "현재층: #{test_property.current_floor}"
  puts "전체층수: #{test_property.total_floors}"
  puts "방구조: #{test_property.room_structure}"
  puts "관리비: #{test_property.maintenance_fee}"

  # Test the extraction methods
  puts "\n=== 추출 메서드 테스트 ==="

  # Create an instance of crawler to test methods
  crawler = ZigbangTorCrawler.new

  sample_text = "쓰리룸(복실 2개) 55.02㎡ 3/6층 관리비 30만원 전세 1억2000"

  puts "테스트 텍스트: #{sample_text}"
  puts "면적(㎡): #{crawler.send(:extract_area_sqm, sample_text)}"
  puts "현재층: #{crawler.send(:extract_current_floor, sample_text)}"
  puts "전체층수: #{crawler.send(:extract_total_floors, sample_text)}"
  puts "방구조: #{crawler.send(:extract_room_structure, sample_text)}"
  puts "관리비: #{crawler.send(:extract_maintenance_fee, sample_text)}"

rescue => e
  puts "❌ 오류: #{e.message}"
  puts e.backtrace.first(5)
end