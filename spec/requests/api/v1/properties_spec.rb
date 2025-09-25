# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/properties', type: :request do

  path '/api/v1/properties/map' do
    get('지도 기반 매물 조회') do
      tags '매물 조회 API'
      description '지도 경계 내 매물을 사용자 조건에 맞춰 조회합니다. PostGIS를 사용하여 효율적인 지리적 검색을 지원합니다.'
      produces 'application/json'

      # 지도 경계 파라미터 (필수) - 직방 API 형식
      parameter name: :latNorth, in: :query, type: :number, format: :float, required: true,
                description: '북쪽 위도', example: 37.5665
      parameter name: :lngEast, in: :query, type: :number, format: :float, required: true,
                description: '동쪽 경도', example: 127.0280
      parameter name: :latSouth, in: :query, type: :number, format: :float, required: true,
                description: '남쪽 위도', example: 37.5000
      parameter name: :lngWest, in: :query, type: :number, format: :float, required: true,
                description: '서쪽 경도', example: 126.9000

      # 매물 필터 파라미터
      parameter name: :service_types, in: :query, type: :array,
                items: { type: :string, enum: ['원룸', '빌라', '오피스텔', '아파트'] },
                description: '매물 유형 배열', example: ['원룸', '빌라']
      parameter name: :sales_types, in: :query, type: :array,
                items: { type: :string, enum: ['매매', '전세', '월세'] },
                description: '거래 유형 배열', example: ['전세', '월세']
      parameter name: :room_types, in: :query, type: :array,
                items: { type: :string, enum: ['01', '02', '03', '04', '05', '06'] },
                description: '방 구조 배열 (01:오픈형, 02:분리형, 03:복층형, 04:투룸, 05:쓰리룸, 06:포룸+)',
                example: ['01', '04']

      # 가격 필터 파라미터
      parameter name: :deposit_min, in: :query, type: :integer,
                description: '최소 보증금 (만원)', example: 1000
      parameter name: :deposit_max, in: :query, type: :integer,
                description: '최대 보증금 (만원)', example: 10000
      parameter name: :rent_min, in: :query, type: :integer,
                description: '최소 월세 (만원)', example: 50
      parameter name: :rent_max, in: :query, type: :integer,
                description: '최대 월세 (만원)', example: 200
      parameter name: :maintenance_fee_max, in: :query, type: :integer,
                description: '최대 관리비 (만원)', example: 10

      # 페이지네이션 파라미터
      parameter name: :page, in: :query, type: :integer,
                description: '페이지 번호 (기본: 1)', example: 1
      parameter name: :per_page, in: :query, type: :integer,
                description: '페이지당 항목 수 (최대: 15)', example: 15

      response(200, '매물 조회 성공') do
        schema type: :object,
               properties: {
                 properties: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer, description: '매물 ID' },
                       address: { type: :string, description: '주소' },
                       sales_type: { type: :string, description: '거래 유형', enum: ['매매', '전세', '월세'] },
                       deposit: { type: :integer, nullable: true, description: '보증금 (만원)' },
                       rent: { type: :integer, nullable: true, description: '월세 (만원)' },
                       service_type: { type: :string, description: '매물 유형', enum: ['원룸', '빌라', '오피스텔', '아파트'] },
                       room_type: { type: :string, nullable: true, description: '방 구조 코드' },
                       room_type_name: { type: :string, description: '방 구조명', enum: ['오픈형', '분리형', '복층형', '투룸', '쓰리룸', '포룸+', '정보없음'] },
                       floor: { type: :integer, nullable: true, description: '층수' },
                       total_floor: { type: :integer, nullable: true, description: '총 층수' },
                       maintenance_fee: { type: :integer, nullable: true, description: '관리비' },
                       thumbnail_url: { type: :string, nullable: true, description: '썸네일 이미지 URL' },
                       latitude: { type: :number, format: :float, description: '위도' },
                       longitude: { type: :number, format: :float, description: '경도' },
                       geohash: { type: :string, nullable: true, description: '지오해시' },
                       price_info: { type: :string, description: '가격 정보 (formatted)' },
                       floor_info: { type: :string, nullable: true, description: '층수 정보 (formatted)' },
                       created_at: { type: :string, format: :'date-time', description: '생성일시' }
                     }
                   }
                 },
                 total_count: { type: :integer, description: '전체 매물 수' },
                 filters_applied: {
                   type: :object,
                   description: '적용된 필터 요약',
                   properties: {
                     service_types: { type: :array, items: { type: :string } },
                     sales_types: { type: :array, items: { type: :string } },
                     room_types: { type: :array, items: { type: :string } },
                     deposit_range: { type: :array, items: { type: :integer } },
                     rent_range: { type: :array, items: { type: :integer } },
                     maintenance_fee_max: { type: :integer }
                   }
                 },
                 bounds: {
                   type: :object,
                   description: '조회된 지도 경계',
                   properties: {
                     ne_lat: { type: :number, format: :float },
                     ne_lng: { type: :number, format: :float },
                     sw_lat: { type: :number, format: :float },
                     sw_lng: { type: :number, format: :float }
                   }
                 }
               }

        examples 'application/json' => {
          properties: [
            {
              id: 1,
              address: "서울특별시 강남구 역삼동 123-45",
              sales_type: "월세",
              deposit: 1000,
              rent: 80,
              service_type: "원룸",
              room_type: "01",
              room_type_name: "오픈형",
              floor: 3,
              total_floor: 10,
              maintenance_fee: 5,
              thumbnail_url: "https://example.com/thumb.jpg",
              latitude: 37.5000,
              longitude: 127.0500,
              geohash: "wydm6",
              price_info: "월세 1000만/80만원",
              floor_info: "3/10층",
              created_at: "2024-01-15T10:30:00Z"
            }
          ],
          total_count: 125,
          filters_applied: {
            service_types: ["원룸"],
            sales_types: ["월세"],
            deposit_range: [1000, 10000]
          },
          bounds: {
            ne_lat: 37.5665,
            ne_lng: 126.9780,
            sw_lat: 37.5000,
            sw_lng: 126.9000
          }
        }

        run_test!
      end

      response(400, '잘못된 요청') do
        schema type: :object,
               properties: {
                 error: { type: :string, description: '오류 메시지' },
                 message: { type: :string, description: '상세 오류 내용' }
               }

        examples 'application/json' => {
          error: '매물 조회 중 오류가 발생했습니다',
          message: '필수 지도 경계 파라미터가 누락되었습니다: ne_lat, ne_lng'
        }

        run_test!
      end

      response(500, '서버 오류') do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  path '/api/v1/properties/room_types' do
    get('방 구조 옵션 조회') do
      tags '매물 조회 API'
      description '매물 검색에 사용할 수 있는 방 구조 옵션 목록을 조회합니다.'
      produces 'application/json'

      response(200, '방 구조 옵션 조회 성공') do
        schema type: :object,
               properties: {
                 room_types: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       code: { type: :string, description: '방 구조 코드', enum: ['01', '02', '03', '04', '05', '06'] },
                       name: { type: :string, description: '방 구조명', enum: ['오픈형', '분리형', '복층형', '투룸', '쓰리룸', '포룸+'] }
                     }
                   }
                 }
               }

        examples 'application/json' => {
          room_types: [
            { code: "01", name: "오픈형" },
            { code: "02", name: "분리형" },
            { code: "03", name: "복층형" },
            { code: "04", name: "투룸" },
            { code: "05", name: "쓰리룸" },
            { code: "06", name: "포룸+" }
          ]
        }

        run_test!
      end

      response(500, '서버 오류') do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end
end