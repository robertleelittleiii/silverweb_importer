class ImportersController < ApplicationController
  # GET /importers
  # GET /importers.json
  def index
    @importers = Importer.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @importers} 
    end
  end

  # GET /importers/1
  # GET /importers/1.json
  def show
    @importer = Importer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @importer }
    end
  end

  # GET /importers/new
  # GET /importers/new.json
  def new
    @importer = Importer.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @importer}
    end
  end

  # GET /importers/1/edit
  def edit
    @importer = Importer.find(params[:id])
  end

  # POST /importers
  # POST /importers.json
  def create
    @importer = Importer.new(importer_params)

    respond_to do |format|
      if @importer.save
        format.html { redirect_to @importer, notice: "Importer was successfully created." }
        format.json { render json: @importer, status: :created, location: @importer }
      else
        format.html { render action: "new" }
        format.json { render json: @importer.errors, status: :unprocessable_entry }
      end
    end
  end

  # PUT /importers/1
  # PUT /importers/1.json
  def update
    @importer = Importer.find(params[:id])

    if (not params[:importer][:full_uri_path].blank?) and ( not @importer.full_uri_path == params[:importer][:full_uri_path]) then
      @importer.files.first.destroy rescue ""
      @importer.status_message = "Remote Load..."
      @importer.save
      begin
        temp_file = FileAtt.new(remote_file_info_url: params[:importer][:full_uri_path])
        temp_file.save
        @importer.files << temp_file
      rescue Exception => import_exec
        Rails.logger.error("Error occured when trying to access url: #{import_exec.message}")
      end        
      @importer.status_message = "Process Complete"
      @importer.save
      puts("is remote update")
    end
    
    respond_to do |format|
      if @importer.update_attributes(importer_params)
        format.html { redirect_to @importer, notice: "Importer was successfully updated."}
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @importer.errors, status: "unprocessable_entry" }
      end
    end
  end

  # DELETE /importers/1
  # DELETE /importers/1.json
  def destroy
    @importer = Importer.find(params[:id])
    @importer.destroy

    respond_to do |format|
      format.html { redirect_to importers_url }
      format.json { head :ok }
    end
  end
  
   # CREATE_EMPTY_RECORD /importers/1
   # CREATE_EMPTY_RECORD /importers/1.json

  def create_empty_record
    @importer = Importer.new
    @importer.save
    
    redirect_to(controller: :importers, action: :edit, id: @importer)
  end

   def importer_params
  params[:importer].permit( "name", "full_uri_path", "columns", "table_name", "created_at", "updated_at", "importer_type", "login_id", "password", "status", "status_percent", "status_message", "start_time", "end_time", "run_count")
end

end
