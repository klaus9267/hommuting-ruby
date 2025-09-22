require 'swagger_helper'

# MVP용 간소화된 API 스펙
RSpec.describe 'Properties API', type: :request do
  path '/api/v1/properties' do
    get '매물 목록 조회' do
      tags '매물'
      description '매물 목록을 페이지네이션과 함께 조회합니다. 매물 유형, 거래 유형, 지역 등으로 필터링 가능합니다.'
      produces 'application/json'

      # 헬퍼 사용으로 간소화
      SharedSchemas.property_filter_params.each { |param| parameter param }
      SharedSchemas.pagination_params.each { |param| parameter param }

      # 지역 필터링 (MVP용 최소한)
      parameter name: :lat, in: :query, type: :number, description: '중심 위도'
      parameter name: :lng, in: :query, type: :number, description: '중심 경도'
      parameter name: :radius, in: :query, type: :number, description: '반경 (km)'

      response 200, 'Success' do
        schema '$ref' => '#/components/schemas/PropertyList'
        example 'application/json', :success, {
          properties: [
            {
              id: 1,
              title: "강남구 논현동 빌라",
              address_text: "서울시 강남구 논현동",
              price: "1000/50",
              property_type: "빌라",
              deal_type: "월세",
              area_sqm: 25.5,
              current_floor: 2,
              total_floors: 4,
              room_structure: "원룸",
              maintenance_fee: 50000,
              address: {
                local1: "서울특별시",
                local2: "강남구",
                local3: "논현동",
                full_address: "서울특별시 강남구 논현동"
              },
              property_image: {
                thumbnail_url: "https://example.com/thumb.jpg",
                image_urls: ["https://example.com/img1.jpg"]
              }
            }
          ],
          pagination: {
            current_page: 1,
            per_page: 20,
            total_count: 100
          }
        }
        run_test!
      end

      response 400, 'Bad Request'
      response 500, 'Internal Server Error'
    end
  end

  # MVP 핵심 기능만 간소화
  path '/api/v1/properties/{id}' do
    parameter name: 'id', in: :path, type: :string

    get '매물 상세 조회' do
      tags '매물'
      description '특정 매물의 상세 정보를 조회합니다.'

      response 200, 'Success' do
        schema '$ref' => '#/components/schemas/Property'
        example 'application/json', :success, {
          id: 1,
          title: "강남구 논현동 신축 빌라",
          address_text: "서울시 강남구 논현동 123-45",
          price: "50000/80",
          property_type: "빌라",
          deal_type: "월세",
          area: "33㎡",
          floor: "3층",
          description: "깔끔한 신축 빌라입니다. 교통이 편리하고 주변 상권이 발달했습니다.",
          area_description: "33㎡",
          area_sqm: 33.0,
          floor_description: "3층",
          current_floor: 3,
          total_floors: 4,
          room_structure: "투룸",
          maintenance_fee: 80000,
          latitude: 37.5172,
          longitude: 127.0473,
          source: "zigbang_api",
          address: {
            id: 1,
            local1: "서울특별시",
            local2: "강남구",
            local3: "논현동",
            local4: "123-45",
            short_address: "강남구 논현동",
            full_address: "서울특별시 강남구 논현동 123-45"
          },
          property_image: {
            id: 1,
            thumbnail_url: "https://example.com/thumb.jpg",
            image_urls: [
              "https://example.com/img1.jpg",
              "https://example.com/img2.jpg",
              "https://example.com/img3.jpg"
            ]
          }
        }
        run_test!
      end

      response 404, 'Not Found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/properties/search' do
    get '매물 검색' do
      tags '매물'
      description '제목, 주소, 설명에서 키워드를 검색합니다. 추가 필터링 옵션 사용 가능합니다.'

      parameter name: :q, in: :query, type: :string, required: true, description: '검색어'
      SharedSchemas.property_filter_params.each { |param| parameter param }
      SharedSchemas.pagination_params.each { |param| parameter param }

      response 200, 'Success' do
        schema '$ref' => '#/components/schemas/PropertyList'
        let(:q) { 'test' }
        run_test!
      end

      response 400, 'Bad Request'
      response 500, 'Internal Server Error'
    end
  end

  # MVP용 간단한 통계
  path '/api/v1/properties/stats' do
    get '매물 통계' do
      tags '매물'
      description '전체 매물 통계 정보를 제공합니다. 총 개수, 유형별 분포, 최근 등록 매물 등을 포함합니다.'

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 total: { type: :integer },
                 by_type: { type: :object },
                 recent: { type: :array, items: { '$ref' => '#/components/schemas/Property' } }
               }
        run_test!
      end
    end
  end

  path '/api/v1/properties/by_area' do
    get '지역별 매물 조회' do
      tags '매물'
      description '특정 좌표 중심으로 반경 내의 매물을 조회합니다. 위도, 경도와 반경을 지정하여 해당 지역의 매물을 검색할 수 있습니다.'
      produces 'application/json'

      parameter name: :lat, in: :query, type: :number, required: true, description: '중심 위도 (예: 37.5665)'
      parameter name: :lng, in: :query, type: :number, required: true, description: '중심 경도 (예: 126.9780)'
      parameter name: :radius, in: :query, type: :number, description: '검색 반경 (기본값: 0.01, 약 1km)'
      SharedSchemas.property_filter_params.each { |param| parameter param }

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 center: {
                   type: :object,
                   properties: {
                     lat: { type: :number },
                     lng: { type: :number }
                   }
                 },
                 radius: { type: :number },
                 properties: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/Property' }
                 },
                 count: { type: :integer }
               }

        let(:lat) { 37.5665 }
        let(:lng) { 126.9780 }
        run_test!
      end

      response 400, 'Bad Request' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Latitude and longitude are required' }
               }
        run_test!
      end
    end
  end
end