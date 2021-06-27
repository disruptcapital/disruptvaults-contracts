const GasPrice = artifacts.require("../../contracts/GasPrice.sol");

module.exports = async function (deployer) {
  await deployer.deploy(GasPrice);
};

