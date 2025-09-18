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
        let(:properties) { create_list(:property, 2) }
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
end