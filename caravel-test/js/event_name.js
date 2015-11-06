Caravel.getDefault().register("Foo", function(name, data) {
    if (name == "Foo") {
        $('body').append('<p class="js">You should see me</p>');
    } else {
        $('body').append('<p class="js">You should not see me</p>');
    }
});

Caravel.getDefault().register("Foobar", function(name, data) {
    $('body').append('<p class="js">You should not see me</p>');
});

Caravel.getDefault().post('Bar');