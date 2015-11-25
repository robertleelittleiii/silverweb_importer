class Importer < ActiveRecord::Base
  has_many :importer_items
  
  has_many :files, -> { order(:position) },  dependent: :destroy, as: :resource, class_name: "FileAtt",  foreign_key: 'resource_id'

  
end
