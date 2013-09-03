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

// Redirect to the proper checkout screen for quantity
$(document).ready(function() {
    var selectedProduct = "";

    function setSelectedProduct() {
        selectedProduct = $("input[name=product]:checked").val();
    }

    $(".buy-form input[name=product]").change(function() {
        setSelectedProduct();

        var text = selectedProduct.charAt(0).toUpperCase() + selectedProduct.slice(1);
        $("#buy-fusion").text("Buy " + text + " Licenses Now");
    });

    $("#buy-fusion").click(function() {
        var seats = parseInt($("#seats").val(), 10);
        if (isNaN(seats)) {
            alert("The number of seats you want to purchase must be a number.");
            return;
        } else if (seats <= 0) {
            alert("The number of seats you want must be greater than zero.");
            return;
        }

        var productId = "";
        if (selectedProduct == "fusion") {
            productId = "279661674";
        } else if (selectedProduct == "workstation") {
            productId = "302167489";
        } else {
            alert("Unknown product selected. Please refresh and try again.");
            return;
        }

        window.location = "http://shopify.hashicorp.com/cart/" + productId + ":" + seats;
    });

    if ($("#buy-fusion").length > 0) {
        setSelectedProduct();
    }
});
