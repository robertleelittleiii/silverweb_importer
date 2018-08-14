class CreateImporters < ActiveRecord::Migration
  def self.up
    if not ActiveRecord::Base.connection.table_exists? 'importers' then
      create_table :importers do |t|
      t.string :name
      t.string :full_file_name
      t.text :columns
      t.string :table_name

      t.timestamps
    end
     end
  end

  def self.down
    drop_table :importers
  end
end
