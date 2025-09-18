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
          # MVP용 간소화된 스키마
          Property: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              address: { type: :string },
              price: { type: :string },
              property_type: { type: :string, enum: ['아파트', '빌라', '오피스텔', '단독주택', '다가구', '주상복합'] },
              deal_type: { type: :string, enum: ['매매', '전세', '월세'] },
              area: { type: :string },
              coordinate: { type: :array, items: { type: :number } },
              source: { type: :string }
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
