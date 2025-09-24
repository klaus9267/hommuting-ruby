# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 0) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"


  create_table "apartment_details", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "area_ho_id"
    t.bigint "area_danji_id"
    t.string "area_danji_name"
    t.bigint "danji_room_type_id"
    t.string "dong"
    t.json "room_type_title"
    t.decimal "size_contract_m2", precision: 10, scale: 2
    t.string "tran_type"
    t.string "item_type"
    t.boolean "is_price_range", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area_danji_id"], name: "index_apartment_details_on_area_danji_id"
    t.index ["property_id"], name: "index_apartment_details_on_property_id"
    t.index ["tran_type"], name: "index_apartment_details_on_tran_type"
  end

  create_table "properties", id: :serial, force: :cascade do |t|
    t.string "address"
    t.string "sales_type"
    t.bigint "deposit"
    t.bigint "rent"
    t.string "service_type"
    t.text "description"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "external_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "total_floor"
    t.integer "floor"
    t.string "room_type"
    t.bigint "maintenance_fee"
    t.string "thumbnail_url"
    t.string "geohash"
    t.index ["external_id"], name: "index_properties_on_external_id"
    t.index ["geohash"], name: "index_properties_on_geohash"
    t.index ["latitude", "longitude"], name: "index_properties_on_latitude_and_longitude"
    t.index ["service_type"], name: "index_properties_on_service_type"
  end

  add_foreign_key "apartment_details", "properties"
end
