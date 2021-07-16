const StrategyBlizzardLP = artifacts.require("../../contracts/Compounding/StrategyBlizzardLP.sol");
const DisruptVault = artifacts.require("../../contracts/Compounding/DisruptVault.sol");
const FakeWBNB = artifacts.require("../../contracts/Fakes/FakeWBNB.sol");
const FakeBusd = artifacts.require("../../contracts/Fakes/FakeBusd.sol");
const FakeTusk = artifacts.require("../../contracts/Fakes/FakeTusk.sol");
const FakeTuskWBNB = artifacts.require("../../contracts/Fakes/FakeTuskWBNB.sol");
const FakePancakeRouter = artifacts.require("../../contracts/Fakes/FakePancakeRouter.sol");
const FakeMasterChef = artifacts.require("../../../contracts/Fakes/FakeMasterChef.sol");
const addresses = require("../../addresses.json");

module.exports = async function (deployer) {
  let disruptVaultInstance = await DisruptVault.deployed();

  let fakeBusd = await FakeBusd.deployed();
  let fakeTusk = await FakeTusk.deployed();
  let fakeTuskWBNB = await FakeTuskWBNB.deployed();
  let fakeWBNB = await FakeWBNB.deployed();
  let fakePancakeRouter = await FakePancakeRouter.deployed();
  let fakeMasterChef = await FakeMasterChef.deployed();


  await deployer.deploy(StrategyBlizzardLP, fakeTuskWBNB.address, disruptVaultInstance.address, 
	fakePancakeRouter.address, addresses.strategyOwner, addresses.disruptTreasury, fakeMasterChef.address, 
	fakeWBNB.address, fakeTusk.address, fakeBusd.address, addresses.gasprice);

  let strategyBlizzardLPInstance = await StrategyBlizzardLP.deployed();
  await disruptVaultInstance.setInitialStrategy(strategyBlizzardLPInstance.address);
};