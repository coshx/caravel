Caravel.getDefault().register("Before", function(name, data) {
    $('body').append('<p class="js">Before</p>');
});

Caravel.getDefault().register("After", function(name, data) {
    $('body').append('<p class="js">After</p>');
});