$(document).ready(function(){

	$.ajaxSetup ({
		cache: false
	});

	var ajax_load = "<img src='img/load.gif' alt='loading...' />";

//	$.getJSON()
	var jsonUrl = "/node.json";
	$("#getnode").submit(function(){
		var id = $("#id").val();
		if (id.length == 0) {
			$("#id").focus();
		} else {
			$("aside").html(ajax_load);
			$.getJSON(
				jsonUrl,
				{id: id},
				function(json) {
					var result = "Language code is \"<strong>" + json.responseData.language + "\"";
					$("aside").html(result);
				}
			);
		}
		return false;
	});


	
	// Caching the neo-suggest textbox:
	var neo_suggest = $('#neo-suggest');
	
	// Defining a placeholder text:
	neo_suggest.defaultText('Type a node id');
		

	// Using jQuery UI's catcomplete widget:
       $.widget( "custom.catcomplete", $.ui.autocomplete, {
		_renderMenu: function( ul, items ) {
			var self = this,
				currentCategory = "";
			$.each( items, function( index, item ) {
				if ( item.category != currentCategory ) {
					ul.append( "<li class='ui-autocomplete-category'>" + item.category + "</li>" );
					currentCategory = item.category;
				}
				self._renderItem( ul, item );

			});
		}
	});
	

	neo_suggest.catcomplete({
		minLength	: 3,
		source		: '/autocomplete.json'
	});

});

// A custom jQuery method for placeholder text:

$.fn.defaultText = function(value){
	
	var element = this.eq(0);
	element.data('defaultText',value);
	
	element.focus(function(){
		if(element.val() == value){
			element.val('').removeClass('defaultText');
		}
	}).blur(function(){
		if(element.val() == '' || element.val() == value){
			element.addClass('defaultText').val(value);
		}
	});
	
	return element.blur();
}