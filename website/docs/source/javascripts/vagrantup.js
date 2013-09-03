// add dropshadow to nav on scroll
$(document).ready(function(){
  $(document).scroll(function() {
    var top = $(document).scrollTop();
    if (top > 0) $('nav').addClass("drop-shadow");
    if (top === 0) $('nav').removeClass("drop-shadow");
  });
});

// open/close documentation side nav on small screens
$(document).ready(function(){
  $(".toggle").click(function() {
    $(".sidebar-nav ul").slideToggle('slow');
  });
});
