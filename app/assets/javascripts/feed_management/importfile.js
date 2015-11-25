/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
var $FilesToShow = 1;

var toggleLoading = function () {
    $("#loader_progress").toggle()
};
var toggleAddButton = function () {
    $("#upload-form").toggle()
};

function pausecomp(millis)
{
    var date = new Date();
    var curDate = null;

    do {
        curDate = new Date();
    }
    while (curDate - date < millis);
}



function blockWithMessage(item_to_block, the_message) {
    $(item_to_block).block({
        message: '<h2><img src="/assets/interface/busy.gif" /> ' + the_message + '</h2>',
        css: {
            border: '3px solid #a00',
            width: '300px'
        }
    });

}


$(document).ready(function () {
    var toggleLoading = function () {
        $("#loader_progress").toggle()
    };
    var toggleAddButton = function () {
        $("#upload-form").toggle()
    };
    // load any specific libraries

    require("jquery.timers.js");
    require("jquery.blockUI.js");
    requireCss("feed_management.css");

    bind_file_upload_to_upload_form();

    //
    //
    // image class bindings
    // 
    setupNewImporter();

    // setupFileButtonAction();

    setupDelete();

    updateSheetColumns();

    setupModelName();

    setupDeleteImportItem();

    setupMenuChange();

    setupNameChange();

    setUpRunImporterButton();

    $("#new-importer").bind('ajax:before', function () {
        //         window.alert("before");
        // toggleLoading();
    })
            .bind('ajax:complete', function () {
                //          window.alert("after");

                //      toggleLoading();
            })
            .bind('ajax:success', function (event, data, status, xhr) {
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

    bindDeleteImporter();
    bindDuplicateImporter();
    uploaderSetupTimer(".filesection");
    setupTimer('#run-importer');
    ui_ajax_select();

});

function setupTimer(item_to_link) {

    item_linked = item_to_link
    //  console.log(item_linked)
    $("#import-progress-block").hide();

    if ((($("#importer-status-msg").text().trim() != "Importer Failed") & ($("#importer-status-msg").text().trim() != "Process Complete") & ($("#importer-status-msg").text().trim() != "")))
    {
        // alert("OK");
        $(item_linked).everyTime(5000, 'importer', function () {

            //if ($("#importer-status-msg").text().trim() != "Opening File...") {
            $("#import-progress-block").show();
            loadImportProgress();

            //}


            if (($("#importer-status-msg").text().trim() == "Importer Failed") | ($("#importer-status-msg").text().trim() == "Process Complete") | ($("#importer-status-msg").text().trim() == ""))
            {
                //    console.log(item_linked)

                //    console.log("setupTimer" + item_linked)
                $(item_linked).stopTime('importer');
                loadImportStatus();
                $("#import-progress-block").hide();
                // import_action_update();

                //   alert("DONE!!!");

            }
        });
    }
    ;
}

function uploaderSetupTimer(item_to_link) {
    loadImportProgress();

    $(item_to_link).everyTime(5000, 'uploader', function () {
        item_linked = item_to_link

        //if ($("#importer-status-msg").text().trim() != "Opening File...") {

        loadImportProgress();
        $("#import-progress-block").show();
        //}


        if (($("#importer-status-msg").text().trim() == "Importer Failed") | ($("#importer-status-msg").text().trim() == "Process Complete") | ($("#importer-status-msg").text().trim() == ""))
        {
            //  console.log("uploaderSetupTimer" + item_linked)
            $(item_linked).stopTime('uploader');

            $("#import-progress-block").hide();

            import_action_update();

            // import_action_update();

            //   alert("DONE!!!");

        }
    });

}




function setUpRunImporterButton() {

    $('#run-importer').bind("click", function () {
        $("#importer-status-msg").html("Starting...");
        setupTimer(this);
        $("#import-progress-block").show();
        //  alert("clicked");
    });
}

function BestInPlaceCallBackInit(input) {
    // alert("this is a test");
    // console.log("log:" + input.attributeName);
    switch (input.attributeName) {
        case 'name':
        {
            break;
        }
        case 'columns':
        {
            break;
        }
        case 'full_uri_path':
        {
            blockWithMessage(".filesection", "Downloading data...");
            //          uploaderSetupTimer(".filesection");
            break;
        }
        default:
            {

            }
            ;
    }
    ;

}

function BestInPlaceCallBack(input) {
    //   console.log(input);

    switch (input.attributeName) {
        case 'name':
        {
            importer_id = $("#importer-id").text().trim();

            $.ajax({
                url: "/feed_management/set_up_importer_partial",
                dataType: "html",
                type: "POST",
                data: "id=" + importer_id + "&importer_type=file",
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

            break;
        }
        case 'columns':
        {

            updateSheetColumns();
            break;
        }
        case 'full_uri_path':
            {
                //alert("edit complete");
                //         blockWithMessage(".filesection", "Downloading data...");
                //         uploaderSetupTimer(".filesection");
                import_action_update();
                //updateSheetColumns();
                break;

            }
            ;
        default:
            {

            }
            ;
    }
    ;





//    if (input.data.indexOf("importer[name]") != -1)
//    {  
//        importer_id=$("#importer-id").text().trim();
//
//        $.ajax({
//            url: "/feed_management/set_up_importer_partial",
//            dataType: "html",
//            type: "POST",
//            data: "id="+importer_id+ "&importer_type=file" ,
//            success: function (data)
//            {
//                //alert(data);
//                if (data === undefined || data === null || data === "")
//                {
//                //display warning
//                }
//                else
//                {
//                    $("#set-up-importer").html(data);
//                    setupMenuChange(); 
//
//                }
//            }
//        });
//    
//    
//    };
//    
//    if (input.data.indexOf("importer[columns]") != -1)
//    {  
//        // alert("edit complete");
//        updateSheetColumns();
//
//    
//    };
//    if (input.data.indexOf("importer[full_uri_path]") != -1)
//    {  
//        alert("edit complete");
//        blockWithMessage(".filesection", "Downloading data...");
//        uploaderSetupTimer(".filesection");
//        updateSheetColumns();
//
//    };


}
;


function setupNameChange() {


    $("div#best_in_place_importer_name").bind('ajax:before', function () {
        window.alert("before");
        // toggleLoading();
    })
            .bind('ajax:complete', function () {
                window.alert("after");

                //      toggleLoading();
            })
            .bind('ajax:success', function (event, data, status, xhr) {
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

function import_action_update() {

    selected_item = $("#importer-name option:selected");

    $.ajax({
        url: "/feed_management/import_action_partial",
        dataType: "html",
        type: "POST",
        data: "id=" + selected_item.val() + "&importer_name=" + selected_item.text(),
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
                    message: '<h2><img src="/assets/interface/busy.gif" /> Just a moment...</h2>',
                    css: {
                        border: '3px solid #a00',
                        width: '300px'
                    }
                });

                $("#import-action").html(data);
                // styleizefilebutton(); 
                //   initStylizeInput();
                // setupFileButtonAction();
                setupModelName();
                ui_ajax_select();

                setupMapToButton();
                setupNameChange();
                updateModelName();
                updateSheetColumns();
                setupDelete();

                $("#importer-item-list").find(".best_in_place").best_in_place();
                $("#table-section").find(".best_in_place").best_in_place();
                $(".filesection").find(".best_in_place").best_in_place();
                setupDeleteImportItem();
                $("#importer-status-msg").html("");
                setUpRunImporterButton();
                // 
                // setupTimer(this);
                // $('div#import-action-div').unblock(); 

                // $(".best_in_place").best_in_place();

            }
        }
    });

}

function update_import_actions(selected_item_val, selected_item_text) {
    $.ajax({
        url: "/feed_management/import_action_partial",
        dataType: "html",
        type: "POST",
        data: "id=" + selected_item_val + "&importer_name=" + selected_item_text,
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
                    message: '<h2><img src="/assets/interface/busy.gif" /> Just a moment...</h2>',
                    css: {
                        border: '3px solid #a00',
                        width: '300px'
                    }
                });

                $("#import-action").html(data);
                // styleizefilebutton(); 
                //   initStylizeInput();
                // setupFileButtonAction();
                setupModelName();
                ui_ajax_select();

                setupMapToButton();
                setupNameChange();
                updateModelName();
                updateSheetColumns();
                setupDelete();

                $("#importer-item-list").find(".best_in_place").best_in_place();
                $("#table-section").find(".best_in_place").best_in_place();
                $(".filesection").find(".best_in_place").best_in_place();

                setupDeleteImportItem();
                $("#importer-status-msg").html("");
                setUpRunImporterButton();
                setupTimer(this);
                bind_file_upload_to_upload_form();
                $('div#import-action-div').unblock();

                // $(".best_in_place").best_in_place();

            }
        }
    })
}


