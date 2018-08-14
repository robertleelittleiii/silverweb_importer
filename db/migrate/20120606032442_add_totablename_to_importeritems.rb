class AddTotablenameToImporteritems < ActiveRecord::Migration
  def self.up
    begin
      add_column :importer_items, :to_table_name, :string
    rescue
    end
  end

  def self.down
    remove_column :importer_items, :to_table_name
  end
end
