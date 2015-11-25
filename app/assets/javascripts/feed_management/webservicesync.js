/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
var $FilesToShow=1;

var toggleLoading = function() {
    $("#loader_progress").toggle()
};
var toggleAddButton= function() {
    $("#upload-form").toggle()
};

$(document).ready(function(){
    var toggleLoading = function() {
        $("#loader_progress").toggle()
    };
    var toggleAddButton= function() {
        $("#upload-form").toggle()
    };

    //
    //
    // image class bindings
    // 
    setupNewImporter();

    setupFileButtonAction();
    
    setupDelete();
    
    updateSheetColumns();
    
    setupModelName();
    
    setupDeleteImportItem();
  
    setupMenuChange();
   
    setupNameChange();
   
    setUpRunImporterButton();
   
    $("#set-up-importer-button").find("form").bind('ajax:before', function(){
        //         window.alert("before");
        // toggleLoading();
        }) 
    .bind('ajax:complete', function(){
        //          window.alert("after");

        //      toggleLoading();
        })
    .bind('ajax:success', function(event, data, status, xhr) {
        //$("#response").html(data);
        console.log(event);
        console.log(data);
        console.log(status);
        console.log(xhr);
        $("#set-up-importer").html(data);
        setupMenuChange();

        $("#importer-name").trigger("change");
    //  window.alert("success");
    });
    
    
    
    
});

function setUpRunImporterButton() {
    
    $('#run-importer').bind("click", function() {
        $("#importer-status-msg").html("Starting...");
        $(this).everyTime(1000, 'importer', function() {
          
            loadImportProgress();
            if ($("#importer-status-msg").text().strip() == "Process Complete")
            {
                $(this).stopTime('importer');
                
            //$("#import-progress-block").html("");

            //   alert("DONE!!!");

            }
        });
    //  alert("clicked");
    });  
}

function BestInPlaceCallBack(input) {

    if (input.data.indexOf("importer[name]") != -1)
    {  
        importer_id=$("#importer-id").text().strip();

        $.ajax({
            url: "/feed_management/set_up_importer_partial",
            dataType: "html",
            type: "POST",
            data: "id="+importer_id+ "&importer_type=web-service" ,
            success: function (data)
            {
                //alert(data);
                if (data === undefined || data === null || data === "")
                {
                //display warning
                }
                else
                {
                    $("#set-up-importer").html(data);
                    setupMenuChange(); 

                }
            }
        });
    
    
    };
    

    
    
} ;
 

function setupNameChange() {
    
     
    $("div#best_in_place_importer_name").bind('ajax:before', function(){
        window.alert("before");
    // toggleLoading();
    }) 
    .bind('ajax:complete', function(){
        window.alert("after");

    //      toggleLoading();
    })
    .bind('ajax:success', function(event, data, status, xhr) {
        //$("#response").html(data);
        console.log(event);
        console.log(data);
        console.log(status);
        console.log(xhr);
        // $("#set-up-importer").html(data);
        // setupMenuChange();

        //// $("#importer-name").trigger("change");
        window.alert("success");
    });
     
    
    
}



function setupMenuChange() {
    
    $('#importer-name').bind("change", function() {
        selected_item= $("#importer-name option:selected");
        $.ajax({
            url: "/feed_management/importer_name_partial",
            dataType: "html",
            type: "POST",
            data: "id="+selected_item.val()+ "&importer_name="+selected_item.text() ,
            success: function (data)
            {
                //alert(data);
                if (data === undefined || data === null || data === "")
                {
                //display warning
                }
                else
                {
                    $("#importer-id").html(selected_item.val());
                    $("#importer-name-div").html(data);
                    $("#best_in_place_importer_name.best_in_place").best_in_place();
                }
            }
        });
        
        updateWebServiceInfo();

        $.ajax({
            url: "/feed_management/import_action_partial",
            dataType: "html",
            type: "POST",
            data: "id="+selected_item.val()+ "&importer_name="+selected_item.text() ,
            success: function (data)
            {
                //alert(data);
                if (data === undefined || data === null || data === "")
                {
                //display warning
                }
                else
                {
                    $('div#import-action-div').block({ 
                        message: '<h2><img src="/images/busy.gif" /> Just a moment...</h2>', 
                        css: {
                            border: '3px solid #a00',
                            width: '300px'
                        } 
                    }); 
                    
                    $("#import-action").html(data);
                    initStylizeInput();
                    setupFileButtonAction();
                    setupModelName();
                    setupMapToButton();
                    setupNameChange();
                    updateModelName();
                    updateSheetColumns();
                    $("#importer-item-list").find(".best_in_place").best_in_place();
                    setupDeleteImportItem();
                    $("#importer-status-msg").html("");
                    setUpRunImporterButton();
                   // $('div#import-action-div').unblock(); 

                // $(".best_in_place").best_in_place();

                }
            }
        });
        
    });
    
    
}

