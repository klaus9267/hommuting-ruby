# MVP용 간소화된 스키마 헬퍼
module SharedSchemas
  def self.pagination_params
    [
      { name: :page, in: :query, type: :integer, description: '페이지 번호 (기본: 1)' },
      { name: :per_page, in: :query, type: :integer, description: '페이지당 항목 수 (기본: 20)' }
    ]
  end

  def self.property_filter_params
    [
      { name: :property_type, in: :query, type: :string, enum: ['apartment', 'villa', 'officetel', 'single_house', 'multi_house', 'mixed_use'], description: '매물 유형 필터' },
      { name: :deal_type, in: :query, type: :string, enum: ['sale', 'jeonse', 'monthly_rent'], description: '거래 유형 필터' },
      { name: :source, in: :query, type: :string, description: '매물 데이터 출처 필터' }
    ]
  end

  def self.success_response(ref)
    {
      200 => {
        description: 'Success',
        content: {
          'application/json' => {
            schema: { '$ref' => ref }
          }
        }
      }
    }
  end

  def self.error_response
    {
      400 => { description: 'Bad Request' },
      404 => { description: 'Not Found' },
      500 => { description: 'Internal Server Error' }
    }
  end
end