function setupMenuChange() {

    $('#importer-name').bind("change", function () {
        selected_item = $("#importer-name option:selected");
        $.ajax({
            url: "/feed_management/importer_name_partial",
            dataType: "html",
            type: "POST",
            data: "id=" + selected_item.val() + "&importer_name=" + selected_item.text(),
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

        update_import_actions(selected_item.val(), selected_item.text());

    });


}

function setupProgressBar(percent_complete) {
    $("#importer-status-img").progressbar({
        value: Number(percent_complete)
    });
}


function loadImportStatus() {
    importer_id = $("#importer-id").text().trim();

    $.ajax({
        url: "/feed_management/load_importer_status",
        dataType: "html",
        type: "POST",
        data: "id=" + importer_id,
        success: function (data)
        {
            //alert(data);
            if (data === undefined || data === null || data === "")
            {
                //display warning
            }
            else
            {
                $("#importer-status").html(data);
            }
        }
    });
}

function loadImportProgress() {
    importer_id = $("#importer-id").text().trim();

    $.ajax({
        url: "/feed_management/load_importer_progress",
        dataType: "html",
        type: "POST",
        data: "id=" + importer_id,
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
                progress_done = $("#progress-done").text().trim();

                setupProgressBar(progress_done);

            }
        }
    });
}

