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
      { name: :property_type, in: :query, type: :string, enum: ['아파트', '빌라', '오피스텔', '단독주택', '다가구', '주상복합'] },
      { name: :deal_type, in: :query, type: :string, enum: ['매매', '전세', '월세'] },
      { name: :source, in: :query, type: :string, description: '데이터 소스' }
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