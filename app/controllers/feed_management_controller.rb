  
class FeedManagementController < ApplicationController
  # uses "libxml-ruby"
  # requires :xml

  # include FileTools
  #include ThisIsATest

  require 'filetools'
  include FileTools
  
  require 'RMagick'
  include Magick
  
  require "roo"
  require "roo-xls"
  require "rat"
  require 'zip'

  
  IMAGE_TYPES = ["jpg", "gif", "png","jpeg"].freeze
  MAP_FIELD_LIST = [["style-code",0], ["color-code",1]].freeze
  
  FILESTOSHOW = 1

  def importfile
    @filestoshow=FILESTOSHOW
    @importers = Importer.where(:importer_type=>"file").order("name desc")
    @current_importer=:null 
    
    if params[:id].blank? then
    
    
      @files = Dir.glob("public/data_import/*")
      @files = FileAtt.where(:resource_type=> "feed_managment")
      
      @feed_manager = FeedManagement.new()
      puts("feed manager id", @feed_manager.id)
      puts("feed manager name", @feed_manager.name)
      puts("feed manager files", @feed_manager.files)
      puts("feed manager resource type", @feed_manager.resource_type)
    
      # @workbook = Roo::Excelx.new("public/data_import/Master_Surgical_List_(11-15-10).xlsx")
      # @workbook.default_sheet="Sheet1"
      #@name_row=@workbook.row(1)
      #@hashed_name_row=Hash[@name_row.collect { |v| [v, @name_row.index(v)]}]
      #@table_names=Dir.glob(Rails.root + '/app/models/*.rb').collect{|file| File.basename(file,".rb").pluralize}
      #@model_names=Dir.glob(Rails.root + '/app/models/*.rb').collect{|file| File.basename(file,".rb").classify}
      @selected_model=""
      @selected_row=""
      @selected_table=""
    
    else
      @current_importer=params[:id] 
      @importer = Importer.find(params[:id])
      @model_names = ActiveRecord::Base.connection.tables.map{|item| item.classify }
      # @model_list=Dir.glob(Rails.root + '/app/models/*.rb')
      # @model_names=@model_list.collect{|file| File.basename(file,".rb").classify}   
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @customers} 
    end
  end    

  
  def columns_render_partial
    if params[:id].blank? or params[:id]=="null" or params[:id]=="undefined" then
      render nothing: true
    else
      @importer = Importer.find(params[:id])
      @filestoshow=FILESTOSHOW
      file_type = @importer.files[0][:file_info].split(".").last rescue "none"
      
      case file_type
      when "zip"
  
        @map_field_list = [["style-code",0], ["color-code",1]]

        render partial: "columns_zip"
      when "xls", "xlsx", "ods"
        begin
          @model_name=params[:model_name]
          #   @table_columns_part =(@model_name.constantize.column_names + @model_name.constantize.reflect_on_all_associations(:has_many).collect { |each| [ each.active_record.column_names.collect { |each_field| each.name.to_s + "." + each_field }]}).flatten.sort
          @table_columns_part =(@model_name.constantize.column_names + @model_name.constantize.reflect_on_all_associations(:has_many).collect { |each| [ each.name.to_s.classify.constantize.column_names.collect { |each_field| each.name.to_s + "." + each_field rescue "" } ] rescue ""}).flatten.sort

          #    @table_columns_part = @model_name.constantize.column_names
          @table_columns = @table_columns_part.collect{|item|[item, @table_columns_part.index(item)]} 
          #  @table_columns = @model_name.constantize.column_names
        rescue
          @table_columns = []
        end
        
        if params[:model_name] == "Product" then
          @table_columns << ["Tagged[Department]"]
          @table_columns << ["Tagged[Category]"]
        end
           
    
        render partial: "columns"
      else
        render nothing: true
      end
      
    end
  end
  
  def importer_name_partial
    if params[:id]=="" then
      render nothing: true
    else
      @importer_name=params[:importer_name]
      @importer = Importer.find(params[:id])
      puts("nameofimporter:",@importer.name)
      render partial: "importer_name"
    end 
  end
  
  def web_service_info_partial
    if params[:id].blank? then
      render nothing: true
    else
      @importer = Importer.find(params[:id])
      puts("nameofimporter:",@importer.name)
      render partial: "web_services_info"
    end
  end
  
  def set_up_importer_partial
    puts("params ID",params[:id])
     
    if params[:id].blank? then
      render nothing: true
    else
      @importer = Importer.find(params[:id])
      @current_importer=params[:id]
      
      @importers = Importer.all.order("name desc")
      @importers = Importer.where(:importer_type=>params[:importer_type]).order("name desc")

      puts("nameofimporter:",@importer.name)
      
      render partial: "set_up_importer", format: "html"
    end 
  end
  
  def load_importer_progress
    puts("params ID",params[:id])
     
    if params[:id].blank? or params[:id]=="null" then
      render nothing: true
    else
      @importer = Importer.find(params[:id])
      
      render partial: "import_progress_block", format: "html"
    end 
  end
  
  def load_importer_status
     
    if params[:id].blank? then
      render nothing: true
    else
      @importer = Importer.find(params[:id])
      
      render partial: "importer_status", format: "html"
    end 
  end
  
  def import_action_partial
    if params[:id]=="" then
      render nothing: true
    else
      @importer = Importer.find(params[:id])
      @filestoshow = FILESTOSHOW
      file_type = @importer.files[0][:file_info].split(".").last rescue "none"
      
      case file_type
      when "zip"
        image_name = "n/a"
        pathtopublic = Rails.root.to_s + "/public" 
        fullpath = pathtopublic+@importer.files[0].file_info_url
        
        image_file = Zip::File.open(fullpath)
        @file_name = "none found!!"    
        image_file.entries.each_with_index do |each_item, index|
          file_name = each_item.name.split("/").last
          file_extension = file_name.split(".").last
          
          if(not file_name.chars.first == ".") &(not IMAGE_TYPES.index(file_extension).nil?) &  each_item.file? then
            @file_name = each_item.name.split("/").last
            break
          end
        end
        
        if not @importer.columns.blank?
          @field_list = @file_name.split(".")[0].split(@importer.columns).each_with_index.collect.to_a
        end
    
        @map_field_list = [["style-code",0], ["color-code",1]]
        image_file.close
        render partial: "import_action_zip"        
      when "xls", "xlsx", "ods"
        
        # @model_list=Dir.glob(Rails.root + '/app/models/*.rb')
        # @model_names=@model_list.collect{|file| File.basename(file,".rb").classify}
        @model_names = ActiveRecord::Base.connection.tables.map{|item| item.classify }
        @table_columns = {}
     
        render partial: "import_action"        
      when "none"
        render partial: "import_action_new"
      else
        render partial: "import_action_unknown"
      end
    end
  end
  
  def cancel_import
    @mission = Importer.find(params[:id])
    @mission.status="Canceled!"
    @mission.status_percent=100
    @mission.status_message= "Process Complete"
    @mission.end_time = DateTime.now
    @mission.save
    render(text: "canceled")
  end
  
  def xsd_columns_render_partial
    if(not params[:file_path]=="") then

      @pathtopublic = Rails.root.to_s + "/public/"  
      @fullpath = @pathtopublic+params[:file_path]
      
      xml = File.open(@fullpath).read
      source=XML::Parser.string(xml)
      content = source.parse

      
      entries = content.root.find('./xs:element/xs:complexType/xs:choice/xs:element/xs:complexType/xs:sequence/xs:element')
      @table_name = entries[0].attributes["TableNameXsd"]

      @hashed_name_row = Hash[entries.collect { |each| [each.attributes["name"].camelize.gsub(/([^A-Z]+)([^A-Z])*/,"\\1\\2 ").humanize.strip, each.attributes["name"]]}].sort
      
      render partial: "xsd_columns"
       
    else
      render nothing: true
    end  
    
  end
  
  
  def sheet_columns_render_partial
    
    if params[:id].blank? or params[:id]=="null" or params[:id]=="undefined" then
      render nothing: true
    else
      puts("******** ******** ********* ********* ********* ********** ")
      puts("starting....")
      
      @importer = Importer.find(params[:id])
      @filestoshow=FILESTOSHOW
      file_type = @importer.files[0][:file_info].split(".").last rescue "none"
      puts("file_type: #{file_type}")
      
      case file_type
      when "zip"
        image_name = "n/a"
        pathtopublic = Rails.root.to_s + "/public" 
        fullpath = pathtopublic+@importer.files[0].file_info_url
        
        image_file = Zip::File.open(fullpath)
        @file_name = "none found!!"    
        image_file.entries.each_with_index do |each_item, index|
          file_name = each_item.name.split("/").last
          file_extension = file_name.split(".").last
          
          if(not file_name.chars.first == ".") &(not IMAGE_TYPES.index(file_extension).nil?) &  each_item.file? then
            @file_name = each_item.name.split("/").last
            break
          end
        end
        
        if not @importer.columns.blank?
          @field_list = @file_name.split(".")[0].split(@importer.columns).each_with_index.collect.to_a
        end
        
        @workbook_size = "Number of Images:(#{image_file.size.to_s})"
        image_file.close

        render partial: "sheet_columns_zip"
      when "xls", "xlsx", "ods"
        #begin
        if(not params[:file_path]=="") then
     
          @pathtopublic = Rails.root.to_s + "/public/"  
          # @fullpath = @pathtopublic+params[:file_path]
          @fullpath = @pathtopublic + @importer.files[0].file_info_url
          puts("here i am ------------ > ")
          case file_type #File.extname(params[:file_path]).delete!(".")
          when "xls"
            @workbook = Roo::Excel.new(@fullpath)

          when "xlsx"
            @workbook = Roo::Excelx.new(@fullpath)

          when "ods"
            @workbook = Roo::Openoffice.new(@fullpath)
          end
            
          puts("workbook: #{@workbook.inspect}")
          # wb_info=Hash[@workbook.info.scan(/\b(.*):(.*)/)]
          wb_info=Hash[@workbook.info.scan(/\b(.*|\s*):(.*|\s*)/)]
  
          @workbook.default_sheet= @workbook.sheets[0]
          @name_row=@workbook.row(1)
          @hashed_name_row=Hash[@name_row.collect { |v| [v, @name_row.index(v)]}]
          @workbook_size = "Size Cols:("+wb_info["First column"].strip+"..."+wb_info["Last column"].strip + ") by Rows:(" + wb_info["First row"].strip+"..."+wb_info["Last row"].strip+")"
          # puts(@hashed_name_row.inspect)
          render partial: "sheet_columns"
        else
          render nothing: true
        end  
        #rescue
        # render nothing: true
        #end
      else
        render nothing: true
      end
    end
  end
  
  
  def add_importer_item
    @importer = Importer.find(params[:id])
    @importer_item = ImporterItem.new()
      
    @importer_item.from_column=params[:from_column]
    @importer_item.to_column=params[:to_column]
    @importer_item.from_column_name=params[:from_column_name]
    @importer_item.to_column_name=params[:to_column_name]
    @importer_item.to_table_name=params[:to_table_name]
    @importer_item.from_table_name=params[:from_table_name]
    
    @importer_item.save
      
    @importer.importer_items<< @importer_item
    
    #      @file_path=@importer.file_atts[0].file_info_url
    #      
    #      @pathtopublic = Rails.root.to_s + "/public/"  
    #      puts("file path",@pathtopublic+@file_path)
    #      @workbook = Roo::Excelx.new(@pathtopublic+@file_path)
    #      @workbook.default_sheet="Sheet1"
    #      @name_row=@workbook.row(1)
    #      
    #      @hashed_name_row=Hash[@name_row.collect { |v| [v, @name_row.index(v)]}]
    #    
    #      @table_columns_part = @importer.table_name.constantize.column_names rescue {}
    #      @table_columns = @table_columns_part.collect{|item|[item, @table_columns_part.index(item)]}
    #      
    
    render partial: "importer_items_list"
    
  end
  
  def delete_importer
    @importer = Importer.find(params[:id])
    @importer.delete
    
    @current_importer = ""
    @filestoshow=FILESTOSHOW
    @importers = Importer.where(:importer_type=>"file").order("name desc")
    render partial: "set_up_importer"
  end

  def duplicate_importer
    @importer = Importer.find(params[:id])
    @new_importer = @importer.clone
    @new_importer.name = @new_importer.name + " Copy"
    @new_importer.save
    
    @importer.importer_items.each do |item|
      @new_item = item.clone
      @new_item.save
      @new_importer.importer_items << @new_item
    end

    # => This will not work since we are not duplicating the file.
    # todo:  write the code to copy the file as well.    
    #    @importer.file_atts.each do |@file|
    #      @new_file = @file.clone
    #      @new_file.save
    #      @new_importer.file_atts << @new_file
    #    end
    #    
    @current_importer = @new_importer.id
    @filestoshow=FILESTOSHOW
    @importers = Importer.where(:importer_type=>"file").order("name desc")
    render partial: "set_up_importer"
  end

  def add_file_static
  

    format = params[:format]
    file=params[:file]
    @filestoshow = FILESTOSHOW
    puts("file: ",file)
    puts("file.size:",file.size )
    if file.size > 0 then
      @file = FileS.new(file_att: file)
      @file.resource_type="feed_managment"
      @file.resource_id=1
      @file.position=999
      @file.save
    end
    
    @feed_manager = FeedManagement.new()
    puts("files:", @feed_manager.files)   
    
    respond_to do |format|
      flash[:notice] = 'file was successfully added.'
      format.js do
        responds_to_parent do
          render :update do |page|
            page.replace_html("files" , partial: "/files/files" , object: @feed_manager.files)
            if @feed_manager.files.count >= @filestoshow
              page.hide "filebutton"
            end
            page.hide "loader_progress"
            page.show "upload-form"
            page.visual_effect :highlight, "file_#{@file.id}"
            page[:files].show if @feed_manager.files.count >= 1
            page.call "window.setupDelete"
            page.call "window.updateSheetColumns"
          end
        end
      end

      format.html { redirect_to action: 'show', id: params[:id] }
    end
  end

  
  def add_file
    @importer = Importer.find(params[:id])

    format = params[:format]
    file_info=params[:file_info]
    @filestoshow = FILESTOSHOW
    puts("file: ",file_info)
    puts("file.size:",file_info.size )
    if file_info.size > 0 then
      @file = FileAtt.new(file_info: file_info)
      @file.position=999
      @file.name = File.basename(@file.file_info_url)
      file_saved = @file.save
      
      @importer.files<< @file

    end
    
    #  @feed_manager = FeedManagement.new()
    # puts("files:", @importer.file_atts)   
    
    respond_to do |format|
      if file_saved
        format.js   { render :action=>"/files/create.js" }
        format.html { redirect_to @file, :notice=>"File was successfully created." }
        format.json { render :json=>@file, :status=>:created, :location=>@file }
      else
        format.html { render :action=>"new" }
        format.json { render :json=>@file.errors, :status=>:unprocessable_entry }
      end
    end
    
    #    respond_to do |format|
    #      flash[:notice] = 'file was successfully added.'
    #      format.js do
    #        responds_to_parent do
    #          render :update do |page|
    #            page.call "window.import_action_update"
    #
    #            #           page.replace_html("files" , :partial => "/files/files" , :object => @importer.file_atts)
    #            #           if @importer.file_atts.count >= @filestoshow
    #            #            page.hide "filebutton"
    #            #           end
    #            #            page.hide "loader_progress"
    #            #            page.show "upload-form"
    #            #            page.visual_effect :highlight, "file_#{@file.id}"
    #            #            page[:files].show if @importer.file_atts.count >= 1
    #            #            page.call "window.setupDelete"
    #            #            page.call "window.updateSheetColumns"
    #          end
    #        end
    #      end
    #
    #      format.html { redirect_to action: 'show', id: params[:id] }
    #    end
  end

  def render_files 
    @importer = Importer.find(params[:importer_id])
    render(:partial => "/files/files", :object => @importer.files)
  end
  
  def delete_file
    #    @menu = Menu.find(params[:incoming_id])
    @file = FileAtt.find(params[:id])
    @file.destroy
    
    #  respond_to do |format|  
    #          format.html { render :nothing => true }
    #          format.js   { render :nothing => true }  
    #  end  

    # head :deleted
    render nothing: true

    ##    respond_to do |format|
    #      format.js if request.xhr?
    #      format.html {redirect_to :action => 'show', :id=>params[:menu_id]}
    #    end
  end
  
  def delete_import_item
    #    @menu = Menu.find(params[:incoming_id])
    @item = ImporterItem.find(params[:id])
    @item.destroy
    
    #  respond_to do |format|  
    #          format.html { render :nothing => true }
    #          format.js   { render :nothing => true }  
    #  end  

    # head :deleted
    render nothing: true

    ##    respond_to do |format|
    #      format.js if request.xhr?
    #      format.html {redirect_to :action => 'show', :id=>params[:menu_id]}
    #    end
  end
  
  def delete_file_static
    #    @menu = Menu.find(params[:incoming_id])
    @file = FileS.find(params[:id])
    @file.destroy
    
    #  respond_to do |format|  
    #          format.html { render :nothing => true }
    #          format.js   { render :nothing => true }  
    #  end  

    # head :deleted
    render nothing: true

    ##    respond_to do |format|
    #      format.js if request.xhr?
    #      format.html {redirect_to :action => 'show', :id=>params[:menu_id]}
    #    end
  end

  #  def destroy_file
  #    @file = FileS.find(params[:id])
  #    @file.destroy
  #    redirect_to :action => 'show', :id => params[:menu_id]
  #  end

  def update_file_order
    params[:album].each_with_index do |id, position|
      #   Image.update(id, :position => position)
      Picture.reorder(id,position)
    end
    render nothing: true

  end

  def get_sheet
   
    @workbook = Roo::Excelx.new("public/data_import/Master_Surgical_List_(11-15-10).xlsx")
    @workbook.default_sheet="Sheet1"
    @name_row=@workbook.row(1)
    @hashed_name_row=Hash[@name_row.collect { |v| [@name_row.index(v), v]}]

  end 
  
  def create_empty_record
    @importer = Importer.new
    @importer.name=Time.now.to_s
    @importer.importer_type = params[:importer_type]
    @importer.save
    @current_importer=@importer.id
    puts("importer:",@importer.id)
    #        @importer = Importer.find(params[:id])
    # @model_list=Dir.glob(Rails.root + '/app/models/*.rb')
    # @model_names=@model_list.collect{|file| File.basename(file,".rb").classify}  
    @model_names = ActiveRecord::Base.connection.tables.map{|item| item.classify }
    @importers = Importer.where(:importer_type=>params[:importer_type]).order("name desc")

    #  render :partial => "set_up_importer"

    # render :partial=>"set_up_importer"
    #  redirect_to(:action=>:importfile, :id=>@importer, :format=>"html")
    redirect_to(action: :set_up_importer_partial, id: @importer.id, importer_type: params[:importer_type], format: "html")
  end
  
  def import_images_test_old
    
    @test_path = params[:test_path]
    @test_file = params[:test_file]
    puts(@test_path)
    #  directory_hash(@test_path)
    process_zip(@test_path, @test_file)
    render text: "import test complete"
    
  end
  
  def import_images_test
 
    importer_failed = false
    importer= Importer.find(params[:id])
    #  -- cut from here --- 
    image_name = "n/a"
    pathtopublic = Rails.root.to_s + "/public" 
    fullpath = pathtopublic+importer.files[0].file_info_url
    
    importer.status="Start"
    importer.status_percent=1
    importer.status_message="Opening Zipped Image File..."
    importer.save 
    
    image_import_directory = Rails.root.join("tmp", "image_import")

    #
    #set up maping of colors and styles from importer items
    #
    
    style_code_map = importer.importer_items.where(to_column: 0).first.from_column
    color_code_map = importer.importer_items.where(to_column: 1).first.from_column
    
    #
    # make temp dirctory to store file while processing if it doesn't exist
    #
    
    Dir.mkdir(image_import_directory) rescue 0
    
    image_file = Zip::File.open(fullpath)

    begin
      image_file.entries.each_with_index do |each_item, index|
        file_count = image_file.count
      
        entry= each_item.name.split("/").last
         
        file_codes = entry.split(".")
        entry_codes = file_codes[0].split(importer.columns)
      
        if(not entry.chars.first == ".") &(not IMAGE_TYPES.index(file_codes.last).nil?) &  each_item.file? then
     
        
          style_code = entry_codes[style_code_map]
          color_code = entry_codes[color_code_map]
        
          #
          # Extract the file to a temp file for processing
          #
          each_item.extract(Rails.root.join(image_import_directory,entry)) rescue ""
        
          puts("style_code: #{style_code} color_code: #{color_code}")
          if not IMAGE_TYPES.index(file_codes[1]).nil? then
            product = Product.where(supplier_product_id: style_code).first
            if product.blank? then
              puts("product not found") 
            else
              puts(product.inspect)
          
              #
              #first we see if image exists,if it does, we need to remove it before we replace it.  We will destroy each even dups
              #
          
              image_exists = product.pictures.where(image: entry)
              if not image_exists.nil? then
                image_exists.each do |each_item| 
                  each_item.destroy 
                end
              end
              begin
                #
                # process the image to 1000 px wide with 72 dpi and 50% compression as a jpg.
                #
            
                temp_image = ImageList.new(Rails.root.join(image_import_directory,entry))
                temp_image.change_geometry!('1000x')  { |cols, rows, img|
                  img.resize!(cols, rows)
                }
                temp_image.resample()
                temp_image.write(Rails.root.join("tmp",entry)) { self.quality = 50 }
                temp_image.destroy!

                #
                # Then add the imaage to the product
                #
                picture=Picture.create
                picture.image.store!(File.open(Rails.root.join("tmp",entry)))
                File.delete(Rails.root.join("tmp",entry))
          
                picture.save
                image_name = entry
                picture.title = color_code
                picture.save

                product.pictures << picture
                product.save
              rescue Exception => exc
                logger.error("Message for the log file #{exc.message}")
   
                puts("image processing error.#{exc.message}")
              end

            end
          end
          File.delete(Rails.root.join(image_import_directory,entry))

        end
      
        status_percent=Float(Float(index)/Float(file_count)*100)
      
        sleep 1
     
        importer.reload
      
        if(importer.status=="Cancel") then
          importer.status="Canceling..." 
          importer.status_percent=100
          importer.status_message="Process Complete"
          importer.save
          return(false)
        end
      
        importer.status="Processing..." 
        importer.status_percent=status_percent.to_i
        importer.status_message="Processing Image "+ image_name + "(" + index.to_s + " of " + file_count.to_s + ")"
        importer.save
      
      end 
      #rescue importer_failed = true
    rescue Exception => import_exec
      logger.error("Message for the log file #{import_exec.message}")
   
      puts("image processing error.#{import_exec.message}")
    end        
    
    importer.status="Complete"
    importer.status_percent=100
    importer.status_message=(importer_failed ? "Importer Failed" : "Process Complete")
    importer.save

    image_file.close
    
    #-- to here
 
    render text: "import test complete"
  
  end
  
  def import_sheet
    @importer= Importer.find(params[:importer_id])
    if @importer.status=="Processing" or @importer.status == "Start" then
      # file is being processed, take no action.
      puts("Processing in progress.  Take NO ACTION!!")
    else
      
      puts("Starting Processing")
      @importer.status="Start"
      @importer.status_percent=0
      @importer.status_message="Starting Import..."
      @importer.save
    
      file_type = @importer.files[0][:file_info].split(".").last rescue "none"

      case file_type
      when "zip"
        command = "bundle exec rake importer:image_import[#{params[:importer_id]}]"
      when "xls", "xlsx", "ods"
        command = "bundle exec rake importer:data_import[#{params[:importer_id]}]"
      end
      # job = Rat.add("touch at-at", Time.now + 5)

      spawn("echo '#{command}'|at now + 1minute")

      # bundle exec rake importer:data_import[6] 
      #      begin 
      #        if @importer.importer_type=="file" then
      #        file_type = @importer.files[0][:file_info].split(".").last rescue "none"
      #        puts("file_type: #{file_type}")
      #
      #        case file_type
      #        when "zip"
      #          Resque.enqueue(ImageImportProcessor, @importer.id)
      #        when "xls", "xlsx", "ods"
      #          Resque.enqueue(ImportProcessor, @importer.id)
      #        else
      #        end
      #      else
      #        Resque.enqueue(SyncProcessor, @importer.id)
      #      end
      #      rescue
      #        import_sheet_manual
      #      end
      
    end
    
    render nothing: true
    
  end

  def import_sheet_manual
    importer= Importer.find(params[:importer_id])
    
    pathtopublic = Rails.root.to_s + "/public" 
    fullpath = pathtopublic+importer.files[0].file_info_url
    importer.status="Start"
    importer.status_percent=1
    importer.status_message="Opening File..."
    importer.start_time =DateTime.now
    importer.run_count = importer.run_count.to_i  + 1
 
    importer.save 
    
    importer_failed = false
    
    case File.extname(fullpath).delete!(".")
        
    when "xls"
      workbook = Roo::Excel.new(fullpath)

    when "xlsx"
      workbook = Roo::Excelx.new(fullpath)

    when "ods"
      workbook = Roo::Openoffice.new(fullpath)
    end
      
    # wb_info=Hash[workbook.info.scan(/\b(.*):(.*)/)]
    wb_info=Hash[workbook.info.scan(/\b(.*|\s*):(.*|\s*)/)]

    record_count = wb_info["Last row"].to_i * wb_info["Number of sheets"].to_i
    total_row_counter = 0
    
    wb_info["Sheets"].split(",").each_with_index do |sheet_name, index|
      total_row_counter = wb_info["Last row"].to_i * index

      row_counter = 1

      workbook.default_sheet=sheet_name.strip()

      name_row=workbook.row(1) rescue ""
      # How many rows to import


    
      while row_counter <=record_count do
        row_counter+=1
        input_record= Hash.new()
        nilcheck=true
        table_name=importer.table_name
        input_record.merge!(table_name=>{})

        for rule in importer.importer_items
          from_column = rule.from_column.to_i+1
          nilcheck = (nilcheck and (workbook.cell(row_counter,rule.from_column.to_i+1).nil?))
          isRelationship = rule.to_column_name.split(".")
          if (not nilcheck) then
            if isRelationship.size > 1 then
              input_record.merge!(isRelationship[0].classify=>{}) if not input_record.has_key?(isRelationship[0].classify)
              
              # puts("table_name.classify.constantize.columns_hash[isRelationship[1]] #{table_name.classify.constantize.columns_hash[isRelationship[1]].inspect} ")
              
              case isRelationship[0].classify.constantize.columns_hash[isRelationship[1]].type
              when :boolean
                input_record[isRelationship[0].classify].merge!(Hash[isRelationship[1],workbook.cell(row_counter,rule.from_column.to_i+1).to_s.to_i])
              else
                input_record[isRelationship[0].classify].merge!(Hash[isRelationship[1],workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
              end
              # input_record[isRelationship[0].classify].merge!(Hash[isRelationship[1],workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
            else
              case table_name.classify.constantize.columns_hash[rule.to_column_name].type
              when :boolean
                input_record[table_name].merge!(Hash[rule.to_column_name,workbook.cell(row_counter,rule.from_column.to_i+1).to_s.to_i])
              else
                input_record[table_name].merge!(Hash[rule.to_column_name,workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
              end
              #     input_record[table_name].merge!(Hash[rule.to_column_name,workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
            end
          end       
        end
        
        # test for sheet_name attribute in object
        input_record[table_name].merge!(Hash["sheet_name",sheet_name.strip()]) if ((not table_name.classify.constantize.new.attributes.keys.index("sheet_name").blank?) and (not nilcheck))
        #      puts("=====================--------begin----====================")
        #      puts(input_record.inspect)
        if input_record[table_name].length > 0
          if table_name.classify.constantize.respond_to?("key_field") then
            key_field = table_name.classify.constantize.key_field
            nvp_input = input_record[table_name].to_hash
            #            puts("-a--------key field '#{key_field}' = > #{input_record[table_name][key_field]}")
            item = table_name.classify.constantize.find_or_create(key_field => (input_record[table_name][key_field]) )
            #            puts("-a--------item = #{item.inspect}")
            item.update_attributes(input_record[table_name]) 
            #            puts("-a--------update occured")
            item_id = item.id
          else
            begin
              item= table_name.classify.constantize.new(input_record[table_name])
              item.save
            
              item_id=item.id
              #              puts("Item info:#{item.inspect}")
            rescue
              item=table_name.classify.constantize.where(input_record[table_name]).first
              item_id = item.id rescue 0
              #              puts("Update Items: error occured")
            end
          end
          total_row_counter += 1

          importer.reload
          if (importer.status=="Cancel") then
            importer.status="Canceling" 
            importer.status_percent=100
            importer.status_message="Process Complete"
            importer.end_time = DateTime.now
            importer.save
            return(false)
          end
          
          status_percent=Float(Float(total_row_counter)/Float(record_count)*100)
          importer.status="Processing" 
          importer.status_percent=status_percent.to_i
          importer.status_message="Processing Record " + total_row_counter.to_s + " of " + record_count.to_s
          importer.save
          #          puts(":#{status_percent}#{}")
          
          input_record.each_pair do |item_key, item_value|
            #
            #           puts("-b---------table #{item_key}, hash:#{item_value.inspect}")
            if (item_key != table_name) then
              if item_key.classify.constantize.respond_to?("key_field") then
                key_field = item_key.classify.constantize.key_field
                #                puts("-b--------sub item key field '#{key_field}' = > #{item_value[key_field]}")

                item = item_key.classify.constantize.find_or_create(key_field => (item_value[key_field]) )
                item.send("#{table_name.tableize.singularize}_id=", item_id)

                result1 = item.save
                result2 = item.update_attributes(item_value)
                #                puts("-b--------result1'#{result1}' result2 '#{result2}"'')
              else
                begin
                  sub_item= item_key.classify.constantize.new(item_value)
                  #                  puts("-b---------p:#{table_name.tableize.singularize}_id=#{item_id.to_s}")
                  sub_item.send("#{table_name.tableize.singularize}_id=", item_id)
                  sub_item.save
                  #                  puts("-b--------update occured")

                rescue
                  puts("Updateing Table #{item_key}, an error occured.")
                end
              end
            end
          end

          #        if (not nilcheck) then
          #
          #          table_name=importer.table_name
          #        
          #          item= table_name.classify.constantize.new(input_record)
          #        
          #          item.save
          #          status_percent=Float(Float(total_row_counter)/Float(record_count)*100)
          #          importer.status="Processing File" 
          #          importer.status_percent=status_percent.to_i
          #          importer.status_message="Processing Record " + total_row_counter.to_s + " of " + record_count.to_s
          #          importer.save
          #        end
      
      
        end  
    
      end
    end rescue importer_failed = true
    
    
    importer.status="Complete"
    importer.status_percent=100
    importer.status_message= (importer_failed ? "Importer Failed" : "Process Complete")
    importer.end_time = DateTime.now
    importer.save
    
    # render :nothing=>true

  end
  
  def import_sheet_test
    importer= Importer.find(params[:importer_id])
    
    pathtopublic = Rails.root.to_s + "/public" 
    fullpath = pathtopublic+importer.files[0].file_info_url
    importer.status="Start"
    importer.status_percent=1
    importer.status_message="Opening File..."
    importer.start_time =DateTime.now
    importer.run_count = importer.run_count.to_i  + 1
 
    importer.save 
    
    case File.extname(fullpath).delete!(".")
        
    when "xls"
      workbook = Roo::Excel.new(fullpath)

    when "xlsx"
      workbook = Roo::Excelx.new(fullpath)

    when "ods"
      workbook = Roo::Openoffice.new(fullpath)
    end
      
    #wb_info=Hash[workbook.info.scan(/\b(.*):(.*)/)]
    wb_info=Hash[workbook.info.scan(/\b(.*|\s*):(.*|\s*)/)]
  
    record_count = wb_info["Last row"].to_i * wb_info["Number of sheets"].to_i
    total_row_counter = 0
    
    wb_info["Sheets"].split(",").each_with_index do |sheet_name, index|
      total_row_counter = wb_info["Last row"].to_i * index

      row_counter = 1

      workbook.default_sheet=sheet_name.strip()

      name_row=workbook.row(1) rescue ""
      # How many rows to import


    
      while row_counter <=record_count do
        row_counter+=1
        input_record= Hash.new()
        nilcheck=true
        table_name=importer.table_name
        input_record.merge!(table_name=>{})

        for rule in importer.importer_items
          from_column = rule.from_column.to_i+1
          nilcheck = (nilcheck and (workbook.cell(row_counter,rule.from_column.to_i+1).nil?))
          isRelationship = rule.to_column_name.split(".")
          if (not nilcheck) then
            if isRelationship.size > 1 then
              input_record.merge!(isRelationship[0].classify=>{}) if not input_record.has_key?(isRelationship[0].classify)
              case table_name.classify.constantize.columns_hash[isRelationship[1]].type
              when :boolean
                input_record[isRelationship[0].classify].merge!(Hash[isRelationship[1],workbook.cell(row_counter,rule.from_column.to_i+1).to_s.to_i])
              else
                input_record[isRelationship[0].classify].merge!(Hash[isRelationship[1],workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
              end
              # input_record[isRelationship[0].classify].merge!(Hash[isRelationship[1],workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
            else
              case table_name.classify.constantize.columns_hash[rule.to_column_name].type
              when :boolean
                input_record[table_name].merge!(Hash[rule.to_column_name,workbook.cell(row_counter,rule.from_column.to_i+1).to_s.to_i])
              else
                input_record[table_name].merge!(Hash[rule.to_column_name,workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
              end
              #     input_record[table_name].merge!(Hash[rule.to_column_name,workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
            end
          end       
        end
        
        # test for sheet_name attribute in object
        input_record[table_name].merge!(Hash["sheet_name",sheet_name.strip()]) if ((not table_name.classify.constantize.new.attributes.keys.index("sheet_name").blank?) and (not nilcheck))
        #      puts("=====================--------begin----====================")
        #      puts(input_record.inspect)
        if input_record[table_name].length > 0
          if table_name.classify.constantize.respond_to?("key_field") then
            key_field = table_name.classify.constantize.key_field
            nvp_input = input_record[table_name].to_hash
            #            puts("-a--------key field '#{key_field}' = > #{input_record[table_name][key_field]}")
            item = table_name.classify.constantize.find_or_create(key_field => (input_record[table_name][key_field]) )
            #            puts("-a--------item = #{item.inspect}")
            item.update_attributes(input_record[table_name]) 
            #            puts("-a--------update occured")
            item_id = item.id
          else
            begin
              item= table_name.classify.constantize.new(input_record[table_name])
              item.save
            
              item_id=item.id
              #              puts("Item info:#{item.inspect}")
            rescue
              item=table_name.classify.constantize.where(input_record[table_name]).first
              item_id = item.id rescue 0
              #              puts("Update Items: error occured")
            end
          end
          total_row_counter += 1

          importer.reload
          if (importer.status=="Cancel") then
            importer.status="Canceling" 
            importer.status_percent=100
            importer.status_message="Process Complete"
            importer.end_time = DateTime.now
            importer.save
            return(false)
          end
          
          status_percent=Float(Float(total_row_counter)/Float(record_count)*100)
          importer.status="Processing" 
          importer.status_percent=status_percent.to_i
          importer.status_message="Processing Record " + total_row_counter.to_s + " of " + record_count.to_s
          importer.save
          #          puts(":#{status_percent}#{}")
          
          input_record.each_pair do |item_key, item_value|
            #
            #           puts("-b---------table #{item_key}, hash:#{item_value.inspect}")
            if (item_key != table_name) then
              if item_key.classify.constantize.respond_to?("key_field") then
                key_field = item_key.classify.constantize.key_field
                #                puts("-b--------sub item key field '#{key_field}' = > #{item_value[key_field]}")

                item = item_key.classify.constantize.find_or_create(key_field => (item_value[key_field]) )
                item.send("#{table_name.tableize.singularize}_id=", item_id)

                result1 = item.save
                result2 = item.update_attributes(item_value)
                #                puts("-b--------result1'#{result1}' result2 '#{result2}"'')
              else
                begin
                  sub_item= item_key.classify.constantize.new(item_value)
                  #                  puts("-b---------p:#{table_name.tableize.singularize}_id=#{item_id.to_s}")
                  sub_item.send("#{table_name.tableize.singularize}_id=", item_id)
                  sub_item.save
                  #                  puts("-b--------update occured")

                rescue
                  puts("Updateing Table #{item_key}, an error occured.")
                end
              end
            end
          end

          #        if (not nilcheck) then
          #
          #          table_name=importer.table_name
          #        
          #          item= table_name.classify.constantize.new(input_record)
          #        
          #          item.save
          #          status_percent=Float(Float(total_row_counter)/Float(record_count)*100)
          #          importer.status="Processing File" 
          #          importer.status_percent=status_percent.to_i
          #          importer.status_message="Processing Record " + total_row_counter.to_s + " of " + record_count.to_s
          #          importer.save
          #        end
      
      
        end  
    
      end
    end rescue importer_failed = true
    
    
    importer.status="Complete"
    importer.status_percent=100
    importer.status_message= (importer_failed ? "Importer Failed" : "Process Complete")
    importer.end_time = DateTime.now
    importer.save
    
    render nothing: true

  end
  
  def import_sheet_OLD
    # get the importer to use by importer_id
   
    @importer= Importer.find(params[:importer_id])
    
    
    @pathtopublic = Rails.root.to_s + "/public"  
    @fullpath = @pathtopublic+@importer.files[0].file_info_url
      
    case File.extname(@fullpath).delete!(".")
        
    when "xls"
      @workbook = Roo::Excel.new(@fullpath)

    when "xlsx"
      @workbook = Roo::Excelx.new(@fullpath)

    when "ods"
      @workbook = Roo::Openoffice.new(@fullpath)
    end
      
    #wb_info=Hash[@workbook.info.scan(/\b(.*):(.*)/)]
    wb_info=Hash[workbook.info.scan(/\b(.*|\s*):(.*|\s*)/)]
  
    record_count = wb_info["Last row"].to_i * wb_info["Number of sheets"].to_i
    total_row_counter = 0
    
    wb_info["Sheets"].split(",").each do |sheet_name|
      #  @workbook.default_sheet="Billabong"
      row_counter = 1

      @workbook.default_sheet=sheet_name.strip()

      @name_row=@workbook.row(1)
      # How many rows to import

 
      while row_counter <=record_count do
        total_row_counter+=1
        row_counter+=1
        input_record= Hash.new()
        nilcheck=true
        @table_name=@importer.table_name
        
        input_record.merge!(@table_name=>{})
        
        for rule in @importer.importer_items
          column_count=rule.from_column.to_i+1
          nilcheck =(nilcheck and(@workbook.cell(row_counter,rule.from_column.to_i+1).nil?))
          isRelationship = rule.to_column_name.split(".")
          if(not nilcheck) then
            if isRelationship.size > 1 then
              input_record.merge!(isRelationship[0].classify=>{}) if not input_record.has_key?(isRelationship[0].classify)
              input_record[isRelationship[0].classify].merge!(Hash[isRelationship[1],@workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
            else
              input_record[@table_name].merge!(Hash[rule.to_column_name,@workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
            end
          end
        end
        # test for sheet_name attribute in object
        input_record[@table_name].merge!(Hash["sheet_name",sheet_name.strip()]) if((not @table_name.classify.constantize.new.attributes.keys.index("sheet_name").blank?) and(not nilcheck))

        if input_record[@table_name].length > 0
          
          begin
            @item= @table_name.classify.constantize.new(input_record[@table_name])
            @item.save
            @item_id=@item.id
            puts("Item info:#{@item.inspect}")
          rescue
            @item=@table_name.classify.constantize.where(input_record[@table_name]).first
            @item_id = @item.id rescue 0
            puts("error occured")
          end
        
          
          input_record.each_pair do |item_key, item_value|
            puts("table #{item_key}, hash:#{item_value.inspect}")
            if(item_key != @table_name) then
              begin
                @sub_item= item_key.classify.constantize.new(item_value)
                puts("p:#{@table_name.tableize.singularize}_id=#{@item_id.to_s}")
                @sub_item.send("#{@table_name.tableize.singularize}_id=", @item_id)
                @sub_item.save
              rescue
                puts("error occured")
              end
            end
          end
        end

        #        if(not nilcheck) then
        #      
        #          puts(input_record.inspect)
        #
        #          @table_name=@importer.table_name
        #        
        #          begin 
        #            @item= @table_name.classify.constantize.new(input_record)
        #          
        #            @item.save
        #          rescue
        #            puts("Error: Table not found#{@table_name}")
        #          end
        #        
        #        
        #        else
        #          puts("x")
        #          puts("x")
        #          puts("x")
        #          puts("nil record, ignored")
        #        end
        #        
        puts(input_record.inspect)
      
          
 
        #  break if i == 2
      end 
    
    end 
    @hashed_name_row=Hash[@name_row.collect { |v| [v, @name_row.index(v)]}]
    render nothing: true
  end
  

  def webservicesync
    @filestoshow=FILESTOSHOW
    @importers = Importer.where(:importer_type=>"web-service").order("name desc")
    @current_importer=:null 
    
    if params[:id].blank? then
    
    
      @files = Dir.glob("public/data_import/*")
      @files = FileAtt.where(:resource_type=>"feed_managment")
      
      @feed_manager = FeedManagement.new()
      puts("feed manager id", @feed_manager.id)
      puts("feed manager name", @feed_manager.name)
      puts("feed manager files", @feed_manager.files)
      puts("feed manager resource type", @feed_manager.resource_type)
    
      @workbook = Roo::Excelx.new("public/data_import/Master_Surgical_List_(11-15-10).xlsx")
      @workbook.default_sheet="Sheet1"
      @name_row=@workbook.row(1)
      @hashed_name_row=Hash[@name_row.collect { |v| [v, @name_row.index(v)]}]
      @table_columns =(Pricing.column_names + Product.reflect_on_all_associations(:has_many).collect { |each| [ each.active_record.column_names.collect { |each_field| each.name.to_s + "." + each_field }]}).flatten.sort
      @table_names=Dir.glob(Rails.root + '/app/models/*.rb').collect{|file| File.basename(file,".rb").pluralize}
      @model_names = ActiveRecord::Base.connection.tables.map{|item| item.classify }
      #@model_names=Dir.glob(Rails.root + '/app/models/*.rb').collect{|file| File.basename(file,".rb").classify}
      @selected_model=""
      @selected_row=""
      @selected_table=""
    
    else
      @current_importer=params[:id] 
      @importer = Importer.find(params[:id])
      @model_names = ActiveRecord::Base.connection.tables.map{|item| item.classify }
      # @model_list=Dir.glob(Rails.root + '/app/models/*.rb')
      # @model_names=@model_list.collect{|file| File.basename(file,".rb").classify}   
    end
    
  
  end

  def generate_request
    @importer= Importer.find(params[:importer_id])
     
    @table_name=@importer.table_name
        
    @table_data= @table_name.classify.constantize.find(:all)
    uri_command="Insert-Update"
    puts(@table_data.inspect)
    uri_string= @importer.full_uri_path + "?" + "login=" + @importer.login_id + "&" + "EncryptedPassword=" + @importer.password + "&" + "Import=" + uri_command 
    uri = URI.parse(uri_string)
      
    #  uri=URI.parse('http://v833920.e3wxp2dno7n6.demo5.volusion.com/net/WebService.aspx?Login=little@mac.com&EncryptedPassword=0E0517191356E9B4977B38E3E51B1F4928014F95B31FC2AC8E75C50501E12D6C&Import=Insert')

    http=Net::HTTP.new(uri.host,uri.port)
    path= uri.path + "?" + uri.query
    # path=('/net/WebService.aspx?Login=little@mac.com&EncryptedPassword=0E0517191356E9B4977B38E3E51B1F4928014F95B31FC2AC8E75C50501E12D6C&Import=Insert')

       
      
      
      
      
    api_header="<?xml version=\"1.0\" encoding=\"utf-8\" ?> <xmldata> "  
    api_footers= "</xmldata>"
     
    record_count = @table_data.count-1
    record_count = 10
    
    row_counter = 1
    while row_counter <=record_count do
      api_from_table_name_start = "<"+@importer.importer_items[0].from_table_name+">" rescue ""
      api_insert_fields = ""
      for rule in @importer.importer_items
        puts(row_counter.to_s + ":" + rule.from_column + "=>" + rule.to_column_name+"("+((eval("@table_data[row_counter]."+rule.to_column_name.gsub(/[.]/,'[0].')) rescue "").to_s.strip||"")+")")
        rule_value =((eval("@table_data[row_counter]."+rule.to_column_name.gsub(/[.]/,'[0].')) rescue "").to_s.strip||"")  
        puts(@table_data[row_counter].inspect)
        api_insert_fields = api_insert_fields + "<" + rule.from_column + ">" + rule_value + "</" + rule.from_column + ">"
      end
      api_from_table_name_end = "</"+@importer.importer_items[0].from_table_name+">" rescue ""
       
      api_data = api_header+ api_from_table_name_start+api_insert_fields+api_from_table_name_end+api_footers
      
        
        
      puts(api_data)
      response=http.post(path, api_data) 
      puts(response)
      #puts(input_record.inspect)
      
          
 
      #  break if i == 2
      
      row_counter+=1

    end 
    render nothing: true
      
  end
  
  
  def from_xml_to_database
    @importer= Importer.find(params[:importer_id])
     
    @table_name=@importer.table_name
        
    # @table_data= @table_name.classify.constantize.find(:all)
    # uri_command="Insert-Update"
    # puts(@table_data.inspect)
    # uri_string= @importer.full_uri_path + "?" + "login=" + @importer.login_id + "&" + "EncryptedPassword=" + @importer.password + "&" + "Import=" + uri_command 
    # uri = URI.parse(uri_string)
      
    #  uri=URI.parse('http://v833920.e3wxp2dno7n6.demo5.volusion.com/net/WebService.aspx?Login=little@mac.com&EncryptedPassword=0E0517191356E9B4977B38E3E51B1F4928014F95B31FC2AC8E75C50501E12D6C&Import=Insert')

    # http=Net::HTTP.new(uri.host,uri.port)
    # path= uri.path + "?" + uri.query
    # path=('/net/WebService.aspx?Login=little@mac.com&EncryptedPassword=0E0517191356E9B4977B38E3E51B1F4928014F95B31FC2AC8E75C50501E12D6C&Import=Insert')

       
      
      
      
      
    # api_header="<?xml version=\"1.0\" encoding=\"utf-8\" ?> <xmldata> "  
    # api_footers= "</xmldata>"
    
     
    pathtopublic = Rails.root.to_s + "/public/data_import" 
    fullpath = pathtopublic + "/" + "products_export.xml"
    xml = File.open(fullpath).read
    
    # uri_string= @importer.full_uri_path + "?" + "login=" + @importer.login_id + "&" + "EncryptedPassword=" + @importer.password + "&" + "Import=" + uri_command 
    uri=URI.parse('http://rmrkz.cpgnd.servertrust.com/net/WebService.aspx?Login=avenelpharmacy@gmail.com&EncryptedPassword=7E23F162AC864A0EF33E9F0D991C8077B3B4C9E8FCF6CDE8DA9F1B4ABABE6719&EDI_Name=Generic\\Products&SELECT_Columns=*')
    http=Net::HTTP.new(uri.host,uri.port)
    response=http.get(uri.path+"?"+uri.query)
    response.body
    
    source=XML::Parser.string(xml)
    content = source.parse
    entries = content.find("Products")
     
     
    theHash = Hash[test.entries.collect { |each| [each.name, each.content]}]

     
     
    record_count = @table_data.count-1
    record_count = 10
    
    row_counter = 1
    while row_counter <=record_count do
      api_from_table_name_start = "<"+@importer.importer_items[0].from_table_name+">" rescue ""
      api_insert_fields = ""
      for rule in @importer.importer_items
        puts(row_counter.to_s + ":" + rule.from_column + "=>" + rule.to_column_name+"("+((eval("@table_data[row_counter]."+rule.to_column_name.gsub(/[.]/,'[0].')) rescue "").to_s.strip||"")+")")
        rule_value =((eval("@table_data[row_counter]."+rule.to_column_name.gsub(/[.]/,'[0].')) rescue "").to_s.strip||"")  
        puts(@table_data[row_counter].inspect)
        api_insert_fields = api_insert_fields + "<" + rule.from_column + ">" + rule_value + "</" + rule.from_column + ">"
      end
      api_from_table_name_end = "</"+@importer.importer_items[0].from_table_name+">" rescue ""
       
      api_data = api_header+ api_from_table_name_start+api_insert_fields+api_from_table_name_end+api_footers
      
        
        
      puts(api_data)
      response=http.post(path, api_data) 
      puts(response)
      #puts(input_record.inspect)
      
          
 
      #  break if i == 2
      
      row_counter+=1

    end 
    render nothing: true
      
  end
  
  
  
end
