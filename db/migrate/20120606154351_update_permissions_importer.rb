class UpdatePermissionsImporter < ActiveRecord::Migration[4.2]
  def self.up
    #assign them to Admin role.
    role_admin =  Role.find_by_name('Admin')
    role_cust =  Role.find_by_name('Customer')
    role_siteowner =  Role.find_by_name('Site Owner')


    right = Right.create name: "*Access to all Importer actions", controller: "feed_management", action: "*"
    role_admin.rights << right
    role_siteowner.rights << right
    
    role_siteowner.save
    role_cust.save
    role_admin.save 
  end

  def self.down
    #Destroy all rights    
    right = Right.find_by_name( "*Access to all Importer actions")
    right.destroy  rescue puts("order feed_management not found.")
    
  end
end
