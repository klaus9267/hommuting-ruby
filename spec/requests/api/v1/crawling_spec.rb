require 'swagger_helper'

RSpec.describe 'Crawling API', type: :request do
  path '/api/v1/crawling/seoul' do
    post '서울 매물 수집' do
      tags '크롤링'
      description '서울 전체 25개 구의 매물을 수집합니다. 직방 API를 통해 빌라, 원룸, 오피스텔 매물을 수집하며, 개발 모드에서는 강남구와 서초구만 테스트로 수집합니다.'
      produces 'application/json'

      parameter name: :dev_mode, in: :query, type: :boolean, required: false,
                description: '개발 모드 (true: 강남구, 서초구만 테스트, false: 서울 전체 25개 구)',
                example: true

      parameter name: :property_types, in: :query, type: :array, required: false,
                description: '수집할 매물 타입들 (기본값: villa, oneroom, officetel)',
                items: { type: :string, enum: ['villa', 'oneroom', 'officetel', 'apartment'] },
                example: ['villa', 'oneroom']

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'success' },
                 message: { type: :string, example: '서울 전체 매물 수집을 완료했습니다' },
                 collected_count: { type: :integer, example: 1250 },
                 property_types: {
                   type: :object,
                   example: { '빌라' => 500, '원룸' => 400, '오피스텔' => 350 },
                   description: '매물 타입별 수집 개수'
                 },
                 sample_properties: {
                   type: :array,
                   description: '수집된 매물 샘플 (최대 3개)',
                   items: { '$ref' => '#/components/schemas/Property' }
                 },
                 areas_completed: { type: :integer, example: 25, description: '완료된 지역 수' },
                 dev_mode: { type: :boolean, example: false },
                 timestamp: { type: :string, format: 'date-time' }
               }

        run_test!
      end

      response 500, 'Internal Server Error' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'error' },
                 message: { type: :string, example: '서울 매물 수집 중 오류가 발생했습니다' },
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/crawling/gyeonggi' do
    post '경기도 매물 수집' do
      tags '크롤링'
      description '경기도 48개 시/구의 매물을 수집합니다. 수원시 4개 구, 성남시 3개 구, 용인시 3개 구 등 구 단위로 세분화하여 수집하며, 개발 모드에서는 수원시 영통구와 성남시 분당구만 테스트로 수집합니다.'
      produces 'application/json'

      parameter name: :dev_mode, in: :query, type: :boolean, required: false,
                description: '개발 모드 (true: 수원시 영통구, 성남시 분당구만 테스트, false: 경기도 전체 48개 시/구)',
                example: true

      parameter name: :property_types, in: :query, type: :array, required: false,
                description: '수집할 매물 타입들 (기본값: villa, oneroom, officetel)',
                items: { type: :string, enum: ['villa', 'oneroom', 'officetel', 'apartment'] },
                example: ['villa', 'oneroom']

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'success' },
                 message: { type: :string, example: '경기도 전체 매물 수집을 완료했습니다' },
                 collected_count: { type: :integer, example: 2100 },
                 property_types: {
                   type: :object,
                   example: { '빌라' => 800, '원룸' => 700, '오피스텔' => 600 },
                   description: '매물 타입별 수집 개수'
                 },
                 sample_properties: {
                   type: :array,
                   description: '수집된 매물 샘플 (최대 3개)',
                   items: { '$ref' => '#/components/schemas/Property' }
                 },
                 areas_completed: { type: :integer, example: 48, description: '완료된 지역 수' },
                 dev_mode: { type: :boolean, example: false },
                 timestamp: { type: :string, format: 'date-time' }
               }

        run_test!
      end

      response 500, 'Internal Server Error' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'error' },
                 message: { type: :string, example: '경기도 매물 수집 중 오류가 발생했습니다' },
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/crawling/all' do
    post '전체 매물 수집' do
      tags '크롤링'
      description '서울과 경기도 전체 매물을 한 번에 수집합니다. 서울 25개 구와 경기도 48개 시/구의 모든 매물을 포함하며, 총 73개 지역에서 매물을 수집합니다.'
      produces 'application/json'

      parameter name: :dev_mode, in: :query, type: :boolean, required: false,
                description: '개발 모드 (true: 테스트 지역만, false: 전체 73개 지역)',
                example: true

      parameter name: :property_types, in: :query, type: :array, required: false,
                description: '수집할 매물 타입들 (기본값: villa, oneroom, officetel)',
                items: { type: :string, enum: ['villa', 'oneroom', 'officetel', 'apartment'] },
                example: ['villa', 'oneroom']

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'success' },
                 message: { type: :string, example: '서울 및 경기도 전체 매물 수집을 완료했습니다' },
                 total_collected: { type: :integer, example: 3350 },
                 breakdown: {
                   type: :object,
                   properties: {
                     seoul: {
                       type: :object,
                       properties: {
                         count: { type: :integer, example: 1250 },
                         areas: { type: :integer, example: 25 },
                         property_types: {
                           type: :object,
                           example: { '빌라' => 500, '원룸' => 400, '오피스텔' => 350 }
                         },
                         sample_properties: {
                           type: :array,
                           description: '서울 매물 샘플',
                           items: { '$ref' => '#/components/schemas/Property' }
                         }
                       }
                     },
                     gyeonggi: {
                       type: :object,
                       properties: {
                         count: { type: :integer, example: 2100 },
                         areas: { type: :integer, example: 48 },
                         property_types: {
                           type: :object,
                           example: { '빌라' => 800, '원룸' => 700, '오피스텔' => 600 }
                         },
                         sample_properties: {
                           type: :array,
                           description: '경기도 매물 샘플',
                           items: { '$ref' => '#/components/schemas/Property' }
                         }
                       }
                     }
                   }
                 },
                 dev_mode: { type: :boolean, example: false },
                 timestamp: { type: :string, format: 'date-time' }
               }

        run_test!
      end

      response 500, 'Internal Server Error' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'error' },
                 message: { type: :string, example: '전체 매물 수집 중 오류가 발생했습니다' },
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/crawling/status' do
    get '크롤링 현황 조회' do
      tags '크롤링'
      description '현재 수집된 매물 통계와 크롤링 현황을 조회합니다. 지역별, 매물 유형별, 거래 유형별 분포를 포함합니다.'
      produces 'application/json'


      response 200, 'Success' do
        schema type: :object,
               properties: {
                 total_properties: { type: :integer, example: 1250 },
                 seoul_properties: { type: :integer, example: 800 },
                 gyeonggi_properties: { type: :integer, example: 450 },
                 by_property_type: {
                   type: :object,
                   example: { 'apartment' => 500, 'villa' => 300, 'officetel' => 250 }
                 },
                 by_deal_type: {
                   type: :object,
                   example: { 'sale' => 600, 'jeonse' => 400, 'monthly_rent' => 250 }
                 },
                 last_updated: { type: :string, format: 'date-time' },
                 recent_properties: {
                   type: :array,
                   description: '최근 수집된 매물 목록',
                   items: { '$ref' => '#/components/schemas/Property' }
                 }
               }

        run_test!
      end

    end
  end
end