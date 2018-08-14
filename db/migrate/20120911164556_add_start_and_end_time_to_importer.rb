class AddStartAndEndTimeToImporter < ActiveRecord::Migration
  def self.up
 begin
   add_column :importers, :start_time, :time
    add_column :importers, :end_time, :time
    add_column :importers, :run_count, :integer
 rescue
 end
  end

  def self.down
    remove_column :importers, :end_time
    remove_column :importers, :start_time
    remove_column :importers, :run_count

    
  end
end
