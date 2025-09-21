class AddZigbangUrlToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :zigbang_url, :string
  end
end
