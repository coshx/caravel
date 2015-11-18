var sendBackgroundCounter = 0;
var sendBackgroundCounterField = $('.js-send-background-counter');
var receiveBackgroundCounter = 0;
var receiveBackgroundCounterField = $('.js-receive-background-counter');

var sendMainCounter = 0;
var sendMainCounterField = $('.js-send-main-counter');
var receiveMainCounter = 0;
var receiveMainCounterField = $('.js-receive-main-counter');

function append(msg) {
    $('body').append('<p>' + msg + '</p>');
}

Caravel.getDefault().register("BusName", function(name, data) {
    var bus = Caravel.get(data);
    var postAction = function() {
        for (var i = 0; i < 1000; i++) {
            var captureIndex = (function(i) {
                setTimeout(
                    function() {
                        bus.post("Background-" + i);
                        sendBackgroundCounter++;
                        sendBackgroundCounterField.text(sendBackgroundCounter);

                        bus.post("Main-" + i);
                        sendMainCounter++;
                        sendMainCounterField.text(sendMainCounter);
                    },
                    0
                );
            })(i);
        }
    };

    append('Initializing...');

    for (var i = 0; i < 1000; i++) {
        var captureIndex = (function(i) {
            bus.register("Background-" + i + "-confirmation", function() {
                setTimeout(function() {
                    receiveBackgroundCounter++;
                    receiveBackgroundCounterField.text(receiveBackgroundCounter);
                }, 0);
            });

            bus.register("Main-" + i + "-confirmation", function() {
                setTimeout(function() {
                    receiveMainCounter++;
                    receiveMainCounterField.text(receiveMainCounter);
                }, 0);
            });
        })(i);
    }

    bus.register("Ready", function() {
        append('Starting...');
        postAction();
    });
});