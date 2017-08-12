module.exports = {
  name: 'development',
  environment: 'development',

  // TODO: change to db-per-user scheme, then remove /ephemeral
  couchUrl: 'http://localhost:5984/ephemeral'

  // TODO: setting up pouchdb-server locally with these
  // couchUsername: 'fotis',
  // couchPassword: '123'
};
