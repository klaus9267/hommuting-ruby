# MVP용 간소화된 스키마 헬퍼
module SharedSchemas
  def self.pagination_params
    [
      { name: :page, in: :query, type: :integer, description: '페이지 번호 (기본: 1)' },
      { name: :per_page, in: :query, type: :integer, description: '페이지당 항목 수 (최대: 15)' }
    ]
  end

  def self.property_filter_params
    [
      { name: :property_type, in: :query, type: :string, enum: ['apartment', 'villa', 'officetel', 'single_house', 'multi_house', 'mixed_use'], description: '매물 유형 필터' },
      { name: :deal_type, in: :query, type: :string, enum: ['sale', 'jeonse', 'monthly_rent'], description: '거래 유형 필터' },
      { name: :source, in: :query, type: :string, description: '매물 데이터 출처 필터' }
    ]
  end

  def self.map_filter_params
    [
      # 지도 경계 파라미터 (필수) - 직방 API 형식
      { name: :latNorth, in: :query, type: :number, format: :float, required: true, description: '북쪽 위도', example: 37.5665 },
      { name: :lngEast, in: :query, type: :number, format: :float, required: true, description: '동쪽 경도', example: 127.0280 },
      { name: :latSouth, in: :query, type: :number, format: :float, required: true, description: '남쪽 위도', example: 37.5000 },
      { name: :lngWest, in: :query, type: :number, format: :float, required: true, description: '서쪽 경도', example: 126.9000 },

      # 매물 필터 파라미터
      { name: :service_types, in: :query, type: :array, items: { type: :string, enum: ['원룸', '빌라', '오피스텔', '아파트'] }, description: '매물 유형 배열', example: ['원룸', '빌라'] },
      { name: :sales_types, in: :query, type: :array, items: { type: :string, enum: ['매매', '전세', '월세'] }, description: '거래 유형 배열', example: ['전세', '월세'] },
      { name: :room_types, in: :query, type: :array, items: { type: :string, enum: ['01', '02', '03', '04', '05', '06'] }, description: '방 구조 배열 (01:오픈형, 02:분리형, 03:복층형, 04:투룸, 05:쓰리룸, 06:포룸+)', example: ['01', '04'] },

      # 가격 필터 파라미터
      { name: :deposit_min, in: :query, type: :integer, description: '최소 보증금 (만원)', example: 1000 },
      { name: :deposit_max, in: :query, type: :integer, description: '최대 보증금 (만원)', example: 10000 },
      { name: :rent_min, in: :query, type: :integer, description: '최소 월세 (만원)', example: 50 },
      { name: :rent_max, in: :query, type: :integer, description: '최대 월세 (만원)', example: 200 },
      { name: :maintenance_fee_max, in: :query, type: :integer, description: '최대 관리비 (만원)', example: 10 }
    ]
  end

  def self.property_schema
    {
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