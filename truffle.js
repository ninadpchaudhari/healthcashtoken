require('babel-register');
require('babel-polyfill');

module.exports = {
  migrations_directory: "./migrations",
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      gas: 2900000,
      network_id: "*" // Match any network id
    }
  }
};
