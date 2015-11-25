class AddStartAndEndTimeToImporter < ActiveRecord::Migration
  def self.up
    add_column :importers, :start_time, :time
    add_column :importers, :end_time, :time
    add_column :importers, :run_count, :integer
  end

  def self.down
    remove_column :importers, :end_time
    remove_column :importers, :start_time
    remove_column :importers, :run_count

    
  end
end
