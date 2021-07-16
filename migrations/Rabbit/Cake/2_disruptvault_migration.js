const DisruptVault = artifacts.require("../../contracts/Compounding/DisruptVault.sol");
const addresses = require("../../addresses.json");

module.exports = async function (deployer) {
  await deployer.deploy(DisruptVault, "DISRPTD_CAKE", "Disrupt Vaults CAKERABBIT", 0);
};

