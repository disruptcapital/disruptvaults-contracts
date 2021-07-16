const FakeTuskWBNB = artifacts.require("../../contracts/Fakes/FakeTuskWBNB.sol");
const FakeTusk = artifacts.require("../../contracts/Fakes/FakeTusk.sol");
const FakeWBNB = artifacts.require("../../contracts/Fakes/FakeWBNB.sol");

module.exports = async function (deployer) {
	let fakeTusk = await FakeTusk.deployed();
	let fakeWBNB = await FakeWBNB.deployed();

  await deployer.deploy(FakeTuskWBNB, fakeWBNB.address, fakeTusk.address);
};
