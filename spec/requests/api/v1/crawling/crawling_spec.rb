# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/crawling', type: :request do

  path '/api/v1/crawling/seoul' do

    post('서울 지역 매물 수집') do
      tags '크롤링 API'
      description '서울 전체 지역의 매물을 geohash 기반으로 수집합니다. CrawlingOrchestrator를 통해 직방 사이트에서 원룸, 빌라, 오피스텔 매물을 수집합니다.'
      produces 'application/json'

      parameter name: :dev_mode, in: :query, type: :boolean, required: false,
                description: '개발 모드 (true/false)', example: false
      parameter name: :property_types, in: :query, type: :array, required: false,
                items: { type: :string, enum: ['oneroom', 'villa', 'officetel'] },
                description: '수집할 매물 타입 배열 (기본값: 전체)', example: ['oneroom', 'villa']

      response(200, '수집 완료') do
        schema type: :object,
               properties: {
                 status: { type: :string, description: '수집 상태' },
                 region: { type: :string, description: '수집 지역' },
                 total_collected: { type: :integer, description: '수집된 매물 수' },
                 property_types: { type: :array, items: { type: :string }, description: '수집한 매물 타입들' },
                 execution_time: { type: :number, description: '실행 시간 (초)' },
                 details: { type: :object, description: '상세 수집 결과' }
               }

        examples 'application/json' => {
          status: 'completed',
          region: 'seoul',
          total_collected: 15430,
          property_types: ['oneroom', 'villa', 'officetel'],
          execution_time: 245.7,
          details: {
            oneroom: 8520,
            villa: 4210,
            officetel: 2700,
            errors: 0
          }
        }

        run_test!
      end

      response(500, '수집 오류') do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  path '/api/v1/crawling/gyeonggi' do

    post('경기도 지역 매물 수집') do
      tags '크롤링 API'
      description '경기도 전체 지역의 매물을 geohash 기반으로 수집합니다.'
      produces 'application/json'

      parameter name: :dev_mode, in: :query, type: :boolean, required: false,
                description: '개발 모드 (true/false)', example: false
      parameter name: :property_types, in: :query, type: :array, required: false,
                items: { type: :string, enum: ['oneroom', 'villa', 'officetel'] },
                description: '수집할 매물 타입 배열'

      response(200, '수집 완료') do
        schema type: :object,
               properties: {
                 status: { type: :string, description: '수집 상태' },
                 region: { type: :string, description: '수집 지역' },
                 total_collected: { type: :integer, description: '수집된 매물 수' },
                 property_types: { type: :array, items: { type: :string } },
                 execution_time: { type: :number, description: '실행 시간 (초)' },
                 details: { type: :object, description: '상세 수집 결과' }
               }

        run_test!
      end

      response(500, '수집 오류') do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  path '/api/v1/crawling/all' do

    post('전체 지역 매물 수집') do
      tags '크롤링 API'
      description '서울 + 경기도 전체 지역의 매물을 수집합니다.'
      produces 'application/json'

      parameter name: :dev_mode, in: :query, type: :boolean, required: false,
                description: '개발 모드 (true/false)'
      parameter name: :property_types, in: :query, type: :array, required: false,
                items: { type: :string, enum: ['oneroom', 'villa', 'officetel'] },
                description: '수집할 매물 타입 배열'

      response(200, '수집 완료') do
        schema type: :object,
               properties: {
                 status: { type: :string, description: '수집 상태' },
                 regions: { type: :array, items: { type: :string }, description: '수집 지역들' },
                 total_collected: { type: :integer, description: '전체 수집된 매물 수' },
                 execution_time: { type: :number, description: '실행 시간 (초)' },
                 region_details: { type: :object, description: '지역별 상세 결과' }
               }

        examples 'application/json' => {
          status: 'completed',
          regions: ['seoul', 'gyeonggi'],
          total_collected: 28750,
          execution_time: 485.2,
          region_details: {
            seoul: { collected: 15430, errors: 0 },
            gyeonggi: { collected: 13320, errors: 0 }
          }
        }

        run_test!
      end

      response(500, '수집 오류') do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end
end