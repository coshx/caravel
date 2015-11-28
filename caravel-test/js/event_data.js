function ok(name) {
    $('body').append('<p class="js">' + name + ' ok</p>');
}

function fail(name, data) {
    if ((data instanceof Array) || (data instanceof Object)) {
        data = JSON.stringify(data);
    }
    $('body').append('<p class="js">Failed for ' + name + ': received ' + data + '</p>');
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
    var expected = [1, 2, 3, 5];
    for (var i = 0, s = data.length; i < s; i++) {
        if (data[i] != expected[i]) {
            fail(name, data);
            return
        }
    }

    ok(name);
});

Caravel.getDefault().register("Dictionary", function(name, data) {
    var expected = { foo: 45, bar: 89 };

    for (var key in expected) {
        if (!data.hasOwnKeyProperty(key) || data[key] != expected[key]) {
            fail(name, data);
            return;
        }
    }

    ok(name);
});

Caravel.getDefault().register("ComplexArray", function(name, data) {
    var expectedData = [{name: "Alice", age: 24}, {name: "Bob", age: 23}];
    var customFail = function() {
        fail(name, data);
    };

    if (data.length == 2) {
        if (data[0].name == expectedData[0].name && data[0].age == expectedData[0].age) {
            if (data[1].name == expectedData[1].name && data[1].age == expectedData[1].age) {
                ok(name);
            } else {
                customFail();
            }
        } else {
            customFail();
        }
    } else {
        customFail();
    }
});

Caravel.getDefault().register("ComplexDictionary", function(name, data) {
    var expectedData = {name: "Paul", address: { street: "Hugo", city: "Bordeaux" }, games: ["Fifa", "Star Wars"]};
    var customFail = function() {
        fail(name, data);
    };

    if (data.name == expectedData.name) {
        if (data.address.street == expectedData.address.street && data.address.city == expectedData.address.city) {
            if (data.length == expectedData.length && data.games[0] == expectedData.games[0] && data.games[1] == expectedData.games[1]) {
                ok(name);
            } else {
                customFail();
            }
        } else {
            customFail();
        }
    } else {
        customFail();
    }
});

Caravel.getDefault().register("Ready", function() {
    Caravel.getDefault().post("True", true);
    Caravel.getDefault().post("False", false);
    Caravel.getDefault().post("Int", 987);
    Caravel.getDefault().post("Double", 15.15);
    Caravel.getDefault().post("String", "Napoleon");
    Caravel.getDefault().post("UUID", "9658ae60-9e0d-4da7-a63d-46fe75ff1db1");
    Caravel.getDefault().post("Array", [3, 1, 4]);
    Caravel.getDefault().post("Dictionary", { "movie": "Once upon a time in the West", "actor": "Charles Bronson" });

    Caravel.getDefault().post("ComplexArray", [87, {"name": "Bruce Willis"}, "left-handed" ]);
    Caravel.getDefault().post("ComplexDictionary", {name: "John Malkovich", movies: ["Dangerous Liaisons", "Burn after reading"], kids: 2});
});