Caravel.getDefault().register("Before", function(name, data) {
    $('body').append('<p>Before</p>');
});

Caravel.getDefault().register("After", function(name, data) {
    $('body').append('<p>After</p>');
});