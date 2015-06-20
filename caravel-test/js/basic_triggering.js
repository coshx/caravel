Caravel.getDefault().register("From iOS", function(name, data) {
    $('body').append('<p>Received From iOS!</p>');
});

Caravel.getDefault().post("From JS");
