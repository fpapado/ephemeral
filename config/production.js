module.exports = {
  name: 'production',
  environment: 'production',

  // TODO: change to db-per-user scheme, then remove /ephemeral
  couchUrl: 'https://ephemeral.fltbx.xyz:6984/ephemeral'
};
