# desc "Explaining what the task does"
# task :silverweb_importer do
#   # Task goes here
# end
require "roo"
require "roo-xls"

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
    
  
  end
end