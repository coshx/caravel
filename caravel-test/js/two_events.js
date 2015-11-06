Caravel.getDefault().register("ThirdEvent", function(name, data) {
    $('body').append('<p class="js">You should see me and only me</p>');
});

Caravel.getDefault().register("FourthEvent", function(name, data) {
    $('body').append('<p class="js">You should not see me</p>');
});

Caravel.getDefault().post("FirstEvent");