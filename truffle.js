require('babel-register');
require('babel-polyfill');

module.exports = {
  migrations_directory: "./migrations",
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      gas: 4712387,
      network_id: "*" // Match any network id
    }
  }
};
