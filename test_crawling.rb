#!/usr/bin/env ruby

# Simple test script for the crawling service
require_relative 'config/environment'

puts "Testing improved crawling service..."

begin
  result = CrawlingService.crawl_zigbang_properties('수지구')
  puts "Collected: #{result.size} properties"

  if result.any?
    # Show sample property data
    sample = result.first
    puts "\nSample property:"
    puts "Title: #{sample.title}"
    puts "Price: #{sample.price}"
    puts "Area: #{sample.area}"
    puts "Floor: #{sample.floor}"
    puts "Address: #{sample.address}"
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5)
end