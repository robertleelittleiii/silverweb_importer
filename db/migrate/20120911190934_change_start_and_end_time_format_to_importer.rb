class ChangeStartAndEndTimeFormatToImporter < ActiveRecord::Migration
  def self.up
    
    change_column :importers, :start_time, :datetime
    change_column :importers, :end_time, :datetime
  end

  def self.down
    change_column :importers, :start_time, :time
    change_column :importers, :end_time, :time
  end
end

