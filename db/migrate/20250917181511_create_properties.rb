class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.string :title
      t.string :address
      t.string :price
      t.string :property_type
      t.string :deal_type
      t.string :area
      t.string :floor
      t.text :description
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :external_id
      t.string :source
      t.json :raw_data

      t.timestamps
    end
    
    add_index :properties, :external_id
    add_index :properties, :source
    add_index :properties, [:latitude, :longitude]
    add_index :properties, :property_type
    add_index :properties, :deal_type
  end
end