function setupNewImporter() {

    $('#new-importer').bind("click", function () {
        //    $("#importer-name").trigger("change");
        //    alert("clicked");
    });

}

function duplicateCurrentImporter() {
    if (!$("#importer-name").val() == "")
    {
        importer_id = $("#importer-id").text().trim();

        $.ajax({
            url: "/feed_management/duplicate_importer",
            dataType: "html",
            type: "POST",
            data: "id=" + importer_id + "&importer_type=file",
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
                    importer_id = $("#importer-id").text().trim();
                    $('#importer-name option').val(importer_id);
                    //$('#importer-name').prop('selectedIndex', $('#importer-name option').size()-1);
                    setupMenuChange();
                    $('#importer-name').change();


                }
            }
        });


    }
    ;
}
function deleteCurrentImporter() {
    if (!$("#importer-name").val() == "")
    {
        var importer_id = $("#importer-id").text().trim();
        var importer_current_index = $('#importer-name').prop('selectedIndex')

        if (confirm("Delete this importer?")) {
            $.ajax({
                url: "/feed_management/delete_importer",
                dataType: "html",
                type: "POST",
                data: "id=" + importer_id + "&importer_type=file",
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
                        $('#importer-name').prop('selectedIndex', importer_current_index);

                        setupMenuChange();
                        $('#importer-name').change();
                    }
                }
            });
        }

    }
    ;
}

function bindDeleteImporter() {

    $('#delete-importer').bind("click", function () {
        //    $("#importer-name").trigger("change");
        // alert("delete this");
        deleteCurrentImporter();
        return(false);
    });

}

