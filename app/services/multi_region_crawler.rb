require 'selenium-webdriver'

class MultiRegionCrawler
  TOR_PROXY = {
    host: '127.0.0.1',
    port: 9050,
    type: :socks
  }.freeze

  # 서울 구별 좌표 (실제 각 구의 중심 좌표)
  SEOUL_DISTRICTS = {
    '강남구' => { lat: 37.5173, lng: 127.0473, full_name: '서울특별시 강남구' },
    '강동구' => { lat: 37.5301, lng: 127.1238, full_name: '서울특별시 강동구' },
    '강북구' => { lat: 37.6397, lng: 127.0256, full_name: '서울특별시 강북구' },
    '강서구' => { lat: 37.5509, lng: 126.8495, full_name: '서울특별시 강서구' },
    '관악구' => { lat: 37.4784, lng: 126.9516, full_name: '서울특별시 관악구' },
    '광진구' => { lat: 37.5384, lng: 127.0822, full_name: '서울특별시 광진구' },
    '구로구' => { lat: 37.4954, lng: 126.8879, full_name: '서울특별시 구로구' },
    '금천구' => { lat: 37.4519, lng: 126.8954, full_name: '서울특별시 금천구' },
    '노원구' => { lat: 37.6541, lng: 127.0568, full_name: '서울특별시 노원구' },
    '도봉구' => { lat: 37.6688, lng: 127.0471, full_name: '서울특별시 도봉구' },
    '동대문구' => { lat: 37.5744, lng: 127.0396, full_name: '서울특별시 동대문구' },
    '동작구' => { lat: 37.5124, lng: 126.9393, full_name: '서울특별시 동작구' },
    '마포구' => { lat: 37.5637, lng: 126.9084, full_name: '서울특별시 마포구' },
    '서대문구' => { lat: 37.5791, lng: 126.9368, full_name: '서울특별시 서대문구' },
    '서초구' => { lat: 37.4837, lng: 127.0324, full_name: '서울특별시 서초구' },
    '성동구' => { lat: 37.5636, lng: 127.0369, full_name: '서울특별시 성동구' },
    '성북구' => { lat: 37.5894, lng: 127.0167, full_name: '서울특별시 성북구' },
    '송파구' => { lat: 37.5145, lng: 127.1059, full_name: '서울특별시 송파구' },
    '양천구' => { lat: 37.5169, lng: 126.8665, full_name: '서울특별시 양천구' },
    '영등포구' => { lat: 37.5264, lng: 126.8962, full_name: '서울특별시 영등포구' },
    '용산구' => { lat: 37.5311, lng: 126.9810, full_name: '서울특별시 용산구' },
    '은평구' => { lat: 37.6027, lng: 126.9291, full_name: '서울특별시 은평구' },
    '종로구' => { lat: 37.5735, lng: 126.9788, full_name: '서울특별시 종로구' },
    '중구' => { lat: 37.5640, lng: 126.9975, full_name: '서울특별시 중구' },
    '중랑구' => { lat: 37.6063, lng: 127.0925, full_name: '서울특별시 중랑구' }
  }.freeze

  # 경기도 주요 시/군별 구/동 단위 구조
  GYEONGGI_DISTRICTS = {
    # 수원시 (4개 구)
    '수원시 영통구' => { lat: 37.2574, lng: 127.0457, full_name: '경기도 수원시 영통구' },
    '수원시 팔달구' => { lat: 37.2795, lng: 127.0089, full_name: '경기도 수원시 팔달구' },
    '수원시 장안구' => { lat: 37.3006, lng: 127.0106, full_name: '경기도 수원시 장안구' },
    '수원시 권선구' => { lat: 37.2398, lng: 126.9729, full_name: '경기도 수원시 권선구' },

    # 성남시 (3개 구)
    '성남시 분당구' => { lat: 37.3636, lng: 127.1286, full_name: '경기도 성남시 분당구' },
    '성남시 수정구' => { lat: 37.4503, lng: 127.1315, full_name: '경기도 성남시 수정구' },
    '성남시 중원구' => { lat: 37.4340, lng: 127.1548, full_name: '경기도 성남시 중원구' },

    # 고양시 (3개 구)
    '고양시 덕양구' => { lat: 37.6359, lng: 126.8327, full_name: '경기도 고양시 덕양구' },
    '고양시 일산동구' => { lat: 37.6581, lng: 126.7733, full_name: '경기도 고양시 일산동구' },
    '고양시 일산서구' => { lat: 37.6694, lng: 126.7562, full_name: '경기도 고양시 일산서구' },

    # 용인시 (3개 구)
    '용인시 기흥구' => { lat: 37.2758, lng: 127.1175, full_name: '경기도 용인시 기흥구' },
    '용인시 수지구' => { lat: 37.3243, lng: 127.0984, full_name: '경기도 용인시 수지구' },
    '용인시 처인구' => { lat: 37.2349, lng: 127.2020, full_name: '경기도 용인시 처인구' },

    # 안산시 (2개 구)
    '안산시 상록구' => { lat: 37.2968, lng: 126.8308, full_name: '경기도 안산시 상록구' },
    '안산시 단원구' => { lat: 37.3169, lng: 126.7925, full_name: '경기도 안산시 단원구' },

    # 안양시 (2개 구)
    '안양시 만안구' => { lat: 37.3895, lng: 126.9504, full_name: '경기도 안양시 만안구' },
    '안양시 동안구' => { lat: 37.3916, lng: 126.9568, full_name: '경기도 안양시 동안구' },

    # 단일 구조 시/군들
    '부천시' => { lat: 37.5036, lng: 126.7660, full_name: '경기도 부천시' },
    '남양주시' => { lat: 37.6369, lng: 127.2165, full_name: '경기도 남양주시' },
    '화성시' => { lat: 37.1996, lng: 126.8312, full_name: '경기도 화성시' },
    '평택시' => { lat: 36.9923, lng: 127.1127, full_name: '경기도 평택시' },
    '의정부시' => { lat: 37.7380, lng: 127.0337, full_name: '경기도 의정부시' },
    '시흥시' => { lat: 37.3800, lng: 126.8028, full_name: '경기도 시흥시' },
    '파주시' => { lat: 37.7598, lng: 126.7800, full_name: '경기도 파주시' },
    '김포시' => { lat: 37.6158, lng: 126.7160, full_name: '경기도 김포시' },
    '광명시' => { lat: 37.4786, lng: 126.8644, full_name: '경기도 광명시' },
    '광주시' => { lat: 37.4296, lng: 127.2550, full_name: '경기도 광주시' },
    '군포시' => { lat: 37.3617, lng: 126.9352, full_name: '경기도 군포시' },
    '하남시' => { lat: 37.5395, lng: 127.2146, full_name: '경기도 하남시' },
    '오산시' => { lat: 37.1498, lng: 127.0772, full_name: '경기도 오산시' },
    '이천시' => { lat: 37.2723, lng: 127.4347, full_name: '경기도 이천시' }
  }.freeze

  # 개발용 작은 범위 (테스트용)
  DEV_SEOUL = ['강남구', '서초구'].freeze
  DEV_GYEONGGI = ['수원시 영통구', '성남시 분당구'].freeze

  def self.crawl_seoul_properties(dev_mode: false)
    areas = dev_mode ? DEV_SEOUL : SEOUL_DISTRICTS.keys
    new.crawl_region_properties('서울', SEOUL_DISTRICTS, areas)
  end

  def self.crawl_gyeonggi_properties(dev_mode: false)
    areas = dev_mode ? DEV_GYEONGGI : GYEONGGI_DISTRICTS.keys
    new.crawl_region_properties('경기도', GYEONGGI_DISTRICTS, areas)
  end

  def crawl_region_properties(region_name, coordinates_map, areas)
    Rails.logger.info "=== #{region_name} 매물 크롤링 시작 (#{areas.size}개 지역) ==="

    total_collected = []
    collection_stats = {
      region: region_name,
      total_areas: areas.size,
      completed_areas: 0,
      property_stats: {},
      start_time: Time.current
    }

    areas.each_with_index do |area, index|
      Rails.logger.info "📍 #{area} 크롤링 시작 (#{index + 1}/#{areas.size})"

      begin
        area_properties = crawl_area_properties_with_tor(area, region_name, coordinates_map[area])
        deduplicated_properties = remove_duplicates(area_properties)
        saved_properties = save_properties_with_deduplication(deduplicated_properties)

        # 판매완료 매물 처리
        remove_sold_properties(area, saved_properties)

        total_collected.concat(saved_properties)
        collection_stats[:completed_areas] += 1

        # 구별 통계 로깅
        area_stats = calculate_area_stats(saved_properties)
        collection_stats[:property_stats][area] = area_stats
        Rails.logger.info "✅ #{area} 완료: 총 #{saved_properties.size}개 매물 저장"

        sleep(rand(3..7)) # 지역간 대기

      rescue => e
        Rails.logger.error "❌ #{area} 크롤링 실패: #{e.message}"
        next
      end
    end

    collection_stats[:end_time] = Time.current
    collection_stats[:total_collected] = total_collected.size
    log_region_completion(collection_stats)

    total_collected
  end

  private

  def crawl_area_properties_with_tor(area, region, coordinates_data)
    all_properties = []
    ip_check_count = 0
    coordinates = { lat: coordinates_data[:lat], lng: coordinates_data[:lng] }
    full_name = coordinates_data[:full_name]

    # 매물 타입별로 각각 다른 Tor 세션 사용
    %w[oneroom officetel apartment].each do |property_type|
      driver = setup_tor_driver
      begin
        check_ip_change(driver, ip_check_count += 1)
        # 아파트를 제외한 매물 타입만 로그 출력
        if property_type != 'apartment'
          Rails.logger.info "🏠 #{area} #{property_type} 수집 시작"
        end

        properties = collect_property_type_for_area(driver, area, property_type, region, coordinates, full_name)
        all_properties.concat(properties)

        if property_type != 'apartment'
          Rails.logger.info "✅ #{area} #{property_type} 최종 #{properties.size}개 수집"
        end
        sleep(rand(2..4))
      ensure
        driver&.quit
      end

      sleep(3) # 매물 타입간 대기
    end

    all_properties
  end

  def collect_property_type_for_area(driver, area, property_type, region, coordinates, full_name)
    # 직방 매물 타입별 페이지로 이동
    url = "https://www.zigbang.com/home/#{property_type}/map"
    driver.get(url)
    sleep(5)

    # 지역 검색 및 자동완성 선택 (무조건 성공하도록 개선)
    search_success = search_and_select_area_enhanced(driver, area, region, full_name)

    if search_success
      sleep(5)

      # 우측 상단 매물 개수 확인 (아파트 제외한 매물만 로그)
      total_count = get_total_property_count(driver, area, property_type)

      properties = collect_sidebar_infinite_scroll(driver, property_type, area, region, coordinates, total_count)
    else
      properties = []
    end

    properties
  end

  def search_and_select_area_enhanced(driver, area, region, full_name)
    search_strategies = [
      full_name,           # "서울특별시 강남구" 또는 "경기도 수원시 영통구"
      area,               # "강남구" 또는 "수원시 영통구"
      area.split(' ').last, # "강남구" 또는 "영통구"
      "#{region} #{area}"  # "서울 강남구" 또는 "경기도 수원시 영통구"
    ].uniq

    search_strategies.each_with_index do |search_term, index|
      if try_search_with_long_wait(driver, search_term, area, region)
        return true
      end
      sleep(2)
    end

    false
  end

  def try_search_with_long_wait(driver, search_term, area, region)
    begin
      search_selectors = [
        'input[placeholder*="검색"]',
        'input[placeholder*="지역"]',
        'input[type="text"]',
        '.search-input input',
        '#search-input'
      ]

      search_input = nil
      search_selectors.each do |selector|
        begin
          search_input = driver.find_element(:css, selector)
          break if search_input&.displayed?
        rescue
          next
        end
      end

      return false unless search_input

      search_input.click
      search_input.send_keys([:control, 'a'])
      search_input.send_keys(:backspace)
      search_input.send_keys(search_term)

      sleep(10)
      return find_and_select_autocomplete_persistent(driver, search_term, area, region)

    rescue => e
      return false
    end
  end

  def try_search_with_term(driver, search_term, area, region)
    begin
      search_selectors = [
        'input[placeholder*="검색"]',
        'input[placeholder*="지역"]',
        'input[type="text"]',
        '.search-input input',
        '#search-input'
      ]

      search_input = nil
      search_selectors.each do |selector|
        begin
          search_input = driver.find_element(:css, selector)
          break if search_input&.displayed?
        rescue
          next
        end
      end

      return false unless search_input

      search_input.click
      search_input.send_keys([:control, 'a'])
      search_input.send_keys(:backspace)
      search_input.send_keys(search_term)
      sleep(5)

      3.times do |attempt|
        if find_and_select_autocomplete(driver, search_term, area, region)
          return true
        end
        sleep(2) if attempt < 2
      end

      false

    rescue => e
      return false
    end
  end

  def find_and_select_autocomplete_persistent(driver, search_term, area, region)
    # 끈질기게 자동완성 찾기 (최대 5번 시도)
    5.times do |attempt|
      # 자동완성 선택자들 (더 포괄적으로)
      autocomplete_selectors = [
        'ul li', '[role="option"]', '.suggestion-item', '.autocomplete-item',
        '[class*="auto"] li', '[class*="suggest"] li', '[class*="dropdown"] li',
        '[class*="list"] div', '[data-testid*="suggest"]', '.search-result-item',
        'li', 'div[class*="item"]'
      ]

      autocomplete_selectors.each do |selector|
        begin
          options = driver.find_elements(:css, selector)

          options.each do |option|
            text = option.text.strip
            next if text.empty?

            # 매칭 조건들 (우선순위 순)
            if match_autocomplete_option?(text, search_term, area, region)
              # 클릭 시도
              begin
                option.click
                sleep(3)
                return true
              rescue => e
                begin
                  driver.execute_script("arguments[0].click();", option)
                  sleep(3)
                  return true
                rescue => js_e
                  next
                end
              end
            end
          end
        rescue => e
          next
        end
      end

      # 각 시도 사이에 대기
      sleep(3) if attempt < 4
    end

    false
  end

  def find_and_select_autocomplete(driver, search_term, area, region)
    # 자동완성 선택자들 (더 포괄적으로)
    autocomplete_selectors = [
      'ul li',
      '[role="option"]',
      '.suggestion-item',
      '.autocomplete-item',
      '[class*="auto"] li',
      '[class*="suggest"] li',
      '[class*="dropdown"] li',
      '[class*="list"] div',
      '[data-testid*="suggest"]',
      '.search-result-item'
    ]

    autocomplete_selectors.each do |selector|
      begin
        options = driver.find_elements(:css, selector)

        options.each do |option|
          text = option.text.strip
          next if text.empty?

          # 매칭 조건들 (우선순위 순)
          if match_autocomplete_option?(text, search_term, area, region)
            Rails.logger.debug "    ✅ 자동완성 선택: '#{text}'"

            # 클릭 시도
            begin
              option.click
              sleep(2)
              return true
            rescue => e
              Rails.logger.debug "    클릭 실패, JavaScript 클릭 시도: #{e.message}"
              driver.execute_script("arguments[0].click();", option)
              sleep(2)
              return true
            end
          end
        end
      rescue => e
        Rails.logger.debug "    선택자 #{selector} 시도 실패: #{e.message}"
        next
      end
    end

    false
  end

  def match_autocomplete_option?(text, search_term, area, region)
    text_lower = text.downcase
    search_lower = search_term.downcase
    area_lower = area.downcase
    region_lower = region.downcase

    # 정확한 매치 (최우선)
    return true if text_lower.include?(search_lower)

    # 지역명 포함 (두 번째 우선순위)
    return true if text_lower.include?(area_lower) && text_lower.include?(region_lower)

    # 지역명만 포함 (세 번째 우선순위)
    return true if text_lower.include?(area_lower) && !text_lower.include?('역') && !text_lower.include?('로') && !text_lower.include?('동')

    # 구 단위 매치 (수원시 영통구 -> 영통구)
    if area.include?(' ')
      last_part = area.split(' ').last.downcase
      return true if text_lower.include?(last_part) && !text_lower.include?('역')
    end

    false
  end

  def search_and_select_area(driver, area, region)
    begin
      Rails.logger.debug "    🔍 #{area} 지역 검색 시도"

      # 검색창 찾기
      search_input = driver.find_element(:css, 'input[placeholder*="검색"]')
      search_input.clear
      search_input.send_keys(area)
      sleep(2)

      # 자동완성 목록 대기
      Rails.logger.debug "    ⏳ 자동완성 목록 대기 중"

      # 자동완성 목록에서 적절한 항목 찾기
      autocomplete_selectors = [
        '[class*="auto"]',
        '[class*="suggest"]',
        '[class*="dropdown"]',
        '[class*="list"]',
        'ul li',
        '[role="option"]'
      ]

      selected = false
      autocomplete_selectors.each do |selector|
        begin
          options = driver.find_elements(:css, selector)

          options.each do |option|
            text = option.text.strip

            # 지역명과 매칭되는 항목 찾기
            if text.include?(region) && text.include?(area)
              Rails.logger.debug "    ✅ 자동완성에서 선택: #{text}"
              option.click
              selected = true
              break
            elsif text.include?(area) && !text.include?('역') && !text.include?('로')
              # "강남구" 포함하고 역명이 아닌 경우
              Rails.logger.debug "    ✅ 자동완성에서 선택: #{text}"
              option.click
              selected = true
              break
            end
          end

          break if selected
        rescue => e
          Rails.logger.debug "    선택자 #{selector} 시도 실패: #{e.message}"
          next
        end
      end

      if !selected
        # 자동완성 선택 실패시 엔터로 검색
        Rails.logger.debug "    ⌨️  자동완성 선택 실패, 엔터로 검색"
        search_input.send_keys(:enter)
        sleep(3)
        selected = true
      end

      selected
    rescue => e
      Rails.logger.debug "    ❌ 지역 검색 실패: #{e.message}"
      false
    end
  end

  def get_total_property_count(driver, area, property_type)
    # 끈질기게 총 매물 수 찾기 (10번 시도, 각 2초씩 대기)
    10.times do |attempt|
      Rails.logger.debug "    📊 매물 수 확인 시도 #{attempt + 1}/10"

      count_selectors = [
        # 더 포괄적인 선택자들
        '*[class*="count"]',
        '*[class*="total"]',
        '*[class*="목록"]',
        'span:contains("개")',
        'div:contains("개")',
        'p:contains("개")',
        'h1:contains("개")',
        'h2:contains("개")',
        'h3:contains("개")',
        '.sidebar *:contains("개")',
        '[class*="list"] *:contains("개")',
        '[class*="result"] *:contains("개")'
      ]

      count_selectors.each do |selector|
        begin
          elements = driver.find_elements(:css, selector)
          elements.each do |element|
            text = element.text.strip
            next if text.empty?

            # "지역 목록 1,282개", "총 1,500개", "매물 501개" 등 다양한 형태 매칭
            if text.match(/(\d{1,3}(?:,\d{3})*)\s*개/)
              count_matches = text.scan(/(\d{1,3}(?:,\d{3})*)\s*개/)
              count_matches.each do |match|
                count_str = match.first
                formatted_count = count_str.gsub(',', '').to_i

                # 너무 작은 숫자는 제외 (최소 10개 이상)
                if formatted_count >= 10
                  Rails.logger.info "    📊 #{area} #{property_type} 총 매물 수 발견: #{count_str}개 (텍스트: '#{text}')"
                  return formatted_count
                end
              end
            end
          end
        rescue => e
          Rails.logger.debug "    선택자 '#{selector}' 시도 실패: #{e.message}"
          next
        end
      end

      # 매 시도마다 2초 대기
      if attempt < 9
        sleep(2)
      end
    end

    nil
  end

  def collect_sidebar_infinite_scroll(driver, property_type, area, region, coordinates, expected_count = nil)
    properties = []
    last_count = 0
    stable_count = 0
    max_scroll_attempts = 100  # 많은 매물을 위해 증가

    # 사이드바 스크롤 컨테이너 찾기
    sidebar_selectors = [
      '.sidebar',
      '[class*="sidebar"]',
      '[class*="list"]',
      '.property-list',
      '#property-list'
    ]

    scroll_container = nil
    sidebar_selectors.each do |selector|
      begin
        scroll_container = driver.find_element(:css, selector)
        if scroll_container&.displayed?
          Rails.logger.debug "    스크롤 컨테이너 발견: #{selector}"
          break
        end
      rescue
        next
      end
    end

    max_scroll_attempts.times do |i|
      # 현재 매물 카드들 수집
      current_properties = extract_current_properties(driver, property_type, properties.size, area, region, coordinates)
      properties.concat(current_properties)

      Rails.logger.info "스크롤 #{i + 1}: 현재 #{properties.size}개 수집" if i % 10 == 0

      # 매물 수가 안정되면 중단 (더 관대한 조건)
      if properties.size == last_count
        stable_count += 1

        # 예상 개수의 99% 이상 수집했으면 성공으로 간주
        if expected_count && properties.size >= (expected_count * 0.99).to_i
          break
        end

        if stable_count >= 12  # 12번 연속 동일해야 중단 (더 관대하게)
          break
        end
      else
        stable_count = 0
      end

      last_count = properties.size

      # 스크롤 다운
      if scroll_container
        driver.execute_script("arguments[0].scrollTop = arguments[0].scrollHeight;", scroll_container)
      else
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
      end

      sleep(3)  # 더 긴 대기 시간
      wait_for_loading(driver)
    end

    # 수집 완료 로그
    if expected_count
      collection_rate = (properties.size.to_f / expected_count * 100).round(1)
      Rails.logger.info "✅ 최종 수집: #{properties.size}/#{expected_count}개 (#{collection_rate}%)"
    else
      Rails.logger.info "✅ 수집 완료: #{properties.size}개"
    end

    properties
  end

  def extract_current_properties(driver, property_type, current_count, area, region, coordinates)
    property_cards = find_property_cards(driver)
    new_properties = []

    property_cards.each_with_index do |card, index|
      next if index < current_count # 이미 처리된 카드는 스킵

      property_data = extract_card_data_with_location(card, current_count + new_properties.size, property_type, area, region, coordinates)
      new_properties << property_data if property_data
    end

    new_properties
  end

  def extract_card_data_with_location(card, index, property_type, area, region, coordinates)
    begin
      text = card.text.strip

      # 실제 매물 정보 추출
      price = extract_price(text)
      area_desc = extract_area(text)
      floor = extract_floor(text)

      return nil if price == "정보없음" && area_desc == "정보없음" && floor == "정보없음"

      # 직방 URL 추출
      zigbang_url = extract_zigbang_url(card)

      external_id = "zigbang_#{region}_#{area}_#{property_type}_#{Time.current.to_i}_#{index}"

      {
        title: "#{region} #{area} #{property_type} #{index + 1}",
        address: "#{region} #{area}",
        price: price,
        property_type: map_property_type(property_type),
        deal_type: determine_deal_type(price),
        area_description: area_desc,
        area_sqm: extract_area_sqm(text),
        floor_description: floor,
        current_floor: extract_current_floor(text),
        total_floors: extract_total_floors(text),
        room_structure: extract_room_structure(text),
        maintenance_fee: extract_maintenance_fee(text),
        zigbang_url: zigbang_url,
        latitude: coordinates[:lat] + (rand(-50..50) * 0.0001),
        longitude: coordinates[:lng] + (rand(-50..50) * 0.0001),
        external_id: external_id,
        description: "#{region} #{area}에서 수집된 #{property_type} 매물",
        raw_data: {
          original_text: text[0..500],
          property_type: property_type,
          area: area,
          region: region,
          coordinates: coordinates,
          collected_at: Time.current
        }.to_json
      }
    rescue => e
      Rails.logger.error "    매물 #{index} 추출 실패: #{e.message}"
      nil
    end
  end

  def remove_duplicates(properties)
    unique_properties = properties.uniq { |prop| prop[:external_id] }
    removed_count = properties.size - unique_properties.size
    Rails.logger.info "  🔄 중복 매물 #{removed_count}개 제거" if removed_count > 0
    unique_properties
  end

  def save_properties_with_deduplication(properties)
    saved_properties = []

    properties.each do |property_data|
      existing = Property.find_by(external_id: property_data[:external_id])

      if existing
        existing.update!(property_data.except(:external_id))
        saved_properties << existing
      else
        new_property = Property.create!(property_data)
        saved_properties << new_property
      end
    end

    saved_properties
  end

  def remove_sold_properties(area, current_properties)
    current_external_ids = current_properties.map(&:external_id)
    existing_properties = Property.where("address LIKE ?", "%#{area}%")
    sold_properties = existing_properties.where.not(external_id: current_external_ids)

    if sold_properties.any?
      sold_properties.destroy_all
      Rails.logger.info "  🗑️  #{area} 판매완료 매물 #{sold_properties.size}개 삭제"
    end
  end

  def calculate_area_stats(properties)
    {
      total: properties.size,
      by_type: properties.group_by(&:property_type).transform_values(&:count),
      by_deal_type: properties.group_by(&:deal_type).transform_values(&:count)
    }
  end

  def log_area_completion(area, stats)
    Rails.logger.info "✅ #{area} 완료: 총 #{stats[:total]}개"
    stats[:by_type].each do |type, count|
      Rails.logger.info "   - #{type}: #{count}개"
    end
  end

  def log_region_completion(stats)
    duration = ((stats[:end_time] - stats[:start_time]) / 60).round(1)

    Rails.logger.info "🎉 === #{stats[:region]} 크롤링 완료 ==="
    Rails.logger.info "   소요시간: #{duration}분"
    Rails.logger.info "   완료 지역: #{stats[:completed_areas]}/#{stats[:total_areas]}"
    Rails.logger.info "   총 수집: #{stats[:total_collected]}개 매물"

    total_by_type = {}
    stats[:property_stats].each do |area, area_stats|
      area_stats[:by_type].each do |type, count|
        total_by_type[type] = (total_by_type[type] || 0) + count
      end
    end

    Rails.logger.info "   매물 타입별:"
    total_by_type.each do |type, count|
      Rails.logger.info "     - #{type}: #{count}개"
    end
  end

  # 개발용 Chrome + Tor 프록시 설정
  def setup_tor_driver
    Rails.logger.debug "🔧 개발용 Chrome + Tor 프록시 설정"

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--proxy-server=socks5://#{TOR_PROXY[:host]}:#{TOR_PROXY[:port]}")
    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebDriver/537.36')
    options.add_argument('--disable-extensions')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-web-security')

    # 개발용이므로 headless 모드는 사용하지 않음 (브라우저 창 볼 수 있게)
    # options.add_argument('--headless')

    driver = Selenium::WebDriver.for :chrome, options: options
    driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")

    Rails.logger.debug "✅ Chrome + Tor 프록시 실행 성공"
    driver
  end

  def check_ip_change(driver, count)
    begin
      driver.get('https://httpbin.org/ip')
      sleep(2)
      ip_info = driver.find_element(:css, 'pre').text
      current_ip = JSON.parse(ip_info)['origin']
      Rails.logger.debug "IP 확인 #{count}: #{current_ip}"

      @last_ip ||= current_ip
      if @last_ip != current_ip
        Rails.logger.info "🔄 IP 변경 감지: #{@last_ip} → #{current_ip}"
        @last_ip = current_ip
      end
    rescue => e
      Rails.logger.debug "IP 확인 실패: #{e.message}"
    end
  end

  def find_property_cards(driver)
    card_selectors = [
      '[class*="property-item"]',
      '[class*="room-item"]',
      '[class*="list-item"]',
      '.card',
      'article',
      '[role="listitem"]'
    ]

    card_selectors.each do |selector|
      begin
        cards = driver.find_elements(:css, selector)
        valid_cards = cards.select { |card| looks_like_property?(card) }
        if valid_cards.any?
          Rails.logger.debug "    #{selector}에서 #{valid_cards.size}개 매물 카드 발견"
          return valid_cards
        end
      rescue
        next
      end
    end

    # 휴리스틱 방식
    all_divs = driver.find_elements(:css, 'div')
    all_divs.select { |div| looks_like_property?(div) }
  end

  def looks_like_property?(element)
    begin
      text = element.text.strip
      return false if text.length < 10 || text.length > 800

      has_price = text.match?(/\d+만원?|\d+\/\d+|\d+억/)
      has_area = text.match?(/\d+㎡|\d+평/)
      has_floor = text.match?(/\d+층/)
      has_room_type = text.match?(/원룸|투룸|오피스텔|아파트/)

      ui_keywords = ['검색', '필터', '로그인', '메뉴', '지도', '학교', '병원', '역']
      is_ui = ui_keywords.any? { |kw| text.include?(kw) }

      (has_price || has_area || has_floor || has_room_type) && !is_ui
    rescue
      false
    end
  end

  def extract_zigbang_url(card)
    begin
      link = card.find_element(:css, 'a')
      href = link.attribute('href')

      if href&.include?('zigbang.com')
        href
      else
        data_url = card.attribute('data-url') || card.attribute('data-link')
        data_url&.include?('zigbang.com') ? data_url : nil
      end
    rescue
      nil
    end
  end

  def wait_for_loading(driver)
    5.times do
      loading_elements = driver.find_elements(:css, '.loading, [class*="loading"], [class*="spinner"]')
      break if loading_elements.empty?
      sleep(1)
    end
  end

  # 데이터 추출 메서드들 (ZigbangTorCrawler에서 복사)
  def extract_price(text)
    return text.match(/(\d+)억/)[1] + "억" if text.match?(/\d+억/)
    return text.match(/(\d+)만원?/)[1] + "만원" if text.match?(/\d+만원?/)
    return text.match(/(\d+\/\d+)/)[1] if text.match?(/\d+\/\d+/)
    "정보없음"
  end

  def extract_area(text)
    return text.match(/([\d\.]+)㎡/)[1] + "㎡" if text.match?(/[\d\.]+㎡/)
    return text.match(/([\d\.]+)평/)[1] + "평" if text.match?(/[\d\.]+평/)
    "정보없음"
  end

  def extract_floor(text)
    return text.match(/(\d+)층/)[1] + "층" if text.match?(/\d+층/)
    return text.match(/(\d+\/\d+)층/)[1] + "층" if text.match?(/\d+\/\d+층/)
    "정보없음"
  end

  def extract_area_sqm(text)
    text.match(/([\d\.]+)㎡/) ? text.match(/([\d\.]+)㎡/)[1].to_f : nil
  end

  def extract_current_floor(text)
    if text.match?(/(\d+)\/(\d+)층/)
      text.match(/(\d+)\/(\d+)층/)[1].to_i
    elsif text.match?(/(\d+)층/)
      text.match(/(\d+)층/)[1].to_i
    else
      nil
    end
  end

  def extract_total_floors(text)
    text.match?(/(\d+)\/(\d+)층/) ? text.match(/(\d+)\/(\d+)층/)[2].to_i : nil
  end

  def extract_room_structure(text)
    room_patterns = [
      /쓰리룸[^\s]*/,
      /투룸[^\s]*/,
      /원룸[^\s]*/,
      /분리형[^\s]*/,
      /복층형[^\s]*/,
      /오픈형[^\s]*/,
      /방\d+[^\s]*/
    ]

    room_patterns.each do |pattern|
      match = text.match(pattern)
      return match[0] if match
    end

    nil
  end

  def extract_maintenance_fee(text)
    if text.match?(/관리비[\s:]*(\d+만원?)/)
      text.match(/관리비[\s:]*(\d+만원?)/)[1]
    elsif text.match?(/(\d+만원?).*관리비/)
      text.match(/(\d+만원?).*관리비/)[1]
    else
      nil
    end
  end

  def determine_deal_type(price)
    return 'monthly_rent' if price.include?('/')
    return 'jeonse' if price.include?('전세')
    'sale'
  end

  def map_property_type(type)
    case type
    when 'oneroom' then 'villa'
    when 'officetel' then 'officetel'
    when 'apartment' then 'apartment'
    else 'villa'
    end
  end
end