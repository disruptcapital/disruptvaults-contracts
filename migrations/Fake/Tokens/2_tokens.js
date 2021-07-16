const FakeWBNB = artifacts.require("../../contracts/Fakes/FakeWBNB.sol");
const FakeBusd = artifacts.require("../../contracts/Fakes/FakeBusd.sol");
const FakeTusk = artifacts.require("../../contracts/Fakes/FakeTusk.sol");

module.exports = async function (deployer) {
  await deployer.deploy(FakeWBNB);
  await deployer.deploy(FakeBusd);
  await deployer.deploy(FakeTusk);
};

