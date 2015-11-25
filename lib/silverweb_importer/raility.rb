module SilverwebImporter
  class Railtie < Rails::Railtie
    #    initializer "silverweb_portfolio.action_controller" do
    #      ActiveSupport.on_load(:action_controller) do
    #        puts "Extending #{self} with silverweb_portfolio"
    #        # ActionController::Base gets a method that allows controllers to include the new behavior
    #        include SilverwebPortfolio::ControllerExtensions # ActiveSupport::Concern
    #        config.to_prepare do
    #      SiteController.send(:include, SilverwebPortfolio::ControllerExtensions::SiteControllerExtensions)
    #    end
    #      end
    #    end
    
    # The block you pass to this method will run for every request in
    # development mode, but only once in production.
    
 
    initializer "silverweb_importer.update_picture_model" do      
    
      SilverwebCms::Config.add_nav_item({name: "Importer", controller: 'feed_management', action: 'importfile'})

    end
    
  end
end