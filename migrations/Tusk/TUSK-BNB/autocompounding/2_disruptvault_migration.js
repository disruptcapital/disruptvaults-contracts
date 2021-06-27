const DisruptVault = artifacts.require("../../contracts/Compounding/DisruptVault.sol");
const addresses = require("../../../addresses.json");

module.exports = async function (deployer) {
  await deployer.deploy(DisruptVault, "DISRUPTED_TUSK_BNB", "Disrupt Vaults TUSKBNB", 0);
};

