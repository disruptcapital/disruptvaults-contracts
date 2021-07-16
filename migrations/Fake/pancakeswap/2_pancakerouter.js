const FakePancakeRouter = artifacts.require("../../../contracts/Fakes/FakePancakeRouter.sol");


module.exports = async function (deployer) {
  await deployer.deploy(FakePancakeRouter);
};


