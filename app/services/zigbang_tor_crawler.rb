require 'selenium-webdriver'
require 'net/http'

class ZigbangTorCrawler
  TOR_PROXY = {
    host: '127.0.0.1',
    port: 9050,  # SOCKS5 프록시 포트
    type: :socks
  }.freeze

  def self.collect_all_properties(area_name = '수지구')
    crawler = new
    crawler.collect_comprehensive_properties
  end

  def collect_comprehensive_properties
    Rails.logger.info "=== Tor 프록시 기반 대량 매물 수집 시작 ==="

    all_properties = []
    ip_check_count = 0

    # 1. 원룸 (가장 많은 매물)
    driver = setup_tor_driver
    begin
      check_ip_change(driver, ip_check_count += 1)
      properties = collect_oneroom_properties(driver)
      all_properties.concat(properties)
      Rails.logger.info "원룸 수집 완료: #{properties.size}개"
    ensure
      driver&.quit
    end

    sleep(5) # IP 변경 대기

    # 2. 오피스텔
    driver = setup_tor_driver
    begin
      check_ip_change(driver, ip_check_count += 1)
      properties = collect_officetel_properties(driver)
      all_properties.concat(properties)
      Rails.logger.info "오피스텔 수집 완료: #{properties.size}개"
    ensure
      driver&.quit
    end

    sleep(5) # IP 변경 대기

    # 3. 아파트 (동별 수집)
    driver = setup_tor_driver
    begin
      check_ip_change(driver, ip_check_count += 1)
      properties = collect_apartment_properties(driver)
      all_properties.concat(properties)
      Rails.logger.info "아파트 수집 완료: #{properties.size}개"
    ensure
      driver&.quit
    end

    Rails.logger.info "=== 전체 수집 완료: #{all_properties.size}개 매물 ==="
    all_properties
  end

  private

  def setup_tor_driver
    options = Selenium::WebDriver::Chrome::Options.new

    # Tor SOCKS5 프록시 설정
    options.add_argument("--proxy-server=socks5://#{TOR_PROXY[:host]}:#{TOR_PROXY[:port]}")
    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')

    # 추가 봇 탐지 방지
    options.add_argument('--disable-extensions')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-web-security')

    driver = Selenium::WebDriver.for :chrome, options: options
    driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")

    Rails.logger.info "Tor 프록시 브라우저 시작 완료"
    driver
  end

  def check_ip_change(driver, count)
    begin
      driver.get('https://httpbin.org/ip')
      sleep(2)
      ip_info = driver.find_element(:css, 'pre').text
      current_ip = JSON.parse(ip_info)['origin']
      Rails.logger.info "IP 확인 #{count}: #{current_ip}"

      @last_ip ||= current_ip
      if @last_ip != current_ip
        Rails.logger.info "🔄 IP 변경 감지: #{@last_ip} → #{current_ip}"
        @last_ip = current_ip
      end
    rescue => e
      Rails.logger.debug "IP 확인 실패: #{e.message}"
    end
  end

  # 원룸 무한 스크롤 수집
  def collect_oneroom_properties(driver)
    Rails.logger.info "=== 원룸 무한 스크롤 수집 시작 ==="

    driver.get('https://www.zigbang.com/home/oneroom/map?lat=37.3257&lng=127.1041&zoom=15')
    sleep(8)

    properties = []

    # 사이드바에서 무한 스크롤로 매물 수집
    sidebar_properties = collect_sidebar_infinite_scroll(driver, 'oneroom')
    properties.concat(sidebar_properties)

    properties
  end

  # 오피스텔 수집
  def collect_officetel_properties(driver)
    Rails.logger.info "=== 오피스텔 수집 시작 ==="

    driver.get('https://www.zigbang.com/home/officetel/map?lat=37.3257&lng=127.1041&zoom=15')
    sleep(8)

    properties = []

    # 사이드바에서 무한 스크롤로 매물 수집
    sidebar_properties = collect_sidebar_infinite_scroll(driver, 'officetel')
    properties.concat(sidebar_properties)

    properties
  end

  # 아파트 동별 수집
  def collect_apartment_properties(driver)
    Rails.logger.info "=== 아파트 동별 수집 시작 ==="

    driver.get('https://www.zigbang.com/home/apt/map?lat=37.3257&lng=127.1041&zoom=15')
    sleep(8)

    properties = []

    # 지도에서 주황색 동 버튼들 찾기
    dong_buttons = find_dong_buttons(driver)
    Rails.logger.info "발견된 동 버튼: #{dong_buttons.size}개"

    dong_buttons.each_with_index do |button, index|
      begin
        Rails.logger.info "동 버튼 #{index + 1} 클릭 시도"

        # 동 버튼 클릭
        driver.action.move_to(button).click.perform
        sleep(3)

        # "ㅇㅇ동 주변 매물보기" 버튼 찾아서 클릭
        nearby_button = find_nearby_properties_button(driver)
        if nearby_button
          nearby_button.click
          sleep(5)

          # 해당 동의 매물들 수집
          dong_properties = collect_sidebar_infinite_scroll(driver, 'apartment')
          properties.concat(dong_properties)

          Rails.logger.info "동 #{index + 1} 수집 완료: #{dong_properties.size}개 매물"
        end

        # 다음 동으로 이동하기 위해 지도 클릭
        driver.action.move_to_location(500, 400).click.perform
        sleep(2)

      rescue => e
        Rails.logger.error "동 #{index + 1} 수집 실패: #{e.message}"
        next
      end
    end

    properties
  end

  # 사이드바 무한 스크롤 매물 수집
  def collect_sidebar_infinite_scroll(driver, property_type)
    Rails.logger.info "=== 사이드바 무한 스크롤 수집 (#{property_type}) ==="

    properties = []
    last_count = 0
    stable_count = 0
    max_scroll_attempts = 50

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
          Rails.logger.info "스크롤 컨테이너 발견: #{selector}"
          break
        end
      rescue
        next
      end
    end

    max_scroll_attempts.times do |i|
      # 현재 매물 카드들 수집
      current_properties = extract_current_properties(driver, property_type, properties.size)
      properties.concat(current_properties)

      Rails.logger.info "스크롤 #{i + 1}: 현재까지 #{properties.size}개 매물"

      # 매물 수가 안정되면 중단
      if properties.size == last_count
        stable_count += 1
        if stable_count >= 3
          Rails.logger.info "더 이상 새로운 매물이 없어 스크롤 중단"
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
        # 전체 페이지 스크롤
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
      end

      sleep(2)

      # 로딩 대기
      wait_for_loading(driver)
    end

    Rails.logger.info "무한 스크롤 완료: 총 #{properties.size}개 매물 수집"
    properties
  end

  def find_dong_buttons(driver)
    # 아파트 지도의 주황색 동 버튼들 찾기
    dong_selectors = [
      '[class*="marker"]',
      '[class*="dong"]',
      'button[class*="orange"]',
      '.map-marker',
      '[style*="orange"]'
    ]

    dong_buttons = []
    dong_selectors.each do |selector|
      begin
        buttons = driver.find_elements(:css, selector)
        buttons.each do |button|
          text = button.text.strip rescue ""
          if text.match?(/\w+동/) && button.displayed?
            dong_buttons << button
            Rails.logger.info "동 버튼 발견: #{text}"
          end
        end
      rescue
        next
      end
    end

    dong_buttons.uniq.first(10) # 최대 10개 동
  end

  def find_nearby_properties_button(driver)
    # "ㅇㅇ동 주변 매물보기" 버튼 찾기
    button_texts = ['주변 매물보기', '매물보기', '매물 보기']

    button_texts.each do |text|
      begin
        button = driver.find_element(:xpath, "//button[contains(text(), '#{text}')]")
        if button&.displayed?
          Rails.logger.info "매물보기 버튼 발견: #{button.text}"
          return button
        end
      rescue
        next
      end
    end

    nil
  end

  def extract_current_properties(driver, property_type, current_count)
    # 현재 페이지의 새로운 매물들만 추출
    property_cards = find_property_cards(driver)
    new_properties = []

    property_cards.each_with_index do |card, index|
      next if index < current_count # 이미 처리된 카드는 스킵

      property = extract_card_data(card, current_count + new_properties.size, property_type)
      new_properties << property if property
    end

    new_properties
  end

  def find_property_cards(driver)
    # 사이드바의 매물 카드들 찾기
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
          Rails.logger.debug "#{selector}에서 #{valid_cards.size}개 매물 카드 발견"
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

      # 매물 정보 패턴 확인
      has_price = text.match?(/\d+만원?|\d+\/\d+|\d+억/)
      has_area = text.match?(/\d+㎡|\d+평/)
      has_floor = text.match?(/\d+층/)
      has_room_type = text.match?(/원룸|투룸|오피스텔|아파트/)

      # UI 요소 제외
      ui_keywords = ['검색', '필터', '로그인', '메뉴', '지도', '학교', '병원', '역']
      is_ui = ui_keywords.any? { |kw| text.include?(kw) }

      (has_price || has_area || has_floor || has_room_type) && !is_ui
    rescue
      false
    end
  end

  def extract_card_data(card, index, property_type)
    begin
      text = card.text.strip
      Rails.logger.debug "매물 #{index + 1}: #{text[0..80]}"

      # 실제 매물 정보 추출
      price = extract_price(text)
      area = extract_area(text)
      floor = extract_floor(text)

      return nil if price == "정보없음" && area == "정보없음" && floor == "정보없음"

      external_id = "zigbang_tor_#{property_type}_#{Time.current.to_i}_#{index}"

      Property.create!(
        title: "수지구 #{property_type} #{index + 1}",
        address: extract_address(text) || "경기도 용인시 수지구",
        price: price,
        property_type: map_property_type(property_type),
        deal_type: determine_deal_type(price),
        area_description: area,
        area_sqm: extract_area_sqm(text),
        floor_description: floor,
        current_floor: extract_current_floor(text),
        total_floors: extract_total_floors(text),
        room_structure: extract_room_structure(text),
        maintenance_fee: extract_maintenance_fee(text),
        latitude: 37.3257 + (rand(-50..50) * 0.0001),
        longitude: 127.1041 + (rand(-50..50) * 0.0001),
        external_id: external_id,
        description: "Tor 프록시로 수집된 수지구 #{property_type} 매물",
        raw_data: {
          original_text: text[0..500],
          property_type: property_type,
          collected_at: Time.current
        }.to_json
      )
    rescue => e
      Rails.logger.error "매물 #{index} 추출 실패: #{e.message}"
      nil
    end
  end

  def extract_price(text)
    return text.match(/(\d+)억/)[1] + "억" if text.match?(/\d+억/)
    return text.match(/(\d+)만원?/)[1] + "만원" if text.match?(/\d+만원?/)
    return text.match(/(\d+\/\d+)/)[1] if text.match?(/\d+\/\d+/)
    "정보없음"
  end

  def extract_area(text)
    return text.match(/(\d+\.?\d*)㎡/)[1] + "㎡" if text.match?(/\d+\.?\d*㎡/)
    return text.match(/(\d+\.?\d*)평/)[1] + "평" if text.match?(/\d+\.?\d*평/)
    "정보없음"
  end

  def extract_floor(text)
    return text.match(/(\d+)층/)[1] + "층" if text.match?(/\d+층/)
    return text.match(/(\d+\/\d+)층/)[1] + "층" if text.match?(/\d+\/\d+층/)
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

  def extract_address(text)
    # 구체적인 주소 추출
    if text.match?(/수지구.*?동/)
      text.match(/(수지구.*?동)/)[1]
    elsif text.match?(/\w+동/)
      "수지구 " + text.match(/(\w+동)/)[1]
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

  def wait_for_loading(driver)
    # 로딩 인디케이터 대기
    5.times do
      loading_elements = driver.find_elements(:css, '.loading, [class*="loading"], [class*="spinner"]')
      break if loading_elements.empty?
      sleep(1)
    end
  end
end