function append(msg) {
    $('body').append('<p>' + msg + '</p>');
}

var firstBus = Caravel.get("First");
var secondBus = Caravel.get("Second");

secondBus.register("FromMain", function(name) {
    append(name);
    secondBus.post("FromJSForMain");
});

secondBus.register("FromMainAfterFromJS", function(name) {
    append(name);
});

firstBus.register("FromBackground", function(name) {
    append(name);
    firstBus.post("FromJSForBackground");
})

firstBus.register("FromBackgroundAfterFromJS", function(name) {
    append(name);
});