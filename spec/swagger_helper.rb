# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Hommuting API',
        version: 'v1',
        description: 'Korean Real Estate Property Aggregation API'
      },
      paths: {},
      components: {
        schemas: {
          # 새로운 ERD 구조에 맞춘 스키마
          Property: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              address_text: { type: :string, description: '기본 주소 텍스트' },
              price: { type: :string },
              property_type: { type: :string, enum: ['아파트', '빌라', '오피스텔', '단독주택', '다가구', '주상복합'] },
              deal_type: { type: :string, enum: ['매매', '전세', '월세'] },
              area: { type: :string, description: '면적 (기본 표시용)' },
              floor: { type: :string, description: '층수 (기본 표시용)' },
              description: { type: :string, description: '매물 설명' },
              area_description: { type: :string, description: '면적 상세 설명' },
              area_sqm: { type: :number, format: :float, description: '면적 (제곱미터)' },
              floor_description: { type: :string, description: '층수 상세 설명' },
              current_floor: { type: :integer, description: '현재 층' },
              total_floors: { type: :integer, description: '전체 층수' },
              room_structure: { type: :string, description: '방 구조 (예: 2룸, 3룸)' },
              maintenance_fee: { type: :integer, description: '관리비 (원)' },
              latitude: { type: :number, format: :float },
              longitude: { type: :number, format: :float },
              source: { type: :string },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' },
              address: { '$ref' => '#/components/schemas/Address' },
              property_image: { '$ref' => '#/components/schemas/PropertyImage' },
              apartment_detail: { '$ref' => '#/components/schemas/ApartmentDetail' }
            }
          },
          Address: {
            type: :object,
            properties: {
              id: { type: :integer },
              property_id: { type: :integer },
              local1: { type: :string, description: '시/도 (예: 서울특별시)' },
              local2: { type: :string, description: '구/시 (예: 강남구)' },
              local3: { type: :string, description: '동 (예: 논현동)' },
              local4: { type: :string, description: '상세 주소' },
              short_address: { type: :string, description: '간단 주소 (구 + 동)' },
              full_address: { type: :string, description: '전체 주소' },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            }
          },
          PropertyImage: {
            type: :object,
            properties: {
              id: { type: :integer },
              property_id: { type: :integer },
              thumbnail_url: { type: :string, format: :uri, description: '썸네일 이미지 URL' },
              image_urls: {
                type: :array,
                items: { type: :string, format: :uri },
                description: '매물 이미지 URL 배열'
              },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            }
          },
          ApartmentDetail: {
            type: :object,
            properties: {
              id: { type: :integer },
              property_id: { type: :integer },
              area_ho_id: { type: :integer, description: '직방 호 ID' },
              area_danji_id: { type: :integer, description: '단지 ID' },
              area_danji_name: { type: :string, description: '단지명' },
              danji_room_type_id: { type: :integer, description: '단지 방 타입 ID' },
              dong: { type: :string, description: '동 정보' },
              room_type_title: { type: :object, description: '방 타입 제목 (다국어)' },
              size_contract_m2: { type: :number, format: :float, description: '계약 면적 (제곱미터)' },
              tran_type: { type: :string, description: '거래 유형' },
              item_type: { type: :string, description: '매물 타입' },
              is_price_range: { type: :boolean, description: '가격 범위 여부' },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            }
          },
          PropertyList: {
            type: :object,
            properties: {
              properties: { type: :array, items: { '$ref' => '#/components/schemas/Property' } },
              pagination: { '$ref' => '#/components/schemas/Pagination' }
            }
          },
          Pagination: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              per_page: { type: :integer },
              total_count: { type: :integer }
            }
          }
        }
      },
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'api.hommuting.com'
            }
          },
          description: 'Production server'
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
