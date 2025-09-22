#!/usr/bin/env ruby

# 직방 자동완성 API로 모든 서울/경기 지역 정보 수집
require_relative 'config/environment'
require 'httparty'
require 'json'

class RegionCollector
  include HTTParty
  base_uri 'https://apis.zigbang.com'

  def initialize
    @headers = {
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Accept' => 'application/json, text/plain, */*',
      'Referer' => 'https://www.zigbang.com/'
    }
  end

  def search_region(query)
    puts "🔍 '#{query}' 검색 중..."

    response = self.class.get('/v2/search', {
      query: {
        leaseYn: 'N',
        os: 'web',
        q: query,
        serviceType: '빌라'
      },
      headers: @headers
    })

    if response.success?
      results = response.parsed_response['items'] || []
      address_results = results.select { |item| item['type'] == 'address' }
      puts "   📍 #{address_results.size}개 지역 발견"
      address_results
    else
      puts "   ❌ 검색 실패: #{response.code}"
      []
    end
  end

  def collect_seoul_districts
    puts "\n🏙️ 서울특별시 구 정보 수집 시작"

    seoul_districts = []

    # 서울 25개 구 목록
    district_names = [
      '강남구', '강동구', '강북구', '강서구', '관악구', '광진구', '구로구', '금천구',
      '노원구', '도봉구', '동대문구', '동작구', '마포구', '서대문구', '서초구',
      '성동구', '성북구', '송파구', '양천구', '영등포구', '용산구', '은평구',
      '종로구', '중구', '중랑구'
    ]

    district_names.each do |district|
      results = search_region(district)

      # 서울 해당 구 찾기
      seoul_district = results.find do |item|
        item['description']&.include?('서울특별시') &&
        item['name'] == district
      end

      if seoul_district
        seoul_districts << {
          name: district,
          data: seoul_district
        }
        puts "   ✅ #{district}: #{seoul_district['description']}"

        # 요청 간 대기
        sleep(1)
      else
        puts "   ❌ #{district}: 찾을 수 없음"
      end
    end

    seoul_districts
  end

  def collect_gyeonggi_districts
    puts "\n🏘️ 경기도 시/구 정보 수집 시작"

    gyeonggi_districts = []

    # 경기도 구가 있는 시들 (구 단위로 세분화)
    district_searches = [
      # 수원시 (4개 구)
      '수원시 영통구', '수원시 팔달구', '수원시 장안구', '수원시 권선구',

      # 성남시 (3개 구)
      '성남시 분당구', '성남시 수정구', '성남시 중원구',

      # 용인시 (3개 구)
      '용인시 기흥구', '용인시 수지구', '용인시 처인구',

      # 고양시 (3개 구)
      '고양시 덕양구', '고양시 일산동구', '고양시 일산서구',

      # 안양시 (2개 구)
      '안양시 동안구', '안양시 만안구',

      # 안산시 (2개 구)
      '안산시 단원구', '안산시 상록구',

      # 구가 없는 시들 (시 단위)
      '부천시', '광명시', '평택시', '과천시', '구리시', '남양주시',
      '의정부시', '하남시', '김포시', '시흥시', '군포시', '의왕시',
      '화성시', '파주시', '이천시', '안성시', '포천시', '양주시',
      '여주시', '연천군', '가평군', '양평군', '오산시', '동두천시'
    ]

    district_searches.each do |search_term|
      results = search_region(search_term)

      # 경기도 해당 지역 찾기
      gyeonggi_results = results.select do |item|
        item['description']&.include?('경기도') &&
        (item['name'] == search_term ||
         item['description']&.include?(search_term))
      end

      if gyeonggi_results.empty? && search_term.include?(' ')
        # "수원시 영통구" 형태로 안 나오면 "영통구"만으로 재시도
        district_only = search_term.split(' ').last
        results = search_region(district_only)

        gyeonggi_results = results.select do |item|
          item['description']&.include?('경기도') &&
          item['description']&.include?(search_term.split(' ').first) &&
          item['name'] == district_only
        end
      end

      gyeonggi_results.each do |result|
        # 구가 있는 경우 "시 구" 형태로, 없는 경우 "시" 형태로 저장
        display_name = if search_term.include?(' ')
                        search_term  # "수원시 영통구"
                      else
                        result['name']  # "부천시"
                      end

        gyeonggi_districts << {
          name: display_name,
          data: result
        }
        puts "   ✅ #{display_name}: #{result['description']}"
      end

      # 요청 간 대기
      sleep(1)
    end

    gyeonggi_districts
  end

  def generate_korea_regions_code(seoul_districts, gyeonggi_districts)
    puts "\n📝 KoreaRegions 코드 생성 중..."

    code = <<~RUBY
      class KoreaRegions
        # 서울특별시 + 경기도 구/시 정보 (자동 수집됨)
        REGIONS = {
          # 서울특별시 (#{seoul_districts.size}개 구)
          seoul: {
            name: '서울특별시',
            districts: {
    RUBY

    # 서울 구 추가
    seoul_districts.each do |district|
      data = district[:data]
      code += <<~RUBY
              '#{district[:name]}' => {
                id: #{data['id']},
                lat: #{data['lat']},
                lng: #{data['lng']},
                description: '#{data['description']}',
                법정동코드: '#{data['_source']['법정동코드']}',
                geohash: 'wydm'
              },
      RUBY
    end

    code += <<~RUBY
            }
          },

          # 경기도 (#{gyeonggi_districts.size}개 시/구)
          gyeonggi: {
            name: '경기도',
            districts: {
    RUBY

    # 경기도 시/구 추가
    gyeonggi_districts.each do |district|
      data = district[:data]
      code += <<~RUBY
              '#{district[:name]}' => {
                id: #{data['id']},
                lat: #{data['lat']},
                lng: #{data['lng']},
                description: '#{data['description']}',
                법정동코드: '#{data['_source']['법정동코드']}',
                geohash: 'wydm'
              },
      RUBY
    end

    code += <<~RUBY
            }
          }
        }.freeze

        # 중심 좌표로부터 경계 좌표 계산 (줌 레벨 기반)
        def self.calculate_bounds(center_lat, center_lng, zoom_level = 13)
          # 줌 레벨에 따른 반경 계산 (대략적)
          radius = case zoom_level
                   when 13 then 0.05    # 약 5km 반경
                   when 12 then 0.1     # 약 10km 반경
                   when 11 then 0.2     # 약 20km 반경
                   else 0.05
                   end

          {
            geohash: 'wydm',  # 서울/경기 공통
            lat_south: center_lat - radius,
            lat_north: center_lat + radius,
            lng_west: center_lng - radius,
            lng_east: center_lng + radius,
            center_lat: center_lat,
            center_lng: center_lng
          }
        end

        # 지역별 경계 좌표 반환
        def self.get_region_bounds(region, district)
          region_data = REGIONS[region.to_sym]
          return nil unless region_data

          district_data = region_data[:districts][district]
          return nil unless district_data

          calculate_bounds(
            district_data[:lat],
            district_data[:lng],
            13  # 기본 줌 레벨
          )
        end

        # 모든 지역 목록 반환
        def self.all_districts
          result = []
          REGIONS.each do |region_key, region_data|
            region_data[:districts].each do |district_name, district_data|
              result << {
                region: region_data[:name],
                district: district_name,
                full_name: district_data[:description],
                bounds: calculate_bounds(district_data[:lat], district_data[:lng])
              }
            end
          end
          result
        end

        # 특정 지역의 모든 구/시 반환
        def self.districts_for_region(region)
          region_data = REGIONS[region.to_sym]
          return [] unless region_data

          region_data[:districts].keys
        end

        # 지역 검색 (자동완성용)
        def self.search_districts(query)
          all_districts.select do |district|
            district[:district].include?(query) ||
            district[:full_name].include?(query)
          end
        end
      end
    RUBY

    code
  end

  def run
    puts "🚀 직방 지역 정보 자동 수집 시작"
    puts "=" * 50

    # 서울 구 수집
    seoul_districts = collect_seoul_districts

    # 경기도 시/구 수집
    gyeonggi_districts = collect_gyeonggi_districts

    # 코드 생성
    korea_regions_code = generate_korea_regions_code(seoul_districts, gyeonggi_districts)

    # 파일에 저장
    File.write('app/models/korea_regions.rb', korea_regions_code)

    puts "\n📊 수집 결과:"
    puts "서울특별시: #{seoul_districts.size}개 구"
    puts "경기도: #{gyeonggi_districts.size}개 시/구"
    puts "총 #{seoul_districts.size + gyeonggi_districts.size}개 지역"

    puts "\n✅ app/models/korea_regions.rb 파일이 업데이트되었습니다!"
    puts "🎉 지역 정보 수집 완료!"
  end
end

# 실행
if __FILE__ == $0
  collector = RegionCollector.new
  collector.run
end