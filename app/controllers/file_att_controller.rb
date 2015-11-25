class FileAttController < ApplicationController
  # GET /files
  # GET /files.json
  def index
    @files = FileAtt.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json=>@files} 
    end
  end

  # GET /files/1
  # GET /files/1.json
  def show
    @file = FileAtt.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json=>@file }
    end
  end

  # GET /files/new
  # GET /files/new.json
  def new
    @file = FileAtt.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json=>@file}
    end
  end

  # GET /files/1/edit
  def edit
    @file = FileAtt.find(params[:id])
  end

  def insert
    @file = FileAtt.find(params[:id])
  end
  
  # POST /files
  # POST /files.json
  def create
    @file = FileAtt.new(file_params)

    respond_to do |format|
      if @file.save
        format.js   { render :action=>"create" }
        format.html { redirect_to @file, :notice=>"FileAtt was successfully created." }
        format.json { render :json=>@file, :status=>:created, :location=>@file }
      else
        format.html { render :action=>"new" }
        format.json { render :json=>@file.errors, :status=>:unprocessable_entry }
      end
    end
  end

  # PUT /files/1
  # PUT /files/1.json
  def update
    @file = FileAtt.find(params[:id])

    respond_to do |format|
      if @file.update_attributes(file_params)
        format.html { redirect_to @file, :notice=>"FileAtt was successfully updated."}
        format.json { head :ok }
      else
        format.html { render :action=>"edit" }
        format.json { render :json=>@file.errors, :status=>"unprocessable_entry" }
      end
    end
  end

  # DELETE /files/1
  # DELETE /files/1.json
  def destroy
    @file = FileAtt.find(params[:id])
    @file.destroy

    respond_to do |format|
      format.js
      format.html { redirect_to files_url }
      format.json { head :ok }
    end
   
  end
  
  # CREATE_EMPTY_RECORD /files/1
  # CREATE_EMPTY_RECORD /files/1.json

  def create_empty_record
    @file = FileAtt.new
    @file.save
    
    redirect_to(:controller=>:files, :action=>:edit, :id=>@file)
  end
  
  
  def render_file
    class_name =  params[:class_name]

    @file = FileAtt.where(id: params[:id]).first
    if class_name.blank? then
      render :partial=>"/files/file_view.html" 
    else
      render :partial=> class_name.downcase + "s" + "/file_view.html" 
    end
  end
  
  def render_files
    class_name =  params[:class_name]
  
    @files = class_name.classify.constantize.where(id: params[:id]).first.files.order(created_at: :desc)

    if class_name.blank? then
      render(:partial=>"/files/file_list.html", locals: {file_list: @files} )
    else
      render(:partial=> class_name.downcase + "s" + "/file_list.html", locals: {file_list: @files} )
    end
    
  end
  
  def download_file
    @file = FileAtt.find(params[:id])
    send_file(@file.image.path,
      :disposition => 'image',
      :url_based_filename => false)
  end
  
  def insert_image
    @file = FileAtt.find(params[:id])
    @image_class_list =  [["Original Size",nil]] + ImageUploader.versions.keys.map{|item| [(item.to_s.humanize), item] } 

    
  end
  
  
  private

  def file_params
    params[:file].permit( "name", "description", "position", "file_info", "resource_id", "resource_type", "created_at", "updated_at")
  end
  
end
