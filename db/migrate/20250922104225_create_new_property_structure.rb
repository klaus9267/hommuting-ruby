class CreateNewPropertyStructure < ActiveRecord::Migration[8.0]
  def change
    # 기존 properties 테이블에 필드 추가 (이미 존재하는 description, zigbang_url 제외)
    add_column :properties, :area_description, :string
    add_column :properties, :area_sqm, :decimal, precision: 10, scale: 2
    add_column :properties, :floor_description, :string
    add_column :properties, :current_floor, :integer
    add_column :properties, :total_floors, :integer
    add_column :properties, :room_structure, :string
    add_column :properties, :maintenance_fee, :bigint

    # addresses 테이블 생성
    create_table :addresses do |t|
      t.references :property, null: false, foreign_key: true
      t.string :local1          # 서울시, 경기도
      t.string :local2          # 강남구, 수원시 장안구
      t.string :local3          # 논현동, 조원동
      t.string :local4          # 세부 주소
      t.string :short_address   # 강남구 논현동
      t.string :full_address    # 서울시 강남구 논현동

      t.timestamps
    end

    # property_images 테이블 생성
    create_table :property_images do |t|
      t.references :property, null: false, foreign_key: true
      t.string :thumbnail_url
      t.text :image_urls, array: true, default: []

      t.timestamps
    end

    # apartment_details 테이블 생성 (아파트 전용)
    create_table :apartment_details do |t|
      t.references :property, null: false, foreign_key: true
      t.bigint :area_ho_id
      t.bigint :area_danji_id
      t.string :area_danji_name
      t.bigint :danji_room_type_id
      t.string :dong
      t.json :room_type_title
      t.decimal :size_contract_m2, precision: 10, scale: 2
      t.string :tran_type
      t.string :item_type
      t.boolean :is_price_range, default: false

      t.timestamps
    end

    # 인덱스 추가 (존재하지 않는 경우에만)
    add_index :addresses, :local2, if_not_exists: true
    add_index :property_images, :property_id, if_not_exists: true
    add_index :apartment_details, :area_danji_id, if_not_exists: true
    add_index :apartment_details, :tran_type, if_not_exists: true
  end
end
