const StrategyBlizzardLP = artifacts.require("../../contracts/Compounding/StrategyBlizzardLP.sol");
const DisruptVault = artifacts.require("../../contracts/Compounding/DisruptVault.sol");
const addresses = require("../../../addresses.json");

module.exports = async function (deployer) {
  let disruptVaultInstance = await DisruptVault.deployed();

	console.log(addresses.tusk_bnb);
	console.log(disruptVaultInstance.address);
	console.log(addresses.pancakeswapV2);
	console.log(addresses.strategyOwner);
	console.log(addresses.disruptTreasury);
	console.log(addresses.blizzardFarm);

  await deployer.deploy(StrategyBlizzardLP, addresses.tusk_bnb, disruptVaultInstance.address, addresses.pancakeswapV2, addresses.strategyOwner, addresses.disruptTreasury, addresses.blizzardFarm, addresses.wbnb, addresses.tusk, addresses.busd);

  let strategyBlizzardLPInstance = await StrategyBlizzardLP.deployed();
  await disruptVaultInstance.setInitialStrategy(strategyBlizzardLPInstance.address);
};