$(document).on("turbolinks:load", function() {
    $('.slider-nav').slick({
        slidesToShow: 3,
        slidesToScroll: 1,
        dots: true,
        arrows: true,
        centerMode: true,
        focusOnSelect: true,
        adaptiveHeight: true,
    });

    searchOnTextInput($('.new-product-page .search-term'), '/products/table', buildProductQuery, function(data) {
        $('#suggested-products').html(data);
    });
});

function buildProductQuery() {
    var query = {};
    var q = $('.new-product-page .search-term:not(#gtin-input)')
        .map(function() {
            return $(this).val();
        })
        .get()
        .filter(function(searchTerm) {
            return searchTerm;
        })
        .map(function(searchTerm) {
            return searchTerm + "*"
        }).join(" OR ");
        var gtin = $('.new-product-page #gtin-input').val();
    if (q) {
        query.q = q;
    }
    if (gtin) {
        query.gtin = gtin;
    }
    return query;
}
