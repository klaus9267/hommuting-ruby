require 'swagger_helper'

# MVP용 간소화된 API 스펙
RSpec.describe 'Properties API', type: :request do
  path '/api/v1/properties' do
    get 'List properties' do
      tags 'Properties'
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
        let(:properties) { create_list(:property, 2) }
        run_test!
      end

      responses.merge!(SharedSchemas.error_response)
    end
  end

  # MVP 핵심 기능만 간소화
  path '/api/v1/properties/{id}' do
    parameter name: 'id', in: :path, type: :string

    get 'Show property' do
      tags 'Properties'

      response 200, 'Success' do
        schema '$ref' => '#/components/schemas/Property'
        let(:property) { create(:property) }
        let(:id) { property.id }
        run_test!
      end

      response 404, 'Not Found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/properties/search' do
    get 'Search properties' do
      tags 'Properties'

      parameter name: :q, in: :query, type: :string, required: true, description: '검색어'
      SharedSchemas.property_filter_params.each { |param| parameter param }
      SharedSchemas.pagination_params.each { |param| parameter param }

      response 200, 'Success' do
        schema '$ref' => '#/components/schemas/PropertyList'
        let(:q) { 'test' }
        run_test!
      end

      responses.merge!(SharedSchemas.error_response)
    end
  end

  # MVP용 간단한 통계
  path '/api/v1/properties/stats' do
    get 'Property statistics' do
      tags 'Properties'

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
end