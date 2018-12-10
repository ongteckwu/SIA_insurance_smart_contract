var Insurance = artifacts.require ("./contracts/Insurance.sol");
// var ExampleOracle = artifacts.require ("./contracts/ExampleOracle.sol");
module.exports = function(deployer) {
      deployer.deploy(Insurance);
      // deployer.deploy(ExampleOracle);
}