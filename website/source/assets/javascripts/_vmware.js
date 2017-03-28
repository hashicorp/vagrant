var HashiVMware = function() {
  var selectedProduct = "";

  var $buyButton = $('#buy-fusion');
  var $products = $('#buy-now input[name=product]');

  function setSelectedProduct() {
    selectedProduct = $("input[name=product]:checked").val();
  }

  $products.unbind().on('change', function() {
    setSelectedProduct();

    var text = selectedProduct.charAt(0).toUpperCase() + selectedProduct.slice(1);
  });

  $buyButton.unbind().on('click', function(e) {
    e.preventDefault();

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

  if ($buyButton.length > 0) {
    setSelectedProduct();
  }
}

$(document).on('ready turbolinks:load', HashiVMware)
