const FakePancakeRouter = artifacts.require("../../contracts/Fakes/FakePancakeRouter.sol");
const FakeTusk = artifacts.require("../../contracts/Fakes/FakeTusk.sol");
const FakeTuskWBNB = artifacts.require("../../contracts/Fakes/FakeTuskWBNB.sol");
const FakeWBNB = artifacts.require("../../contracts/Fakes/FakeWBNB.sol");

module.exports = async function (deployer) {
  await deployer.deploy(FakePancakeRouter);
  let fakePancakeRouter = await FakePancakeRouter.deployed();


  let fakeTusk = await FakeTusk.deployed();
  let fakeTuskWBNB = await FakeTuskWBNB.deployed();
  let fakeWBNB = await FakeWBNB.deployed();


  await fakePancakeRouter.mapTokens(fakeTusk.address, fakeWBNB.address, fakeTuskWBNB.address);
};


