function ok(name) {
    $('body').append('<p>' + name + ' ok</p>');
}

function fail(name, data) {
    if ((data instanceof Array) || (data instanceof Object)) {
        data = JSON.stringify(data);
    }
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
    if (data.toFixed(2) == 19.92) {
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

Caravel.getDefault().register("String", function(name, data) {
    if (data == "Churchill") {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().register("HazardousString", function(name, data) {
    if (data == "There is a \" and a '") {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().register("Array", function(name, data) {
    if (JSON.stringify(data) == JSON.stringify([1, 2, 3, 5])) {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().register("ComplexArray", function(name, data) {
    if (JSON.stringify(data) == JSON.stringify([{name: "Alice", age: 24}, {name: "Bob", age: 23}])) {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().register("ComplexDictionary", function(name, data) {
    if (JSON.stringify(data) == JSON.stringify({name: "Cesar", address: { street: "Parrot", city: "Perigueux" }, games: ["Fifa", "Star Wars"]})) {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().register("Dictionary", function(name, data) {
    if (JSON.stringify(data) == JSON.stringify({ foo: 45, bar: 89 })) {
        ok(name);
    } else {
        fail(name, data);
    }
});

Caravel.getDefault().post("Int", 987);
Caravel.getDefault().post("Float", 19.89);
Caravel.getDefault().post("Double", 15.15);
Caravel.getDefault().post("String", "Napoleon");
Caravel.getDefault().post("Array", [3, 1, 4]);
Caravel.getDefault().post("Dictionary", { "movie": "Once upon a time in the West", "actor": "Charles Bronson" });