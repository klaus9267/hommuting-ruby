# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  config.openapi_root = Rails.root.join('public').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  config.openapi_specs = {
    'api/v1/swagger.json' => {
      openapi: '3.0.1',
      info: {
        title: 'Hommuting Crawling API V1',
        version: 'v1',
        description: '한국 부동산 매물 수집 API - 직방 등 부동산 사이트에서 매물 데이터를 수집하는 크롤링 시스템'
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://crawling.hommuting.com',
          description: 'Production crawling server'
        }
      ],
      components: {
        schemas: {
          Error: {
            type: :object,
            properties: {
              status: { type: :string, example: 'error', description: '오류 상태' },
              message: { type: :string, description: '오류 메시지' },
              error: { type: :string, description: '상세 오류 내용' }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  config.openapi_format = :json
end