function setupProgressBar(percent_complete) {
    $("#importer-status-img").progressbar({
        value: Number(percent_complete)
    });
}

function loadImportProgress() {
    importer_id=$("#importer-id").text().strip();

    $.ajax({
        url: "/feed_management/load_importer_progress",
        dataType: "html",
        type: "POST",
        data: "id="+importer_id,
        success: function (data)
        {
            //alert(data);
            if (data === undefined || data === null || data === "")
            {
            //display warning
            }
            else
            {
                $("#import-progress-block").html(data);
                progress_done=$("#progress-done").text().strip();

                setupProgressBar(progress_done);

            }
        }
    });
}

function setupNewImporter() {
    
    $('#new-importer').bind("click", function() {
        //    $("#importer-name").trigger("change");
        //    alert("clicked");
        });
    
}

function setupMapToButton() {
    
    $('#map-to-button').bind("click", function() {
        importer_id=$("#importer-id").text().strip();
        from_selected_item= $("#from-select option:selected");
        to_selected_item= $("#to-select option:selected");
        to_table_name= $("#importer_table_name option:selected")
        from_table_name= $("#table-name").text().strip();

        $.ajax({
            url: "/feed_management/add_importer_item",
            dataType: "html",
            type: "POST",
            data: "id="+importer_id + "&from_table_name=" + from_table_name + "&from_column="+from_selected_item.val()+ "&to_column="+to_selected_item.val()+"&from_column_name="+encodeURIComponent(from_selected_item.text())+"&to_column_name="+encodeURIComponent(to_selected_item.text())+"&to_table_name="+encodeURIComponent(to_table_name.text()),
            success: function (data)
            {
                //alert(data);
                if (data === undefined || data === null || data === "")
                {
                //display warning
                }
                else
                {
                    $("#importer-item-list").html(data);

                    setupDeleteImportItem();

                }
            }
        });
    //      alert("clicked");
    });
    
}

function setupModelName() {
    
    $('#importer_table_name').bind("change", function() {
        updateModelName();
    });
    
}

function updateWebServiceInfo() {
        selected_item= $("#importer-name option:selected");

        $.ajax({
            url: "/feed_management/web_service_info_partial",
            dataType: "html",
            type: "POST",
            data: "id="+selected_item.val()+ "&importer_name="+selected_item.text() ,
            success: function (data)
            {
                //alert(data);
                if (data === undefined || data === null || data === "")
                {
                //display warning
                }
                else
                {
                    $("#web-service-info-div").html(data);
                    $("#best_in_place_importer_login_id.best_in_place").best_in_place();
                    $("#best_in_place_importer_password.best_in_place").best_in_place();
                    $("#best_in_place_importer_full_uri_path.best_in_place").best_in_place();

                }
            }
        });
        
}

function updateModelName(){
    selected_item= $("#importer_table_name option:selected");
    $.ajax({
        url: "/feed_management/columns_render_partial",
        dataType: "html",
        type: "POST",
        data: "id="+selected_item.val()+ "&model_name="+selected_item.text() ,
        success: function (data)
        {
            //alert(data);
            if (data === undefined || data === null || data === "")
            {
            //display warning
            }
            else
            {
                $("#table-columns").html(data);

            }
        }
    });
}

function setupFileButtonAction()
{
    
    $('input#file').bind("change", function() {
        toggleLoading();
        toggleAddButton();
        $(this).closest("form").trigger("submit");
    });
}
function setupDelete() 
{
    $('.delete_file').bind('ajax:success', function(event, data, status, xhr) {
        //$("#response").html(data);
        $(this).closest(".fileSingle").fadeOut();
        $(this).closest(".fileSingle").remove();

        $fileCount = $('.fileSingle').length
        if ($fileCount < $FilesToShow)
        {
            $('#filebutton').show();
            updateSheetColumns();
        }
      
    });
}
 
function setupDeleteImportItem() 
{
    $('.delete_import_item').bind('ajax:success', function(event, data, status, xhr) {
        //$("#response").html(data);
        $(this).closest(".importer-item").fadeOut();
        $(this).closest(".importer-item").remove();
    });
}

 
 
function updateSheetColumns()
{
    fullfilepath=$("#full-file-path");

    $.ajax({
        url: "/feed_management/xsd_columns_render_partial",
        dataType: "html",
        type: "POST",
        data: "file_path="+fullfilepath.text().strip() ,
        success: function (data)
        {
            //alert(data);
            if (data === undefined || data === null || data === "")
            {
            //display warning
            }
            else
            {
                $("#sheet-columns").html(data);
                $('div#import-action-div').unblock(); 


            }
        }
    });
     
}