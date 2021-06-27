const FakeDisruptVault = artifacts.require("../../contracts/Fakes/FakeDisruptVault.sol");
const addresses = require("../addresses.json");

module.exports = async function (deployer) {
  await deployer.deploy(FakeDisruptVault, addresses.cake, "DISRUPTCAKE", "DisruptedCakeVaultCoin");
};

