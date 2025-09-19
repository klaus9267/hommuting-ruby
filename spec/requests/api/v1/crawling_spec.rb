require 'swagger_helper'

RSpec.describe 'Crawling API', type: :request do
  path '/api/v1/crawling/seoul' do
    post '서울 매물 수집' do
      tags '크롤링'
      description '서울 전체 25개 구의 매물을 수집합니다. 모든 매물 유형(아파트, 빌라, 오피스텔 등)과 거래 유형(매매, 전세, 월세)을 포함합니다.'
      produces 'application/json'


      response 200, 'Success' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'success' },
                 message: { type: :string, example: '서울 매물 수집을 시작했습니다' },
                 collected_count: { type: :integer, example: 150 },
                 areas: { type: :array, items: { type: :string }, example: ['강남구', '강서구', '종로구'] },
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
      description '경기도 주요 25개 시군의 매물을 수집합니다. 수원, 성남, 고양 등 주요 도시의 모든 매물 유형을 포함합니다.'
      produces 'application/json'


      response 200, 'Success' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'success' },
                 message: { type: :string, example: '경기도 매물 수집을 시작했습니다' },
                 collected_count: { type: :integer, example: 200 },
                 areas: { type: :array, items: { type: :string }, example: ['수원시', '성남시', '고양시'] },
                 timestamp: { type: :string, format: 'date-time' }
               }

        run_test!
      end

      response 500, 'Internal Server Error'
    end
  end

  path '/api/v1/crawling/all' do
    post '전체 매물 수집' do
      tags '크롤링'
      description '서울과 경기도 전체 매물을 한 번에 수집합니다. 서울 25개 구와 경기도 25개 시군의 모든 매물을 포함합니다.'
      produces 'application/json'


      response 200, 'Success' do
        schema type: :object,
               properties: {
                 status: { type: :string, example: 'success' },
                 message: { type: :string, example: '서울 및 경기도 매물 수집을 시작했습니다' },
                 collected_count: { type: :integer, example: 350 },
                 areas: { type: :array, items: { type: :string } },
                 breakdown: {
                   type: :object,
                   properties: {
                     seoul: {
                       type: :object,
                       properties: {
                         count: { type: :integer },
                         areas: { type: :array, items: { type: :string } }
                       }
                     },
                     gyeonggi: {
                       type: :object,
                       properties: {
                         count: { type: :integer },
                         areas: { type: :array, items: { type: :string } }
                       }
                     }
                   }
                 },
                 timestamp: { type: :string, format: 'date-time' }
               }

        run_test!
      end

      response 500, 'Internal Server Error'
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
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       title: { type: :string },
                       address: { type: :string },
                       property_type: { type: :string },
                       deal_type: { type: :string },
                       created_at: { type: :string, format: 'date-time' }
                     }
                   }
                 }
               }

        run_test!
      end

    end
  end
end