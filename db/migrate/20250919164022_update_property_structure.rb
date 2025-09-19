class UpdatePropertyStructure < ActiveRecord::Migration[8.0]
  def change
    # source 컬럼 제거
    remove_column :properties, :source, :string

    # 새로운 컬럼들 추가
    add_column :properties, :area_sqm, :decimal, precision: 8, scale: 2  # 면적 (㎡)
    add_column :properties, :total_floors, :integer                      # 건물 전체 층수
    add_column :properties, :room_structure, :string                     # 방 구조 (쓰리룸, 분리형 등)
    add_column :properties, :maintenance_fee, :string                    # 관리비

    # 기존 area 컬럼을 area_description으로 변경 (기존 "84㎡" 같은 문자열 유지)
    rename_column :properties, :area, :area_description

    # 기존 floor 컬럼을 floor_description으로 변경 (기존 "3/15층" 같은 문자열 유지)
    rename_column :properties, :floor, :floor_description

    # 현재 층수만 따로 저장할 컬럼 추가
    add_column :properties, :current_floor, :integer                     # 현재 층수
  end
end
