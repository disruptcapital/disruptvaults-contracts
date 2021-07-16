const DisruptVault = artifacts.require("../../contracts/Compounding/DisruptVault.sol");

module.exports = async function (deployer) {
  await deployer.deploy(DisruptVault, "DISRUPTED_TUSK_BNB", "Disrupt Vaults TUSKBNB", 0);
};

