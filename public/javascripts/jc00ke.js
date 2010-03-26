$(document).ready(function(){
    // pop external links in new window/tab
	$("a[href^='http']").attr('target','_blank');

    // set active nav item
    var active = $('body').attr('class');
    $('nav a[href$="' + active + '"]').addClass('active');
});
