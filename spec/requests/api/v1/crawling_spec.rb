require 'swagger_helper'

RSpec.describe 'Crawling API (Geohash 기반 2단계 크롤링)', type: :request do
  path '/api/v1/crawling/seoul' do
    post '서울 지역 매물 수집 (Geohash 기반)' do
      tags '크롤링'
      description <<~DESC
        서울 지역의 부동산 매물을 geohash 기반으로 수집합니다.

        **2단계 크롤링 시스템:**
        1. **ID 수집**: 각 geohash 영역별로 매물 ID를 수집 (GET 요청)
        2. **상세 정보**: 수집된 ID를 15개씩 배치로 나누어 상세 정보 조회 (POST 요청)

        **개발 모드**: 3개 geohash만 테스트 수집
        **전체 모드**: 서울 전체 geohash 영역 수집 (약 96개 영역)
      DESC
      produces 'application/json'

      parameter name: :dev_mode, in: :query, type: :boolean, description: '개발 모드 (true: 제한된 geohash만 테스트, false: 전체 수집)'
      parameter name: :property_types, in: :query, type: :array, items: { type: :string, enum: ['oneroom', 'villa', 'officetel'] }, description: '수집할 매물 유형 (기본값: 전체)'

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'success' },
                 message: { type: :string, example: '서울 전체 매물 수집 완료' },
                 collected_count: { type: :integer, example: 1250 },
                 property_types: {
                   type: :object,
                   properties: {
                     원룸: { type: :integer, example: 800 },
                     빌라: { type: :integer, example: 300 },
                     오피스텔: { type: :integer, example: 150 }
                   }
                 },
                 sample_properties: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       title: { type: :string },
                       address_text: { type: :string },
                       price: { type: :string },
                       property_type: { type: :string },
                       deal_type: { type: :string },
                       area_sqm: { type: :number },
                       source: { type: :string, example: 'zigbang_api' },
                       external_id: { type: :string }
                     }
                   }
                 },
                 geohash_count: { type: :integer, example: 96 },
                 dev_mode: { type: :boolean },
                 timestamp: { type: :string }
               }
        run_test!
      end

      response 500, 'Internal Server Error' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'error' },
                 message: { type: :string },
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/crawling/gyeonggi' do
    post '경기도 지역 매물 수집 (Geohash 기반)' do
      tags '크롤링'
      description <<~DESC
        경기도 지역의 부동산 매물을 geohash 기반으로 수집합니다.

        서울과 동일한 2단계 크롤링 시스템을 사용하며,
        경기도 전체 geohash 영역 (약 96개)에서 매물을 수집합니다.
      DESC
      produces 'application/json'

      parameter name: :dev_mode, in: :query, type: :boolean, description: '개발 모드'
      parameter name: :property_types, in: :query, type: :array, items: { type: :string, enum: ['oneroom', 'villa', 'officetel'] }, description: '수집할 매물 유형'

      response 200, 'Success' do
        schema '$ref' => '#/components/schemas/CrawlingResponse'
        run_test!
      end

      response 500, 'Internal Server Error'
    end
  end

  path '/api/v1/crawling/all' do
    post '서울+경기도 전체 매물 수집' do
      tags '크롤링'
      description <<~DESC
        서울과 경기도 전체 지역의 부동산 매물을 수집합니다.

        **처리 순서:**
        1. 서울 지역 전체 geohash 수집
        2. 10초 대기 (안티 봇)
        3. 경기도 지역 전체 geohash 수집

        **예상 소요 시간**: 전체 모드 시 수 시간 소요 가능
      DESC
      produces 'application/json'

      parameter name: :dev_mode, in: :query, type: :boolean, description: '개발 모드'
      parameter name: :property_types, in: :query, type: :array, items: { type: :string, enum: ['oneroom', 'villa', 'officetel'] }, description: '수집할 매물 유형'

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 status: { type: :string },
                 message: { type: :string },
                 total_collected: { type: :integer },
                 breakdown: {
                   type: :object,
                   properties: {
                     seoul: {
                       type: :object,
                       properties: {
                         count: { type: :integer },
                         geohash_count: { type: :integer },
                         property_types: { type: :object },
                         sample_properties: { type: :array }
                       }
                     },
                     gyeonggi: {
                       type: :object,
                       properties: {
                         count: { type: :integer },
                         geohash_count: { type: :integer },
                         property_types: { type: :object },
                         sample_properties: { type: :array }
                       }
                     }
                   }
                 },
                 dev_mode: { type: :boolean },
                 timestamp: { type: :string }
               }
        run_test!
      end

      response 500, 'Internal Server Error'
    end
  end

  path '/api/v1/crawling/geohash' do
    get 'Geohash 정보 조회' do
      tags '크롤링'
      description <<~DESC
        현재 시스템에서 사용하는 geohash 목록과 관련 정보를 조회합니다.

        **Geohash란?**
        - 지리적 좌표를 짧은 문자열로 인코딩하는 시스템
        - 5글자 geohash로 서울/경기도를 약 4km×4km 격자로 분할
        - 총 192개 geohash 영역으로 전체 지역 커버
      DESC
      produces 'application/json'

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 total_geohashes: { type: :integer, example: 192 },
                 seoul: {
                   type: :object,
                   properties: {
                     count: { type: :integer, example: 96 },
                     geohashes: {
                       type: :array,
                       items: { type: :string },
                       example: ['wydm0', 'wydm1', 'wydm2', 'wydm3', 'wydm4']
                     }
                   }
                 },
                 gyeonggi: {
                   type: :object,
                   properties: {
                     count: { type: :integer, example: 96 },
                     geohashes: {
                       type: :array,
                       items: { type: :string },
                       example: ['wydf0', 'wydf1', 'wydf2', 'wydf3', 'wydf4']
                     }
                   }
                 },
                 supported_property_types: {
                   type: :array,
                   items: { type: :string },
                   example: ['oneroom', 'villa', 'officetel']
                 }
               }
        run_test!
      end
    end
  end

  path '/api/v1/crawling/status' do
    get '크롤링 상태 조회' do
      tags '크롤링'
      description '현재 수집된 매물 통계 및 최근 수집 정보를 조회합니다.'
      produces 'application/json'

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 total_properties: { type: :integer },
                 seoul_properties: { type: :integer },
                 gyeonggi_properties: { type: :integer },
                 by_property_type: { type: :object },
                 by_deal_type: { type: :object },
                 by_source: { type: :object },
                 last_updated: { type: :string },
                 recent_properties: { type: :array }
               }
        run_test!
      end
    end
  end
end