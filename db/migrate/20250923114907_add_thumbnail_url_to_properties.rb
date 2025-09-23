class AddThumbnailUrlToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :thumbnail_url, :string
  end
end
