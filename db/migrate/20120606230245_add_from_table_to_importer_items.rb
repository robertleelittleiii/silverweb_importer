class AddFromTableToImporterItems < ActiveRecord::Migration[4.2]
  def self.up
begin
  add_column :importer_items, :from_table_name, :string
rescue
end
  end

  def self.down
    remove_column :importer_items, :from_table_name
  end
end
