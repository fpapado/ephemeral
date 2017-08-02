module.exports = function(){
  const faker = require("faker");
  const _ = require("lodash");

  return {
    notes: {
      notes: _.times(10, function(n) {
        return {
          id: n,
          content: faker.lorem.word(),
          translation: faker.lorem.word(),
          added_at: faker.date.recent(),
          location: {
            latitude: faker.address.longitude(),
            longitude: faker.address.latitude(),
            accuracy: 1.0
          }
        };
      })
    }
  }
}
