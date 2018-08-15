class CreateImporterItems < ActiveRecord::Migration[4.2]
  def self.up
    if not ActiveRecord::Base.connection.table_exists? 'importer_items' then
      create_table :importer_items do |t|
        t.integer :importer_id
        t.integer :from_column
        t.string :from_column_name
        t.integer :to_column
        t.string :to_column_name

        t.timestamps
      end
    end
  end

  def self.down
    drop_table :importer_items
  end
end
