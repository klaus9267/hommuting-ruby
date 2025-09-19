require 'selenium-webdriver'

class ZigbangCrawler
  def self.collect_properties(area_name = '수지구')
    crawler = new
    crawler.collect_suji_properties
  end

  def collect_suji_properties
    driver = setup_driver
    properties = []

    begin
      Rails.logger.info "=== 수지구 원룸 크롤링 시작 ==="

      # 1. 직방 원룸 페이지 접속
      driver.get('https://www.zigbang.com/home/oneroom/map')
      sleep(5)
      Rails.logger.info "페이지 로딩 완료: #{driver.title}"

      # 2. 수지구로 이동
      navigate_to_suji(driver)

      # 3. 매물 데이터 수집
      properties = extract_room_cards(driver)

      Rails.logger.info "수집 완료: #{properties.size}개 매물"

    rescue => e
      Rails.logger.error "크롤링 실패: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    ensure
      driver&.quit
    end

    properties
  end

  private

  def setup_driver
    options = Selenium::WebDriver::Chrome::Options.new

    # 실제 브라우저 창 표시 (디버깅용)
    # options.add_argument('--headless')

    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36')

    Selenium::WebDriver.for :chrome, options: options
  end

  def navigate_to_suji(driver)
    Rails.logger.info "=== 수지구 위치로 이동 ==="

    # URL에 직접 좌표 설정
    suji_url = "https://www.zigbang.com/home/oneroom/map?lat=37.3257&lng=127.1041&zoom=15"
    driver.get(suji_url)
    sleep(8)

    Rails.logger.info "수지구 지도 이동 완료"
  end

  def extract_room_cards(driver)
    Rails.logger.info "=== 매물 카드 추출 시작 ==="

    # 페이지 상호작용으로 매물 로딩 유도
    trigger_loading(driver)

    # 다양한 방법으로 매물 카드 찾기
    cards = find_property_cards(driver)

    Rails.logger.info "매물 카드 #{cards.size}개 발견"

    properties = []
    cards.first(5).each_with_index do |card, i|
      property = extract_card_data(card, i)
      properties << property if property
    end

    properties
  end

  def trigger_loading(driver)
    # 지도 줌 조절
    3.times do
      driver.execute_script("window.scrollTo(0, #{rand(100..500)});")
      sleep(1)
    end

    # 클릭 가능한 요소들 시도
    clickable_selectors = [
      '.map-container',
      '#map',
      '[class*="map"]',
      '[class*="room"]',
      '[class*="item"]'
    ]

    clickable_selectors.each do |selector|
      begin
        element = driver.find_element(:css, selector)
        if element&.displayed?
          element.click
          sleep(2)
          Rails.logger.info "#{selector} 클릭 완료"
          break
        end
      rescue
        next
      end
    end
  end

  def find_property_cards(driver)
    # 가능한 매물 카드 선택자들
    card_selectors = [
      '[class*="room-card"]',
      '[class*="item-card"]',
      '[data-testid*="room"]',
      'article',
      '.card',
      '[role="listitem"]'
    ]

    card_selectors.each do |selector|
      begin
        cards = driver.find_elements(:css, selector)
        if cards.any?
          valid_cards = cards.select { |card| looks_like_property?(card) }
          if valid_cards.any?
            Rails.logger.info "#{selector}에서 #{valid_cards.size}개 유효 카드 발견"
            return valid_cards
          end
        end
      rescue
        next
      end
    end

    # 휴리스틱 방식
    Rails.logger.info "휴리스틱 방식으로 매물 카드 탐색"
    all_divs = driver.find_elements(:css, 'div')
    all_divs.select { |div| looks_like_property?(div) }.first(10)
  end

  def looks_like_property?(element)
    begin
      text = element.text.strip
      return false if text.length < 15 || text.length > 500

      # 매물 정보 패턴 확인
      has_price = text.match?(/\d+만원?|\d+\/\d+|\d+억/)
      has_area = text.match?(/\d+㎡|\d+평/)
      has_floor = text.match?(/\d+층/)

      # UI 요소 제외
      ui_keywords = ['검색', '필터', '로그인', '메뉴', '지도', '학교']
      is_ui = ui_keywords.any? { |kw| text.include?(kw) }

      (has_price || has_area || has_floor) && !is_ui
    rescue
      false
    end
  end

  def extract_card_data(card, index)
    begin
      text = card.text.strip
      Rails.logger.info "카드 #{index + 1}: #{text[0..100]}"

      # 간단한 데이터 추출
      price = extract_price(text)
      area = extract_area(text)

      return nil if price == "정보없음" && area == "정보없음"

      external_id = "zigbang_suji_#{Time.current.to_i}_#{index}"

      Property.create!(
        title: "수지구 원룸 #{index + 1}",
        address: "경기도 용인시 수지구",
        price: price,
        property_type: 'villa',  # 원룸을 빌라로 매핑
        deal_type: determine_deal_type(price),
        area_description: area,
        area_sqm: extract_area_sqm(text),
        floor_description: extract_floor(text),
        current_floor: extract_current_floor(text),
        total_floors: extract_total_floors(text),
        room_structure: extract_room_structure(text),
        maintenance_fee: extract_maintenance_fee(text),
        latitude: 37.3257 + (rand(-10..10) * 0.001),
        longitude: 127.1041 + (rand(-10..10) * 0.001),
        external_id: external_id,
        description: "직방에서 직접 수집된 수지구 원룸",
        raw_data: { original_text: text[0..300] }.to_json
      )
    rescue => e
      Rails.logger.error "카드 #{index} 추출 실패: #{e.message}"
      nil
    end
  end

  def extract_price(text)
    return text.match(/(\d+)억/)[1] + "억" if text.match?(/\d+억/)
    return text.match(/(\d+\/\d+)/)[1] if text.match?(/\d+\/\d+/)
    return text.match(/(\d+)만원?/)[1] + "만원" if text.match?(/\d+만원?/)
    "정보없음"
  end

  def extract_area(text)
    return text.match(/(\d+\.?\d*)㎡/)[1] + "㎡" if text.match?(/\d+\.?\d*㎡/)
    return text.match(/(\d+\.?\d*)평/)[1] + "평" if text.match?(/\d+\.?\d*평/)
    "정보없음"
  end

  def extract_floor(text)
    return text.match(/(\d+)층/)[1] + "층" if text.match?(/\d+층/)
    "정보없음"
  end

  # 새로운 필드 추출 메서드들
  def extract_area_sqm(text)
    # 정확한 평방미터 추출 (55.02㎡, 19㎡ 등)
    if text.match?(/([\d\.]+)㎡/)
      text.match(/([\d\.]+)㎡/)[1].to_f
    else
      nil
    end
  end

  def extract_current_floor(text)
    # "3/6층" 형태에서 현재 층 추출
    if text.match?(/(\d+)\/(\d+)층/)
      text.match(/(\d+)\/(\d+)층/)[1].to_i
    elsif text.match?(/(\d+)층/)
      text.match(/(\d+)층/)[1].to_i
    else
      nil
    end
  end

  def extract_total_floors(text)
    # "3/6층" 형태에서 전체 층 추출
    if text.match?(/(\d+)\/(\d+)층/)
      text.match(/(\d+)\/(\d+)층/)[2].to_i
    else
      nil
    end
  end

  def extract_room_structure(text)
    # 방 구조 추출 (쓰리룸(복실 2개), 분리형(방1,거실1), 복층형 등)
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
    # 관리비 추출 (30만원, 12만원 등)
    if text.match?(/관리비[\s:]*([\d]+만원?)/)
      text.match(/관리비[\s:]*([\d]+만원?)/)[1]
    elsif text.match?(/([\d]+만원?).*관리비/)
      text.match(/([\d]+만원?).*관리비/)[1]
    else
      nil
    end
  end

  def determine_deal_type(price)
    return 'monthly_rent' if price.include?('/')
    return 'jeonse' if price.include?('전세')
    'sale'
  end
end