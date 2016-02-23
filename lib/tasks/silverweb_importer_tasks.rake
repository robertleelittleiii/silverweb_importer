# desc "Explaining what the task does"
# task :silverweb_importer do
#   # Task goes here
# end
require "roo"
require "roo-xls"
require "zip"
require 'RMagick'
include Magick

IMAGE_TYPES = ["jpg", "gif", "png","jpeg"].freeze
MAP_FIELD_LIST = [["style-code",0], ["color-code",1]].freeze

namespace :importer do
  desc "Recurring Update of Scales Data for All Tables."
  task :data_import, [:importer_id] => :environment   do |task, params|
    puts("importer_id is #{params[:importer_id]}")
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
          if rule.to_column_name.include?("Tagged[") then
            input_record.merge!("Tagged"=>{}) if not input_record.has_key?("Tagged")
            input_record["Tagged"].merge!(Hash[rule.to_column_name,workbook.cell(row_counter,rule.from_column.to_i+1).to_s])
          else
            if (not nilcheck) then
              if isRelationship.size > 1 then
                input_record.merge!(isRelationship[0].classify=>{}) if not input_record.has_key?(isRelationship[0].classify)
              
                puts("table_name.classify.constantize.columns_hash[isRelationship[1]] #{table_name.classify.constantize.columns_hash[isRelationship[1]].inspect} ")
              
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
                  input_record[table_name].merge!(Hash[rule.to_column_name,workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.force_encoding("ASCII-8BIT").delete(160.chr+194.chr)])
                end rescue puts("rule.to_column_name not found #{rule.to_column_name}")
                #     input_record[table_name].merge!(Hash[rule.to_column_name,workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.delete(160.chr+194.chr)])
              end
            end
          end
          puts("rule.to_column_name: #{rule.to_column_name}")
          puts("Value: #{workbook.cell(row_counter,rule.from_column.to_i+1).to_s.strip.force_encoding("ASCII-8BIT").delete(160.chr+194.chr)}")

        end
        
        # test for sheet_name attribute in object
        input_record[table_name].merge!(Hash["sheet_name",sheet_name.strip()]) if ((not table_name.classify.constantize.new.attributes.keys.index("sheet_name").blank?) and (not nilcheck))
        puts("=====================--------begin----====================")
        puts(input_record.inspect)
        
        
        if input_record[table_name].length > 0
          if table_name.classify.constantize.respond_to?("key_field") then
            key_field = table_name.classify.constantize.key_field
            nvp_input = input_record[table_name].to_hash
            puts("-a--------key field '#{key_field}' = > #{input_record[table_name][key_field]}")
            item = table_name.classify.constantize.find_or_create(key_field => (input_record[table_name][key_field]) )
            puts("-a--------item = #{item.inspect}")
            item.update_attributes(input_record[table_name]) 
            puts("-a--------update occured")
            item_id = item.id
          else
            begin
              item= table_name.classify.constantize.new(input_record[table_name])
              item.save
            
              item_id=item.id
              puts("Item info:#{item.inspect}")
            rescue
              item=table_name.classify.constantize.where(input_record[table_name]).first
              item_id = item.id rescue 0
              puts("Update Items: error occured")
            end
          end
       
          #          if rule.to_column_name = "Tagged[Department]"     
          #          item.department_list.add()
          #          end 
          #        
          #          if rule.to_column_name = "Tagged[Category]"     
          #                    item.category_list.add()
          #          end
        
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
            puts("-b---------table #{item_key}, hash:#{item_value.inspect}")
            if (item_key != table_name) then
              if item_key == "Tagged" then
                puts("item was tagged! #{item_key.inspect}, #{item_value.inspect}")
                puts("item: == > #{item.inspect}")
                item_value.each_pair do |sub_item_key, sub_item_value|

                  case sub_item_key 
                  when "Tagged[Department]"
                    puts("updated departement!!!")
                    item.department_list.add(sub_item_value)
                    item.save rescue ""
                  when "Tagged[Category]"
                    puts("updated category!!!")
                    item.category_list.add(sub_item_value)
                    item.save rescue ""
                  end
                  puts("subitem was tagged! #{sub_item_key}, #{sub_item_value}")

                end
                
              elsif item_key.classify.constantize.respond_to?("key_field") then
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
    end# rescue importer_failed = true
    
    
    importer.status="Complete"
    importer.status_percent=100
    importer.status_message= (importer_failed ? "Importer Failed" : "Process Complete")
    importer.end_time = DateTime.now
    importer.save
    
  
  end
  
  
  task :image_import, [:importer_id] => :environment   do |task, params|
    puts("importer_id is #{params[:importer_id]}")
    importer= Importer.find(params[:importer_id])
    
    image_name = "n/a"
    pathtopublic = Rails.root.to_s + "/public" 
    fullpath = pathtopublic+importer.files[0].file_info_url
    
    importer.status="Start"
    importer.status_percent=1
    importer.status_message="Opening Zipped Image File..."
    importer.start_time =DateTime.now
    importer.run_count = importer.run_count.to_i  + 1
    importer.save 
    
    importer_failed = false
   
    image_import_directory = Rails.root.join("tmp", "image_import")

    
    style_code_map = importer.importer_items.where(:to_column=>0).first.from_column rescue 0
    color_code_map = importer.importer_items.where(:to_column=>1).first.from_column rescue 1
 
    
    Dir.mkdir(image_import_directory) rescue 0
    
    image_file = Zip::File.open(fullpath)
    puts("Image_file = #{image_file.entries.size}")
    
    begin
      image_file.entries.each_with_index do |each_item, index|
        puts("Start---> #{each_item} file count: #{index}")
        file_count = image_file.count
      
        entry= each_item.name.split("/").last
         
        file_codes = entry.split(".")
        entry_codes = file_codes[0].split(importer.columns)
      
        if (not entry.chars.first == ".") & (not IMAGE_TYPES.index(file_codes.last).nil?) &  each_item.file? then
     
        
          style_code = entry_codes[style_code_map]
          color_code = entry_codes[color_code_map] rescue ""
        
          #
          # Extract the file to a temp file for processing
          #
          each_item.extract(Rails.root.join(image_import_directory,entry)) rescue ""
        
          if not IMAGE_TYPES.index(file_codes[1]).nil? then
            product = Product.where(:supplier_product_id => style_code).first
            if product.blank? then
              puts("style_code: #{style_code} color_code: #{color_code}")
              puts("Product not found with style code!!") 
              image_name = entry  
            else
              puts("style_code: #{style_code} color_code: #{color_code}")

              puts(product.inspect)
              puts("------ p r o d u c t  p r o c e s s e d -----")
          
              # 
              #first we see if image exists,if it does, we need to remove it before we replace it.  We will destroy each even dups
              #
          
              image_exists = product.pictures.where(:image=>entry.tr(" ","_"))
              puts("image_exists? :#{entry.tr(" ","_")} -->#{image_exists.inspect}")
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
                
                max_image_size = Settings.max_image_size.to_i.to_s == "0" ?  "1000x" :Settings.max_image_size.to_i.to_s + "x" 
                
                temp_image.change_geometry!(max_image_size)  { |cols, rows, img|
                  img.resize!(cols, rows)
                }
                sleep(1)
                
                temp_image.resample()
                sleep(1)
                
                temp_image.write(Rails.root.join("tmp",entry)) { self.quality = 50 }
                sleep(1)
                
                temp_image.destroy!
                sleep(1)

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
                puts("Message for the log file #{exc.message}")
              end

            end
          end
          File.delete(Rails.root.join(image_import_directory,entry))

        end
      
        status_percent=Float(Float(index)/Float(file_count)*100)
      
        sleep 1
     
        importer.reload
      
        if (importer.status=="Cancel") then
          importer.status="Canceling" 
          importer.status_percent=100
          importer.status_message="Process Complete"
          importer.end_time = DateTime.now

          importer.save
          return(false)
        end
      
        importer.status="Processing" 
        importer.status_percent=status_percent.to_i
        importer.status_message="Processing Image "+ image_name + "(" + index.to_s + " of " + file_count.to_s + ")"
        importer.save
      
      end 
      #rescue importer_failed = true
    rescue Exception => import_exec
      puts("Message for the log file #{import_exec.message}")
      importer_failed = true
    end
    
    
    importer.status="Complete"
    importer.status_percent=100
    importer.status_message= (importer_failed ? "Importer Failed" : "Process Complete")
    importer.end_time = DateTime.now
    importer.save
    
  
  end
  
  
end