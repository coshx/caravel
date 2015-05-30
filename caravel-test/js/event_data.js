function ok(name) {
    $('body').append('<p>' + name + ' ok</p>');
}

function fail(name, data) {
    $('body').append('<p>Failed for ' + name + ': received ' + data + '</p>');
}

Caravel.getDefault().register("Bool", function(name, data) {
    if (data == true) {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().register("Int", function(name, data) {
    if (data == 42) {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().register("Float", function(name, data) {
    if (data == 19.92) {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().register("Double", function(name, data) {
    if (data == 20.15) {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().register("Array", function(name, data) {
    if (data == [1, 2, 3, 5]) {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().register("Dictionary", function(name, data) {
    if (data == { foo: 45, bar: 89 }) {
        ok(name);
    } else {
        fail(name, data);
    }
});
