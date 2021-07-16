const FakeMasterChef = artifacts.require("../../../contracts/Fakes/FakeMasterChef.sol");
const FakeTusk = artifacts.require("../../contracts/Fakes/FakeTusk.sol");
const FakeTuskWBNB = artifacts.require("../../contracts/Fakes/FakeTuskWBNB.sol");

module.exports = async function (deployer) {

	let fakeTusk = await FakeTusk.deployed();
	let fakeTuskWBNB = await FakeTuskWBNB.deployed();
	
	await deployer.deploy(FakeMasterChef, fakeTuskWBNB.address, fakeTusk.address);
};


