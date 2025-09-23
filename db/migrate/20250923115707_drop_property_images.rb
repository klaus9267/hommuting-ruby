class DropPropertyImages < ActiveRecord::Migration[8.0]
  def change
    drop_table :property_images do |t|
      t.bigint "property_id", null: false
      t.string "thumbnail_url"
      t.text "image_urls", default: [], array: true
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["property_id"], name: "index_property_images_on_property_id"
    end
  end
end
