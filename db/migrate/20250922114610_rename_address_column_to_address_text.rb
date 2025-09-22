class RenameAddressColumnToAddressText < ActiveRecord::Migration[8.0]
  def change
    rename_column :properties, :address, :address_text
  end
end
