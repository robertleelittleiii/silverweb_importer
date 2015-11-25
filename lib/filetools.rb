module FileTools
  
  # require 'carrierwave'
  # include CarrierWave::RMagick
  require 'RMagick'
  include Magick
  
  IMAGE_TYPES = ["jpg", "gif", "png","jpeg"].freeze
  
  
  def process_zip(path, file_name)
    
    image_import_directory = Rails.root.join("tmp", "image_import")

    #
    # make temp dirctory to store file while processing if it doesn't exist
    #
    
    Dir.mkdir(image_import_directory) rescue 0
    
    image_file = Zip::ZipFile.open(Rails.root.join(path,file_name))
      
    image_file.entries.each do |each_item|
      if each_item.file? then
        entry= each_item.name.split("/").last
        file_codes = entry.split(".")
        entry_codes = file_codes[0].split("-")
        
        style_code = entry_codes[0]
        color_code = entry_codes[1]
        
        #
        # Extract the file to a temp file for processing
        #
        each_item.extract(Rails.root.join(image_import_directory,entry))
        
        puts("style_code: #{style_code} color_code: #{color_code}")
        if not IMAGE_TYPES.index(file_codes[1]).nil? then
          @product = Product.where(supplier_product_id: style_code).first
          if @product.blank? then
            puts("product not found") 
          else
            puts(@product.inspect)
          
            #
            #first we see if image exists,if it does, we need to remove it before we replace it.  We will destroy each even dups
            #
          
            image_exists = @product.pictures.where(image: entry)
            if not image_exists.nil? then
              image_exists.each do |each_item| 
                each_item.destroy 
              end
            end
          
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
            @picture=Picture.create
            @picture.image.store!(File.open(Rails.root.join("tmp",entry)))
            File.delete(Rails.root.join("tmp",entry))
          
            @picture.save
            @picture.title = color_code
            @picture.save

            @product.pictures << @picture
            @product.save
      

          end
        end
        File.delete(Rails.root.join(image_import_directory,entry))

      end
      
    end
    
  end
  
  def directory_hash(path, name=nil)
    data = {data: (name || path)}
    data[:children] = children = []
    Dir.foreach(path) do |entry|
      next if (entry == '..' || entry == '.')
      full_path = File.join(path, entry)
      puts("full path: #{full_path}  entry: #{entry}")
      file_codes = entry.split(".")
      entry_codes = file_codes[0].split("-")
    
      style_code = entry_codes[0]
      color_code = entry_codes[1]
    
      
      puts("style_code: #{style_code} color_code: #{color_code}")
      if not IMAGE_TYPES.index(file_codes[1]).nil? then
        @product = Product.where(supplier_product_id: style_code).first
        if @product.blank? then
          puts("product not found") 
        else
          puts(@product.inspect)
          
          #
          #first we see if image exists,if it does, we need to remove it before we replace it.  We will destroy each even dups
          #
          
          image_exists = @product.pictures.where(image: entry)
          if not image_exists.nil? then
            image_exists.each do |each_item| 
              each_item.destroy 
            end
          end
          
          #
          # process the image to 1000 px wide with 72 dpi and 50% compression as a jpg.
          #
          temp_image = ImageList.new(Rails.root.join(path, entry))
          temp_image.change_geometry!('1000x')  { |cols, rows, img|
            img.resize!(cols, rows)
          }
          temp_image.resample()
          temp_image.write(Rails.root.join("tmp",entry)) { self.quality = 50 }
          temp_image.destroy!

          
          @picture=Picture.create
          @picture.image.store!(File.open(Rails.root.join("tmp",entry)))
          File.delete(Rails.root.join("tmp",entry))
          
          @picture.save
          @picture.title = color_code
          @picture.save

          @product.pictures << @picture
          @product.save
      

        end
      end
    
      if File.directory?(full_path)
        children << directory_hash(full_path, entry)
      else
        children << entry
      end
    end
    return data
  end

end