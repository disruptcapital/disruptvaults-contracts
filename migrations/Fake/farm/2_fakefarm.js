const addresses = require("../../addresses.json");
const FakeMasterChef = artifacts.require("../../../contracts/Fakes/FakeMasterChef.sol");


module.exports = async function (deployer) {
  await deployer.deploy(FakeMasterChef, addresses.cake_btd, addresses.cake);
};


