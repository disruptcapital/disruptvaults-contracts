const FakeBusd = artifacts.require("../../contracts/Fakes/FakeBusd.sol");
const FakeTusk = artifacts.require("../../contracts/Fakes/FakeTusk.sol");
const FakeTuskWBNB = artifacts.require("../../contracts/Fakes/FakeTuskWBNB.sol");
const FakeWBNB = artifacts.require("../../contracts/Fakes/FakeWBNB.sol");
const {BigNumber} = require("@ethersproject/bignumber");
const FakePancakeRouter = artifacts.require("../../contracts/Fakes/FakePancakeRouter.sol");
const FakeMasterChef = artifacts.require("../../../contracts/Fakes/FakeMasterChef.sol");
const addresses = require("../../addresses.json");

module.exports = async function (deployer) {
	let fakeBusd = await FakeBusd.deployed();
	let fakeTusk = await FakeTusk.deployed();
	let fakeTuskWBNB = await FakeTuskWBNB.deployed();
	let fakeWBNB = await FakeWBNB.deployed();
	let fakePancakeRouter = await FakePancakeRouter.deployed();
	let fakeMasterChef = await FakeMasterChef.deployed();

	// Mint router some tokens
	await fakeBusd.mint(fakePancakeRouter.address, BigNumber.from("100000000000000000000000"));
	await fakeTusk.mint(fakePancakeRouter.address, BigNumber.from("100000000000000000000000"));
	await fakeTuskWBNB.mint(fakePancakeRouter.address, BigNumber.from("100000000000000000000000"));
	await fakeWBNB.mint(fakePancakeRouter.address, BigNumber.from("100000000000000000000000"));

	// Mint user some tokens
	await fakeBusd.mint(addresses.strategyOwner, BigNumber.from("100000000000000000000000"));
	await fakeTusk.mint(addresses.strategyOwner, BigNumber.from("100000000000000000000000"));
	await fakeTuskWBNB.mint(addresses.strategyOwner, BigNumber.from("100000000000000000000000"));
	await fakeWBNB.mint(addresses.strategyOwner, BigNumber.from("100000000000000000000000"));

	// Mint fake masterchef tokens
	await fakeTusk.mint(fakeMasterChef.address, BigNumber.from("100000000000000000000000"));
};


