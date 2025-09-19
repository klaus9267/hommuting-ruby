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

ActiveRecord::Schema[8.0].define(version: 2025_09_19_164022) do
  create_table "properties", force: :cascade do |t|
    t.string "title"
    t.string "address"
    t.string "price"
    t.string "property_type"
    t.string "deal_type"
    t.string "area_description"
    t.string "floor_description"
    t.text "description"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "external_id"
    t.json "raw_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "area_sqm", precision: 8, scale: 2
    t.integer "total_floors"
    t.string "room_structure"
    t.string "maintenance_fee"
    t.integer "current_floor"
    t.index ["deal_type"], name: "index_properties_on_deal_type"
    t.index ["external_id"], name: "index_properties_on_external_id"
    t.index ["latitude", "longitude"], name: "index_properties_on_latitude_and_longitude"
    t.index ["property_type"], name: "index_properties_on_property_type"
  end
end
