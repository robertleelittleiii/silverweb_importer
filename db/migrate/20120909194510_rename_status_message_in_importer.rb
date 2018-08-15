class RenameStatusMessageInImporter < ActiveRecord::Migration[4.2]
  def self.up
  begin
    rename_column :importers, :stauts_message, :status_message
  rescue 
  end
  end

  def self.down
        rename_column :importers, :status_message, :stauts_message

  end
end
