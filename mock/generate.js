module.exports = function(){
  const faker = require("faker");
  const _ = require("lodash");

  return {
    notes: _.times(10, function(n) {
      let {latitude, longitude} = randomGeo({latitude: 60.1719, longitude: 24.9414}, 2000);

      return {
        content: faker.lorem.word(),
        translation: faker.lorem.word(),
        added_at: faker.date.recent(),
        location: {
          latitude: JSON.stringify(latitude),
          longitude: JSON.stringify(longitude),
          accuracy: "1.0"
        },
        id: n
      };
    })
  }
}

function randomGeo(center, radius) {
    var y0 = center.latitude;
    var x0 = center.longitude;
    var rd = radius / 111300;

    var u = Math.random();
    var v = Math.random();

    var w = rd * Math.sqrt(u);
    var t = 2 * Math.PI * v;
    var x = w * Math.cos(t);
    var y = w * Math.sin(t);

    return {
        'latitude': y + y0,
        'longitude': x + x0
    };
}
