class ChangePropertyAndDealTypeToEnum < ActiveRecord::Migration[8.0]
  def up
    # 기존 데이터를 새로운 enum 값으로 변환
    Property.where(property_type: '아파트').update_all(property_type: 'apartment')
    Property.where(property_type: '빌라').update_all(property_type: 'villa')
    Property.where(property_type: '오피스텔').update_all(property_type: 'officetel')
    Property.where(property_type: '단독주택').update_all(property_type: 'single_house')
    Property.where(property_type: '다가구').update_all(property_type: 'multi_house')
    Property.where(property_type: '주상복합').update_all(property_type: 'mixed_use')

    Property.where(deal_type: '매매').update_all(deal_type: 'sale')
    Property.where(deal_type: '전세').update_all(deal_type: 'jeonse')
    Property.where(deal_type: '월세').update_all(deal_type: 'monthly_rent')
  end

  def down
    # 롤백 시 한국어로 되돌리기
    Property.where(property_type: 'apartment').update_all(property_type: '아파트')
    Property.where(property_type: 'villa').update_all(property_type: '빌라')
    Property.where(property_type: 'officetel').update_all(property_type: '오피스텔')
    Property.where(property_type: 'single_house').update_all(property_type: '단독주택')
    Property.where(property_type: 'multi_house').update_all(property_type: '다가구')
    Property.where(property_type: 'mixed_use').update_all(property_type: '주상복합')

    Property.where(deal_type: 'sale').update_all(deal_type: '매매')
    Property.where(deal_type: 'jeonse').update_all(deal_type: '전세')
    Property.where(deal_type: 'monthly_rent').update_all(deal_type: '월세')
  end
end
