require 'selenium-webdriver'

class CrawlingService
  include HTTParty

  # 서울 지역 코드 (주요 구)
  SEOUL_AREAS = {
    '강남구' => '11680',
    '강동구' => '11740',
    '강북구' => '11305',
    '강서구' => '11500',
    '관악구' => '11620',
    '광진구' => '11215',
    '구로구' => '11530',
    '금천구' => '11545',
    '노원구' => '11350',
    '도봉구' => '11320',
    '동대문구' => '11230',
    '동작구' => '11590',
    '마포구' => '11440',
    '서대문구' => '11410',
    '서초구' => '11650',
    '성동구' => '11200',
    '성북구' => '11290',
    '송파구' => '11710',
    '양천구' => '11470',
    '영등포구' => '11560',
    '용산구' => '11170',
    '은평구' => '11380',
    '종로구' => '11110',
    '중구' => '11140',
    '중랑구' => '11260'
  }.freeze

  # 경기도 주요 시군 코드 (테스트용으로 수지구만)
  GYEONGGI_AREAS = {
    # '수원시' => '41110',
    # '성남시' => '41130',
    # '고양시' => '41280',
    '수지구' => '41460',  # 테스트용으로 수지구 사용
    # '부천시' => '41190',
    # '안산시' => '41270',
    # '안양시' => '41170',
    # '남양주시' => '41360',
    # '화성시' => '41590',
    # '평택시' => '41220',
    # '의정부시' => '41150',
    # '시흥시' => '41390',
    # '파주시' => '41480',
    # '광명시' => '41210',
    # '김포시' => '41570',
    # '군포시' => '41410',
    # '광주시' => '41610',
    # '이천시' => '41500',
    # '양주시' => '41630',
    # '오산시' => '41370',
    # '구리시' => '41310',
    # '안성시' => '41550',
    # '포천시' => '41650',
    # '의왕시' => '41430',
    # '하남시' => '41450'
  }.freeze

  # 직방 매물 타입별 URL
  ZIGBANG_URLS = {
    'apartment' => 'https://www.zigbang.com/home/apt/map',
    'villa' => 'https://www.zigbang.com/home/villa/map',
    'studio' => 'https://www.zigbang.com/home/oneroom/map',
    'officetel' => 'https://www.zigbang.com/home/officetel/map'
  }.freeze

  # 용인시 수지구 테스트 지역 (나중에 전체 지역으로 확장)
  TEST_AREAS = {
    '수지구' => {  # 더 구체적인 검색어 사용
      lat: 37.3257,
      lng: 127.1041,
      zoom_level: 14
    }
  }.freeze

  class << self
    def collect_seoul_properties
      collected_properties = []

      SEOUL_AREAS.each do |area_name, area_code|
        Rails.logger.info "서울 #{area_name} 매물 수집 시작..."

        properties = crawl_area_properties(area_name, area_code, '서울')
        collected_properties.concat(properties)

        # API 호출 간격 조절 (과도한 요청 방지)
        sleep(0.5)
      end

      {
        count: collected_properties.size,
        areas: SEOUL_AREAS.keys,
        properties: collected_properties
      }
    end

    def collect_gyeonggi_properties
      collected_properties = []

      GYEONGGI_AREAS.each do |area_name, area_code|
        Rails.logger.info "경기도 #{area_name} 매물 수집 시작..."

        # 직방에서 실제 크롤링
        properties = crawl_zigbang_properties(area_name)
        collected_properties.concat(properties)

        Rails.logger.info "경기도 #{area_name} 크롤링 완료: #{properties.size}개 매물 수집"
      end

      {
        count: collected_properties.size,
        areas: GYEONGGI_AREAS.keys,
        properties: collected_properties
      }
    end

    # 직방에서 실제 크롤링 (public method)
    def crawl_zigbang_properties(area_name)
      all_properties = []

      # 원룸에만 집중 (매물이 가장 많고 구조가 단순할 가능성)
      test_urls = {
        'studio' => 'https://www.zigbang.com/home/oneroom/map'
      }

      test_urls.each do |property_type, url|
        Rails.logger.info "#{area_name} #{property_type} 크롤링 시작..."

        begin
          properties = crawl_zigbang_by_type(url, area_name, property_type)
          all_properties.concat(properties)

          Rails.logger.info "#{area_name} #{property_type}: #{properties.size}개 매물 수집 완료"

        rescue => e
          Rails.logger.error "#{area_name} #{property_type} 크롤링 실패: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end

      all_properties
    end

    private

    def crawl_area_properties(area_name, area_code, province)
      properties = []

      # 각 매물 유형별로 수집
      Property.property_types.keys.each do |property_type|
        Property.deal_types.keys.each do |deal_type|
          begin
            # 실제 크롤링 로직은 여기에 구현
            # 현재는 샘플 데이터 생성
            sample_properties = create_sample_properties(area_name, area_code, province, property_type, deal_type)
            properties.concat(sample_properties)

            Rails.logger.info "#{province} #{area_name} - #{property_type} #{deal_type}: #{sample_properties.size}개 수집"

          rescue => e
            Rails.logger.error "#{province} #{area_name} #{property_type} #{deal_type} 수집 실패: #{e.message}"
          end
        end
      end

      properties
    end

    # 실제 크롤링 전 샘플 데이터 생성 (테스트용)
    def create_sample_properties(area_name, area_code, province, property_type, deal_type)
      # 랜덤으로 1-3개 매물 생성
      property_count = rand(1..3)

      property_count.times.map do |i|
        # 중복 방지를 위한 external_id 생성
        external_id = "#{area_code}_#{property_type}_#{deal_type}_#{Time.current.to_i}_#{i}"

        # 이미 존재하는 매물인지 확인
        next if Property.exists?(external_id: external_id, source: 'sample_crawler')

        # 좌표 생성 (서울/경기도 범위 내)
        lat, lng = generate_coordinates_for_area(province, area_name)

        property = Property.create!(
          title: "#{area_name} #{property_type} #{deal_type} 매물 #{i+1}",
          address: "#{province} #{area_name} 샘플로 #{rand(1..999)}",
          price: generate_price(deal_type),
          property_type: property_type,
          deal_type: deal_type,
          area: "#{rand(20..150)}㎡",
          floor: "#{rand(1..20)}층",
          latitude: lat,
          longitude: lng,
          source: 'sample_crawler',
          external_id: external_id,
          description: "#{area_name}에 위치한 #{property_type} #{deal_type} 매물입니다.",
          raw_data: {
            area_code: area_code,
            crawled_at: Time.current,
            province: province,
            area_name: area_name
          }.to_json
        )

        property
      end.compact
    end

    def generate_coordinates_for_area(province, area_name)
      if province == '서울'
        # 서울 좌표 범위: 37.4-37.7, 126.8-127.2
        lat = 37.4 + rand * 0.3
        lng = 126.8 + rand * 0.4
      else # 경기도
        # 경기도 좌표 범위: 37.0-38.0, 126.5-127.5
        lat = 37.0 + rand * 1.0
        lng = 126.5 + rand * 1.0
      end

      [lat.round(6), lng.round(6)]
    end

    def generate_price(deal_type)
      case deal_type
      when 'sale' # 매매
        "#{rand(3..15)}억 #{rand(1000..9999)}만원"
      when 'jeonse' # 전세
        "#{rand(1..8)}억 #{rand(1000..9999)}만원"
      when 'monthly_rent' # 월세
        "#{rand(100..1000)}/#{rand(50..300)}"
      else
        "#{rand(1..10)}억원"
      end
    end

    # === 직방 크롤링 메서드들 ===

    def crawl_zigbang_by_type(url, area_name, property_type)
      driver = setup_webdriver
      properties = []

      begin
        Rails.logger.info "직방 접속: #{url}"
        driver.get(url)

        # 페이지 로딩 대기
        sleep(3)

        # 지역 검색 (수지구)
        search_area_in_zigbang(driver, area_name)

        # 매물 리스트 수집
        properties = extract_properties_from_page(driver, area_name, property_type)

      rescue => e
        Rails.logger.error "직방 크롤링 오류: #{e.message}"
        raise e
      ensure
        driver&.quit
      end

      properties
    end

    def setup_webdriver
      options = Selenium::WebDriver::Chrome::Options.new

      # 헤드리스 모드 - 디버깅을 위해 해제 (실제 브라우저 창 표시)
      # options.add_argument('--headless')

      # 봇 감지 방지 설정
      options.add_argument('--disable-blink-features=AutomationControlled')
      options.add_argument('--disable-extensions')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')

      # User-Agent 설정
      user_agents = [
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      ]
      options.add_argument("--user-agent=#{user_agents.sample}")

      driver = Selenium::WebDriver.for :chrome, options: options

      # 자동화 관련 속성 제거
      driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")

      driver
    end

    def search_area_in_zigbang(driver, area_name)
      begin
        # 검색창 찾기 (여러 선택자 시도)
        search_selectors = [
          'input[placeholder*="지역"]',
          'input[placeholder*="검색"]',
          '.search-input',
          '[data-testid="search-input"]',
          'input[type="text"]'
        ]

        search_input = nil
        search_selectors.each do |selector|
          begin
            search_input = driver.find_element(:css, selector)
            break if search_input
          rescue Selenium::WebDriver::Error::NoSuchElementError
            next
          end
        end

        if search_input
          Rails.logger.info "검색창 발견, 지역 검색 시작: #{area_name}"

          # 기존 텍스트 클리어 후 입력
          search_input.clear
          search_input.send_keys(area_name)
          sleep(2)
          search_input.send_keys(:return)

          # 검색 결과 로딩 대기
          sleep(5)

          # 검색 결과 클릭 시도
          search_results = ['수지구', '용인시 수지구']
          search_results.each do |result_text|
            begin
              result_element = driver.find_element(:xpath, "//div[contains(text(), '#{result_text}')]")
              if result_element
                Rails.logger.info "검색 결과 클릭: #{result_text}"
                result_element.click
                sleep(3)
                break
              end
            rescue
              next
            end
          end

          Rails.logger.info "지역 검색 완료"
        else
          Rails.logger.warn "검색창을 찾을 수 없음 - URL 파라미터로 지역 설정 시도"

          # URL에 직접 지역 파라미터 추가 시도
          current_url = driver.current_url
          if !current_url.include?('zoom')
            new_url = "#{current_url}?lat=37.3257&lng=127.1041&zoom=14"
            driver.get(new_url)
            sleep(5)
            Rails.logger.info "URL 파라미터로 수지구 위치 설정"
          end
        end

      rescue => e
        Rails.logger.error "지역 검색 중 오류: #{e.message}"
      end
    end

    def extract_properties_from_page(driver, area_name, property_type)
      properties = []

      begin
        # 매물 리스트가 로드될 때까지 충분히 대기 (React SPA)
        Rails.logger.info "매물 데이터 로딩 대기 중..."
        sleep(10)

        # 다양한 방법으로 매물 데이터 로딩 시도
        trigger_property_loading(driver, area_name)

        # 새로운 접근법: 직방의 실제 API 호출이나 데이터 구조 분석
        Rails.logger.info "=== 직방 실제 데이터 구조 분석 ==="

        # 1. 먼저 페이지에서 가격이 실제로 표시되는지 확인
        page_source = driver.page_source
        Rails.logger.info "페이지 타이틀: #{driver.title}"

        # 정확한 가격 패턴들을 찾아보기 (직방 특화)
        price_matches = page_source.scan(/(\d+억|\d+,\d+만원?|\d+\/\d+|전세 \d+억?|\d+백만원?)/i).flatten.uniq
        Rails.logger.info "실제 가격 패턴들: #{price_matches.first(10)}"

        # 가격 패턴이 있는 경우, 해당 패턴 주변의 HTML 구조 분석
        if price_matches.any?
          Rails.logger.info "=== 가격 패턴 주변 HTML 구조 분석 ==="
          price_matches.first(3).each do |price_pattern|
            # 가격 패턴 주변의 HTML 찾기
            html_with_price = page_source.scan(/.{0,200}#{Regexp.escape(price_pattern)}.{0,200}/m).first
            if html_with_price
              Rails.logger.info "가격 #{price_pattern} 주변 HTML: #{html_with_price[0..400]}"

              # 해당 가격을 포함하는 실제 DOM 요소 찾기
              begin
                elements_with_price = driver.find_elements(:xpath, "//*[contains(text(), '#{price_pattern}')]")
                elements_with_price.each_with_index do |elem, idx|
                  parent = elem.find_element(:xpath, "..")
                  Rails.logger.info "가격 요소 #{idx + 1} 부모: 클래스=#{parent.attribute('class')}, 텍스트=#{parent.text[0..100]}"
                end
              rescue => e
                Rails.logger.debug "가격 요소 검색 실패: #{e.message}"
              end
            end
          end
        end

        # 2. 직방 API 직접 호출 시도
        api_data = try_direct_api_call(area_name)
        if api_data && api_data['items']
          Rails.logger.info "API 데이터 발견: #{api_data['items'].size}개 매물"
          return process_api_data(api_data, area_name, property_type)
        end

        # 3. 데이터 속성이나 JSON 구조에서 매물 정보 찾기
        if page_source.include?('window.__INITIAL_STATE__') || page_source.include?('window.__NEXT_DATA__')
          Rails.logger.info "React 초기 상태 데이터 발견 - JSON 파싱 시도"
          property_elements = extract_from_react_data(driver, page_source)
        else
          # 4. 매물 카드들을 더 정확하게 식별
          property_elements = find_real_property_cards(driver)
        end

        Rails.logger.info "발견된 매물 카드 수: #{property_elements.size}"

        # 실제 매물 데이터 추출
        property_elements.first(10).each_with_index do |element, index|
          begin
            property_data = extract_property_data_improved(driver, element, area_name, property_type, index)

            if property_data && property_data[:price] != "가격 정보 없음"
              # 중복 체크
              external_id = "zigbang_#{property_type}_#{area_name}_#{property_data[:title]}_#{Time.current.to_i}"

              unless Property.exists?(external_id: external_id, source: 'zigbang')
                property = Property.create!(
                  title: property_data[:title],
                  address: property_data[:address],
                  price: property_data[:price],
                  property_type: map_property_type(property_type),
                  deal_type: property_data[:deal_type],
                  area: property_data[:area],
                  floor: property_data[:floor],
                  latitude: property_data[:latitude],
                  longitude: property_data[:longitude],
                  source: 'zigbang',
                  external_id: external_id,
                  description: property_data[:description],
                  raw_data: property_data.to_json
                )

                properties << property
                Rails.logger.info "실제 매물 저장 완료: #{property_data[:title]} - #{property_data[:price]}"
              end
            else
              Rails.logger.warn "매물 #{index + 1}: 유효한 데이터 없음"
            end

          rescue => e
            Rails.logger.error "매물 #{index + 1} 추출 실패: #{e.message}"
          end
        end

      rescue => e
        Rails.logger.error "매물 리스트 추출 중 오류: #{e.message}"
      end

      properties
    end

    # React 앱의 초기 상태에서 매물 데이터 추출
    def extract_from_react_data(driver, page_source)
      begin
        # __INITIAL_STATE__ 또는 __NEXT_DATA__에서 JSON 데이터 추출
        json_match = page_source.match(/window\.__INITIAL_STATE__\s*=\s*({.*?});/) ||
                     page_source.match(/window\.__NEXT_DATA__\s*=\s*({.*?})/)

        if json_match
          Rails.logger.info "JSON 데이터 발견, 파싱 시도"
          # JSON 파싱은 복잡하므로 일단 스킵하고 DOM 기반 접근
        end
      rescue => e
        Rails.logger.error "JSON 데이터 파싱 실패: #{e.message}"
      end

      # JSON 파싱 실패시 DOM 기반으로 폴백
      find_real_property_cards(driver)
    end

    # 실제 매물 카드들을 찾는 개선된 로직
    def find_real_property_cards(driver)
      Rails.logger.info "=== 실제 매물 카드 탐지 시작 ==="

      # 직방의 일반적인 매물 카드 패턴들
      card_selectors = [
        # 직방 특화 선택자들
        '[data-testid*="room"]',
        '[data-testid*="property"]',
        '[data-testid*="item"]',
        '.room-card',
        '.property-card',
        '.item-card',
        # 일반적인 카드 패턴들
        'article',
        '.card',
        '[class*="item"]:not([class*="menu"]):not([class*="tab"]):not([class*="nav"])',
        '[class*="room"]:not([class*="search"])',
        'div[role="listitem"]',
        'li[class*="item"]'
      ]

      property_elements = []

      card_selectors.each do |selector|
        begin
          elements = driver.find_elements(:css, selector)
          next if elements.empty?

          Rails.logger.info "#{selector}: #{elements.size}개 요소 발견"

          # 각 요소에 실제 매물 정보가 있는지 검증
          valid_elements = elements.select do |element|
            is_property_card?(element)
          end

          if valid_elements.any?
            Rails.logger.info "#{selector}에서 #{valid_elements.size}개 유효한 매물 카드 발견"
            property_elements = valid_elements
            break
          end

        rescue => e
          Rails.logger.debug "#{selector} 시도 실패: #{e.message}"
          next
        end
      end

      # 선택자로 찾지 못한 경우, 휴리스틱 방식으로 찾기
      if property_elements.empty?
        Rails.logger.info "선택자 방식 실패, 휴리스틱 탐지 시작"
        property_elements = find_cards_by_heuristics(driver)
      end

      property_elements
    end

    # 요소가 실제 매물 카드인지 판단 (개선된 버전)
    def is_property_card?(element)
      begin
        text = element.text.strip
        return false if text.length < 10 || text.length > 2000

        # 확실한 UI 요소들 제외 (더 정확한 필터링)
        definite_excludes = [
          '로그인', '회원가입', '필터', '정렬', '지도', '목록',
          '상세검색', '즐겨찾기', 'SNS', '카카오', '네이버',
          '매매/전월세/신축분양', '빌라, 투룸+', '시세', '호갱노노',
          '중학교', '초등학교', '고등학교', '대학교',  # 학교 이름들
          '지하철', '버스', '정류장'  # 교통 관련
        ]

        is_ui_element = definite_excludes.any? { |exclude| text.include?(exclude) }
        return false if is_ui_element

        # 매물 정보 패턴 체크 (더 관대하게)
        has_price = text.match?(/\d+억|\d+,\d+만?원?|\d+\/\d+|전세|월세|보증금/)
        has_area = text.match?(/\d+\.?\d*㎡|\d+\.?\d*평/)
        has_floor = text.match?(/\d+층|\d+\/\d+층/)
        has_room_info = text.match?(/방\d+|원룸|투룸|빌라|아파트|오피스텔/)
        has_location = text.match?(/구|동|로|길|번지/) && !text.include?('서비스')

        # 더 관대한 조건: 하나라도 매칭되면 가능성 있음
        potential_property = has_price || has_area || has_floor || has_room_info || has_location

        # 하지만 텍스트가 너무 단순하면 제외 (예: 단순 숫자나 한 단어)
        return false if text.split.size < 2 && !has_price

        potential_property

      rescue => e
        Rails.logger.debug "매물 카드 판단 실패: #{e.message}"
        false
      end
    end

    # 휴리스틱 방식으로 매물 카드 찾기
    def find_cards_by_heuristics(driver)
      Rails.logger.info "=== 휴리스틱 매물 카드 탐지 ==="

      all_divs = driver.find_elements(:css, 'div')
      Rails.logger.info "전체 div 요소 수: #{all_divs.size}"

      # 매물 카드 후보들 필터링
      candidates = all_divs.select do |div|
        is_property_card?(div)
      end

      Rails.logger.info "휴리스틱으로 발견된 매물 카드 후보: #{candidates.size}개"

      candidates.first(10)  # 상위 10개만 사용
    end

    # 개선된 매물 데이터 추출 메서드
    def extract_property_data_improved(driver, element, area_name, property_type, index)
      begin
        Rails.logger.info "=== 매물 #{index + 1} 개선된 추출 ==="

        # 요소의 전체 텍스트와 HTML 구조 분석
        element_text = element.text.strip rescue ""
        element_html = element.attribute('outerHTML') rescue ""

        Rails.logger.info "요소 텍스트 (#{element_text.length}자): #{element_text[0..200]}"

        # 1. 하위 요소들에서 개별적으로 가격, 면적, 층수 찾기
        price = extract_price_from_element(element) || extract_price_from_text(element_text, element)
        area_info = extract_area_from_element(element) || extract_area_from_text(element_text, element)
        floor_info = extract_floor_from_element(element) || extract_floor_from_text(element_text, element)
        address_info = extract_address_from_element(element) || extract_address_from_text(element_text, element, area_name)

        Rails.logger.info "추출 결과 - 가격: #{price}, 면적: #{area_info}, 층수: #{floor_info}, 주소: #{address_info}"

        # 2. 데이터 품질 검증 - 실제 매물 정보가 있는지 확인
        if price == "가격 정보 없음" && area_info == "면적 정보 없음" && floor_info == "층수 정보 없음"
          Rails.logger.warn "매물 #{index + 1}: 유효한 정보 없음, 스킵"
          return nil
        end

        # 제목 생성
        title = generate_property_title(area_name, property_type, price, area_info, index)
        deal_type = determine_deal_type(price)

        # 기본 좌표 (수지구 중심)
        latitude = 37.3257 + (rand(-100..100) * 0.0001)
        longitude = 127.1041 + (rand(-100..100) * 0.0001)

        {
          title: title,
          address: address_info,
          price: price,
          area: area_info,
          floor: floor_info,
          deal_type: deal_type,
          latitude: latitude,
          longitude: longitude,
          description: "직방에서 수집된 #{area_name} #{property_type} 매물입니다.",
          crawled_at: Time.current,
          original_text: element_text[0..300],
          html_snippet: element_html[0..500]
        }

      rescue => e
        Rails.logger.error "매물 데이터 추출 실패: #{e.message}"
        nil
      end
    end

    # 요소의 하위 요소들에서 가격 정보 찾기
    def extract_price_from_element(element)
      price_selectors = [
        '[class*="price"]',
        '[class*="amount"]',
        '[class*="cost"]',
        'span:contains("억")',
        'div:contains("억")',
        'span:contains("/")',  # 월세 패턴
        'strong',
        'b'
      ]

      price_selectors.each do |selector|
        begin
          # CSS 선택자로 시도
          price_elements = element.find_elements(:css, selector.split(':').first)
          price_elements.each do |price_el|
            text = price_el.text.strip
            next if text.empty?

            # 가격 패턴 매칭
            if text.match?(/\d+억|\d+,\d+|\d+\/\d+|전세|월세/)
              extracted = extract_price_from_text(text, price_el)
              return extracted if extracted != "가격 정보 없음"
            end
          end
        rescue
          next
        end
      end

      nil
    end

    # 요소의 하위 요소들에서 면적 정보 찾기
    def extract_area_from_element(element)
      area_selectors = [
        '[class*="area"]',
        '[class*="size"]',
        'span:contains("㎡")',
        'div:contains("㎡")',
        'span:contains("평")',
        'div:contains("평")'
      ]

      area_selectors.each do |selector|
        begin
          area_elements = element.find_elements(:css, selector.split(':').first)
          area_elements.each do |area_el|
            text = area_el.text.strip
            next if text.empty?

            if text.match?(/\d+\.?\d*㎡|\d+\.?\d*평/)
              extracted = extract_area_from_text(text, area_el)
              return extracted if extracted != "면적 정보 없음"
            end
          end
        rescue
          next
        end
      end

      nil
    end

    # 요소의 하위 요소들에서 층수 정보 찾기
    def extract_floor_from_element(element)
      floor_selectors = [
        '[class*="floor"]',
        'span:contains("층")',
        'div:contains("층")'
      ]

      floor_selectors.each do |selector|
        begin
          floor_elements = element.find_elements(:css, selector.split(':').first)
          floor_elements.each do |floor_el|
            text = floor_el.text.strip
            next if text.empty?

            if text.match?(/\d+층|\d+\/\d+층/)
              extracted = extract_floor_from_text(text, floor_el)
              return extracted if extracted != "층수 정보 없음"
            end
          end
        rescue
          next
        end
      end

      nil
    end

    # 요소의 하위 요소들에서 주소 정보 찾기
    def extract_address_from_element(element)
      address_selectors = [
        '[class*="address"]',
        '[class*="location"]',
        '[class*="area"]',
        'span:contains("동")',
        'div:contains("동")',
        'span:contains("로")',
        'div:contains("로")'
      ]

      address_selectors.each do |selector|
        begin
          address_elements = element.find_elements(:css, selector.split(':').first)
          address_elements.each do |addr_el|
            text = addr_el.text.strip
            next if text.empty? || text.length > 50

            if text.match?(/\S+동|뜰|\w+길|\w+로/) && !text.include?('서비스')
              return text
            end
          end
        rescue
          next
        end
      end

      nil
    end

    # 매물 데이터 로딩을 위한 다양한 상호작용 시도
    def trigger_property_loading(driver, area_name)
      Rails.logger.info "=== 매물 로딩 트리거 시도 ==="

      # 1. 스크롤링으로 데이터 로딩 유도
      3.times do |i|
        driver.execute_script("window.scrollTo(0, #{i * 500});")
        sleep(1)
      end

      # 2. 지도 영역 클릭하여 매물 표시 시도
      begin
        map_container = driver.find_element(:css, '#map, .map, [class*="map"]')
        if map_container
          Rails.logger.info "지도 컨테이너 발견, 클릭 시도"
          driver.action.move_to(map_container).click.perform
          sleep(3)
        end
      rescue => e
        Rails.logger.debug "지도 클릭 실패: #{e.message}"
      end

      # 3. 리스트 보기 버튼 찾아서 클릭
      list_buttons = ['목록', '리스트', 'list', '매물보기']
      list_buttons.each do |btn_text|
        begin
          button = driver.find_element(:xpath, "//button[contains(text(), '#{btn_text}')]")
          if button
            Rails.logger.info "#{btn_text} 버튼 클릭"
            button.click
            sleep(3)
            break
          end
        rescue
          next
        end
      end

      # 4. 필터나 가격 범위 클릭으로 매물 표시 유도
      begin
        price_filters = driver.find_elements(:css, '[class*="filter"], [class*="price"]')
        if price_filters.any?
          Rails.logger.info "필터 영역 클릭 시도"
          price_filters.first.click
          sleep(2)
        end
      rescue => e
        Rails.logger.debug "필터 클릭 실패: #{e.message}"
      end

      # 5. Ajax 요청 완료 대기
      10.times do
        loading_indicator = driver.find_elements(:css, '.loading, [class*="loading"], [class*="spinner"]')
        break if loading_indicator.empty?
        sleep(1)
      end

      Rails.logger.info "매물 로딩 트리거 완료"

      # 6. 브라우저의 네트워크 로그에서 API 요청 확인
      begin
        logs = driver.manage.logs.get(:performance)
        api_requests = logs.select { |log|
          log.message.include?('zigbang') &&
          (log.message.include?('room') || log.message.include?('property') || log.message.include?('item'))
        }
        if api_requests.any?
          Rails.logger.info "발견된 API 요청들:"
          api_requests.first(3).each { |req| Rails.logger.info req.message[0..200] }
        end
      rescue => e
        Rails.logger.debug "네트워크 로그 확인 실패: #{e.message}"
      end
    end

    # 직방 API 직접 호출 시도
    def try_direct_api_call(area_name)
      Rails.logger.info "=== 직방 API 직접 호출 시도 ==="

      # 수지구 좌표
      lat, lng = 37.3257, 127.1041

      api_endpoints = [
        "https://api.zigbang.com/v1/items",
        "https://api.zigbang.com/v2/items",
        "https://www.zigbang.com/api/v1/items",
        "https://www.zigbang.com/api/map/items"
      ]

      api_endpoints.each do |endpoint|
        begin
          response = HTTParty.get(endpoint, {
            query: {
              lat: lat,
              lng: lng,
              radius: 1000,
              room_type: [1, 2, 3],  # 원룸, 1.5룸, 투룸
              deposit_min: 0,
              rent_min: 0
            },
            headers: {
              'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
              'Referer' => 'https://www.zigbang.com/'
            },
            timeout: 10
          })

          if response.code == 200 && response.body.include?('item')
            Rails.logger.info "API 응답 성공: #{endpoint}"
            Rails.logger.info "응답 샘플: #{response.body[0..300]}"
            return JSON.parse(response.body)
          end
        rescue => e
          Rails.logger.debug "API 호출 실패 #{endpoint}: #{e.message}"
        end
      end

      nil
    end

    # API 데이터를 Property 모델로 변환
    def process_api_data(api_data, area_name, property_type)
      properties = []

      api_data['items'].each_with_index do |item, index|
        begin
          external_id = "zigbang_api_#{item['id']}_#{Time.current.to_i}"
          next if Property.exists?(external_id: external_id, source: 'zigbang_api')

          property = Property.create!(
            title: "#{area_name} #{property_type} #{item['room_type_str'] || ''}",
            address: item['address'] || "#{area_name} #{item['dong'] || ''}",
            price: format_price(item),
            property_type: map_property_type(property_type),
            deal_type: determine_deal_type_from_item(item),
            area: "#{item['size_m2'] || '0'}㎡",
            floor: "#{item['floor']}/#{item['building_floor']}층",
            latitude: item['lat'] || 37.3257,
            longitude: item['lng'] || 127.1041,
            source: 'zigbang_api',
            external_id: external_id,
            description: "직방 API에서 수집된 #{area_name} 매물",
            raw_data: item.to_json
          )

          properties << property
          Rails.logger.info "API 매물 저장: #{property.title} - #{property.price}"

        rescue => e
          Rails.logger.error "API 매물 #{index} 저장 실패: #{e.message}"
        end
      end

      properties
    end

    def format_price(item)
      if item['rent']
        "#{item['deposit']}/#{item['rent']}"
      elsif item['sales_price']
        "#{item['sales_price']}만원"
      else
        "#{item['deposit']}만원"
      end
    end

    def determine_deal_type_from_item(item)
      return 'monthly_rent' if item['rent'] && item['rent'] > 0
      return 'jeonse' if item['deposit'] && item['deposit'] > 0
      'sale'
    end

    def extract_property_data(driver, element, area_name, property_type, index)
      begin
        Rails.logger.info "=== 매물 #{index + 1} 상세 분석 ==="

        # 요소의 전체 텍스트 먼저 확인
        element_text = element.text.strip rescue ""
        Rails.logger.info "요소 전체 텍스트: #{element_text}"

        # 가격 정보 추출 (다양한 패턴 시도)
        price = extract_price_from_text(element_text, element)
        Rails.logger.info "추출된 가격: #{price}"

        # 면적 정보 추출
        area_info = extract_area_from_text(element_text, element)
        Rails.logger.info "추출된 면적: #{area_info}"

        # 층수 정보 추출
        floor_info = extract_floor_from_text(element_text, element)
        Rails.logger.info "추출된 층수: #{floor_info}"

        # 주소/위치 정보 추출
        address_info = extract_address_from_text(element_text, element, area_name)
        Rails.logger.info "추출된 주소: #{address_info}"

        # 제목 생성
        title = generate_property_title(area_name, property_type, price, area_info, index)

        # 거래 유형 추출 (가격에서 판단)
        deal_type = determine_deal_type(price)

        # 기본 좌표 (수지구 중심)
        latitude = 37.3257 + (rand(-100..100) * 0.0001)
        longitude = 127.1041 + (rand(-100..100) * 0.0001)

        {
          title: title,
          address: address_info,
          price: price,
          area: area_info,
          floor: floor_info,
          deal_type: deal_type,
          latitude: latitude,
          longitude: longitude,
          description: "직방에서 수집된 #{area_name} #{property_type} 매물입니다.",
          crawled_at: Time.current,
          original_text: element_text[0..200] # 디버깅용
        }

      rescue => e
        Rails.logger.error "매물 데이터 추출 실패: #{e.message}"
        nil
      end
    end

    # 가격 정보 추출
    def extract_price_from_text(text, element)
      # 억원 패턴 (예: 3억 5000만원, 12억원)
      if match = text.match(/(\d+)억\s*(\d+,?\d*)?만?원?/)
        eok = match[1].to_i
        man = match[2] ? match[2].gsub(',', '').to_i : 0
        return "#{eok}억#{man > 0 ? " #{man}만원" : '원'}"
      end

      # 월세 패턴 (예: 500/50, 1000/100)
      if match = text.match(/(\d+,?\d*)\/(\d+,?\d*)/)
        return "#{match[1]}/#{match[2]}"
      end

      # 만원 패턴 (예: 3000만원)
      if match = text.match(/(\d+,?\d*)만원/)
        return "#{match[1]}만원"
      end

      # 전세 패턴
      if text.include?('전세') && (match = text.match(/(\d+,?\d*)/))
        return "전세 #{match[1]}"
      end

      return "가격 정보 없음"
    end

    # 면적 정보 추출
    def extract_area_from_text(text, element)
      # ㎡ 패턴
      if match = text.match(/(\d+\.?\d*)㎡/)
        return "#{match[1]}㎡"
      end

      # 평 패턴
      if match = text.match(/(\d+\.?\d*)평/)
        return "#{match[1]}평"
      end

      return "면적 정보 없음"
    end

    # 층수 정보 추출
    def extract_floor_from_text(text, element)
      # 층 패턴 (예: 3층, 5/12층)
      if match = text.match(/(\d+)\/(\d+)층/)
        return "#{match[1]}/#{match[2]}층"
      end

      if match = text.match(/(\d+)층/)
        return "#{match[1]}층"
      end

      return "층수 정보 없음"
    end

    # 주소 정보 추출
    def extract_address_from_text(text, element, area_name)
      # 구체적인 주소가 있는지 확인
      if text.match?(/\S+동|뜰|\w+길|\w+로/)
        address_match = text.match(/([가-힣\w\s]+(?:동|길|로)[\w\s]*)/i)
        return "#{area_name} #{address_match[1]}" if address_match
      end

      return area_name
    end

    # 매물 제목 생성
    def generate_property_title(area_name, property_type, price, area_info, index)
      type_kr = case property_type
                when 'apartment' then '아파트'
                when 'villa' then '빌라'
                when 'studio' then '원룸'
                when 'officetel' then '오피스텔'
                else property_type
                end

      "#{area_name} #{type_kr} #{price != '가격 정보 없음' ? price : ''} #{area_info != '면적 정보 없음' ? area_info : ''} #{index + 1}".strip
    end

    def safe_extract_text(element, selectors)
      selectors.each do |selector|
        begin
          text_element = element.find_element(:css, selector)
          text = text_element.text.strip
          return text if text.present?
        rescue
          next
        end
      end
      nil
    end

    def determine_deal_type(price_text)
      return 'monthly_rent' if price_text.include?('/') || price_text.include?('월세')
      return 'jeonse' if price_text.include?('전세')
      return 'sale' if price_text.include?('매매') || price_text.include?('억')
      'sale' # 기본값
    end

    def map_property_type(zigbang_type)
      case zigbang_type
      when 'apartment'
        'apartment'
      when 'villa'
        'villa'
      when 'studio'
        'villa' # 원룸을 빌라로 매핑 (enum에 원룸이 없으므로)
      when 'officetel'
        'officetel'
      else
        'apartment'
      end
    end
  end
end