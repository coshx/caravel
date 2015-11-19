var bus = Caravel.getDefault();

bus.register("Foo", function() {
    $('body').append('<p>Foo</p>');
    bus.post("Bar");
});