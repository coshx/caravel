Caravel.getDefault().register("AnEvent", function(name, data) {
    $('body').append('<p>First!</p>');
});

Caravel.getDefault().register("AnEvent", function(name, data) {
    $('body').append('<p>Second!</p>');
});