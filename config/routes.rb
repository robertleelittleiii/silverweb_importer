Rails.application.routes.draw do
  
  resources :importer_items do
    collection do
      get "create_empty_record"
    end
  end
  
  resources :importers do
    collection do
      get "create_empty_record"
    end
  end

  resources :file_atts do
    collection do
      
    end
  end
  
  resources :feed_management do
    collection do
      get "create_empty_record"
      get "importfile"
      get "webservciessync"
      get "set_up_importer_partial"
      post "add_file"
      get "add_file_static"
      post "add_importer_item"
      get "cancel_import"
      post "columns_render_partial"
      get "delete_file"
      get "delete_file_static"
      post "delete_import_item"
      post "delete_importer"
      post "duplicate_importer"
      get "from_xml_to_database"
      get "generate_request"
      get "get_sheet"
      post "import_action_partial"
      get "import_images_test"
      get "import_images_test_old"
      post "import_sheet"
      get "import_sheet_manual"
      get "import_sheet_OLD"
      get "import_sheet_test"
      post "importer_name_partial"
      get "importfile"
      post "load_importer_progress"
      post "load_importer_status"
      post "set_up_importer_partial"
      post "sheet_columns_render_partial"
      get "sheet_columns_render_partial"
      get "update_file_order"
      get "web_service_info_partial"
      get "webservicesync"
      get "xsd_columns_render_partial"
      get "render_files"
    end
  end
  
  get "feed_management/importfile"

  get "feed_management/webservicesync"
  
end
