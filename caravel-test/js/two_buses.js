Caravel.get("BarBus").register("AnEvent", function(name, data) {
    $('body').append('<p>You should see me first and once</p>');
});

Caravel.get("FooBus").register("AnEvent", function(name, data) {
    $('body').append('<p>You should see me after and once</p>');
});