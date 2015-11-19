function append(msg) {
    $('body').append('<p>' + msg + '</p>');
}

var bus = Caravel.getDefault();

bus.register("Hello!", function(name) {
    append(name);
    bus.post("Whazup?");
});

bus.register("Bye", function(name) {
    append(name);
    setTimeout(
        function() {
            bus.post("Still around?");
            append("Still around just sent");
        },
        4000
    );
});