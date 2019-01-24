$(function() {

    var setup_inline_request_form = function(uri) {
	modal = $('#inline_request_modal');
	send_btn = modal.find('.action-btn');
	send_btn.html('Send Request');

	send_btn.click(function(e) {
	    modal.find('.page_action, .request').click();
 	    modal.modal('hide');
	});

	$('#inline-aeon-request-form').html('Retrieving request information ...');
	modal.modal('show');

	$.ajax("/plugin/inline_aeon_request_form", {
	    data: {
		uri: uri
	    },
	    type: "GET",
	}).done(function(form) {
	    request_form = $('#inline-aeon-request-form');
	    request_form.html(form);
	    if (request_form.find('.page_action, .request').attr('disabled')) {
	        $('#inline_request_modal').find('.action-btn').attr('disabled', true);
	    }
	    request_form.find('.page_action, .request').hide();
	}).fail(function() {
	    $('#inline-aeon-request-form').html('Unable to retrieve request information');
	    $('#inline_request_modal').find('.action-btn').attr('disabled', true);
	});
    };

    window.setup_inline_request_form = setup_inline_request_form;
});