function bindDuplicateImporter() {

    $('#duplicate-importer').bind("click", function () {
        //    $("#importer-name").trigger("change");
        duplicateCurrentImporter();
        // alert("duplicate clicked");
        return(false);
    });

}
function setupMapToButton() {

    $('#map-to-button').bind("click", function () {
        importer_id = $("#importer-id").text().trim();
        from_selected_item = $("#from-select option:selected");
        to_selected_item = $("#to-select option:selected");
        to_table_name = $("#importer_table_name option:selected")

        $.ajax({
            url: "/feed_management/add_importer_item",
            dataType: "html",
            type: "POST",
            data: "id=" + importer_id + "&from_column=" + from_selected_item.val() + "&to_column=" + to_selected_item.val() + "&from_column_name=" + encodeURIComponent(from_selected_item.text()) + "&to_column_name=" + encodeURIComponent(to_selected_item.text()) + "&to_table_name=" + encodeURIComponent(to_table_name.text()),
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
    $('#importer_table_name').bind("change", function () {
        updateModelName();
    });

}

function updateModelName() {
    var item_id = ""
    var model_name = ""

    var importer_id = $("#importer-id").text().trim();
    var selected_item = $("#importer_table_name option:selected");

    if (selected_item.length == 0)
    {
        item_id = $("#importer-id").text();
        model_name = ""
    }
    else
    {
        item_id = importer_id;
        model_name = selected_item.text();
    }
    $.ajax({
        url: "/feed_management/columns_render_partial",
        dataType: "html",
        type: "POST",
        data: "id=" + item_id + "&model_name=" + model_name,
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

    $('input#file').bind("change", function () {
        toggleLoading();
        toggleAddButton();
        $(this).closest("form").trigger("submit");
    });
}


function setupDelete()
{
    $('.delete_file').bind('ajax:success', function (event, data, status, xhr) {
        //$("#response").html(data);
        $(this).closest(".fileSingle").fadeOut();
        $(this).closest(".fileSingle").remove();

        $fileCount = $('.fileSingle').length
        if ($fileCount < $FilesToShow)
        {
            $('#filebutton').show();
            $('#remote-url').show();
            updateSheetColumns();
        }

    });
}

function setupDeleteImportItem()
{
    $('.delete_import_item').bind('ajax:success', function (event, data, status, xhr) {
        //$("#response").html(data);
        $(this).closest(".importer-item").fadeOut();
        $(this).closest(".importer-item").remove();
    });
}


function render_files()
{
        importer_id = $("#importer-id").text();

 $.ajax({
        url: "/feed_management/render_files",
        dataType: "html",
        type: "GET",
        data: {importer_id: importer_id},
        success: function (data)
        {
            //alert(data);
            if (data === undefined || data === null || data === "")
            {
                //display warning
            }
            else
            {
                $("div#files").html(data);
                $("div#files").fadeIn();
                update_import_actions(importer_id, "");
            }
        }
    });
}

function updateSheetColumns()
{
    fullfilepath = $("#full-file-path");
    selected_item = $("#importer-id").text();

    $.ajax({
        url: "/feed_management/sheet_columns_render_partial",
        dataType: "html",
        type: "POST",
        data: "file_path=" + fullfilepath.text().trim() + "&id=" + selected_item,
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


function bind_file_upload_to_upload_form()
{
    bind_download_to_files();
    $("form.upload-form").fileupload({
        dataType: "json",
        add: function (e, data) {
            file = data.files[0];
            data.context = $(tmpl("template-upload", file));
            // $("div.progress").progressbar();
            $("div#filebutton").hide();
            $("div#remote-url").hide();
            $('.filesection').append(data.context);
            var jqXHR = data.submit()
                    .success(function (result, statusText, jqXHR) {

                        console.log("------ - fileupload: Success - -------");
                        console.log(result);
                        console.log(result.id);
                        console.log(statusText);
                        console.log(jqXHR);

                        console.log(JSON.stringify(jqXHR.responseJSON["name"]));

                        console.log(typeof (jqXHR.responseText));
// specifically for IE8. 
                        // if (typeof (jqXHR.responseText) == "undefined") {
                        setUpPurrNotifier("Notice", jqXHR.responseJSON["name"]);
                        data.context.remove();
                        render_files();
                        //}
                        // else
                        // {
                        //  render_pictures(result.id);
                        // }

                    })
                    .error(function (jqXHR, statusText, errorThrown) {
                        // console.log("------ - fileupload: Error - -------");
                        // console.log(jqXHR.status);
                        // console.log(statusText);
                        // console.log(errorThrown);
                        // console.log(jqXHR.responseText);
                        $("div#filebutton").show();
                        $("div#remote-url").show();
                        if (jqXHR.status == "200")
                        {
                            //   render_pictures();
                        }
                        else
                        {
                            var obj = jQuery.parseJSON(jqXHR.responseText);
                            // console.log(typeof obj["attachment"][0])
                            setUpPurrNotifier("Notice", obj["name"]);
                            data.context.remove();
                        }
//                        if (jqXHR.statusText == "success") {
//                            render_pictures();
//                            // It succeeded and we need to update the file list.
//                        }
//                        else {
//                            var obj = jQuery.parseJSON(jqXHR.responseText);
//                            setUpPurrNotifier("info.png", "Notice", obj["attachment"][0]);
//                            data.context.remove();
//                        }

                    })
                    .complete(function (result, textStatus, jqXHR) {
                        // console.log("------ - fileupload: Complete - -------");
                        // console.log(result);
                        // console.log(textStatus);
                        // console.log(jqXHR);
                    });
        },
        progress: function (e, data) {
            if (data.context)
            {
                progress = parseInt(data.loaded / data.total * 100, 10);
                data.context.find('.bar').css('width', progress + '%');
            }
        },
        done: function (e, data) {
            // console.log(e);
            // console.log(data);
            data.context.text('');
        }
    }).bind('fileuploaddone', function (e, data) {
        // console.log(e);
        // console.log(data);
        data.context.remove();
        //data.context.text('');
    });
}

function bind_download_to_files()
{
    $("div.file-item div#logo-links").unbind("click");
    $("div.file-item div#logo-links").bind("click",
            function () {
                var href = $($(this)[0]).find('a').attr('href');
                window.location.href = href
            });
}