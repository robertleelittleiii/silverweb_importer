class CreateFileAtts < ActiveRecord::Migration[4.2]
  def self.up
    if not ActiveRecord::Base.connection.table_exists? 'file_atts' then
      create_table :file_atts do |t|
        t.string :name
        t.text :description
        t.integer :position
        t.string :file_info
        t.integer :resource_id
        t.string :resource_type

        t.timestamps
      end
    end
  end

  def self.down
    drop_table :file_atts
  end
end
