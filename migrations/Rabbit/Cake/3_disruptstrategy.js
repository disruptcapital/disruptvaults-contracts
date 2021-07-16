const StrategyRabbitVault = artifacts.require("../../contracts/Compounding/StrategyRabbitVault.sol");
const DisruptVault = artifacts.require("../../contracts/Compounding/DisruptVault.sol");
const addresses = require("../../addresses.json");

module.exports = async function (deployer) {
  let disruptVaultInstance = await DisruptVault.deployed();

  await deployer.deploy(StrategyRabbitVault, addresses.cake, disruptVaultInstance.address, 
	addresses.pancakeswapV2, addresses.strategyOwner, addresses.disruptTreasury, addresses.rabbitBank, 
	addresses.rabbitFairLaunch, addresses.wbnb, addresses.rabbit,  addresses.gasprice, addresses.ibCake, addresses.rabbitIBCakePID);

  let strategyRabbitVaultInstance = await StrategyRabbitVault.deployed();
  await disruptVaultInstance.setInitialStrategy(strategyRabbitVaultInstance.address);
};