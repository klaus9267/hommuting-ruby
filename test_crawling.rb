#!/usr/bin/env ruby

# Test script for ZigbangTorCrawler
require_relative 'config/environment'

puts "Testing ZigbangTorCrawler..."

begin
  result = ZigbangTorCrawler.collect_all_properties('수지구')
  puts "Collected: #{result.size} properties"

  if result.any?
    # Show sample property data
    sample = result.first
    puts "\nSample property:"
    puts "Title: #{sample.title}"
    puts "Price: #{sample.price}"
    puts "Area (sqm): #{sample.area_sqm}"
    puts "Room structure: #{sample.room_structure}"
    puts "Maintenance fee: #{sample.maintenance_fee}"
    puts "Address: #{sample.address}"
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5)
end