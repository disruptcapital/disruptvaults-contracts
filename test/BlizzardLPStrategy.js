const {ethers} = require('hardhat');
//import { smockit } from '@eth-optimism/smock'
const {expect} = require("chai");
const {smockit} = require('@eth-optimism/smock');
const { intToBuffer } = require('ethjs-util');
const {BigNumber} = require("@ethersproject/bignumber");

describe("BaseStrategy", function () {

	let fakePancakeRouter;
	let fakeTuskWBNB;
	let disruptVault;
	let blizzardLPStrategy;
	let fakeTusk;
	let fakeMasterChef;
	beforeEach(async () => {

		[owner, user2] = await ethers.getSigners();

		const FakePancakeRouterFactory = await ethers.getContractFactory('FakePancakeRouter');
		fakePancakeRouter = await FakePancakeRouterFactory.deploy();
		
		const FakeTuskFactory = await ethers.getContractFactory('FakeTusk');
		fakeTusk = await FakeTuskFactory.deploy();

		const FakeWBNBFactory = await ethers.getContractFactory('FakeWBNB');
		const fakeWBNB = await FakeWBNBFactory.deploy();

		const FakeBusdFactory = await ethers.getContractFactory('FakeBusd');
		const fakeBusd = await FakeBusdFactory.deploy();

		const FakeTuskWBNBFactory = await ethers.getContractFactory('FakeTuskWBNB');
		fakeTuskWBNB = await FakeTuskWBNBFactory.deploy(fakeWBNB.address, fakeTusk.address);

		const FakeMasterChefFactory = await ethers.getContractFactory('FakeMasterChef');
		fakeMasterChef = await FakeMasterChefFactory.deploy(fakeTuskWBNB.address, fakeTusk.address);

		const GasPriceFactory = await ethers.getContractFactory("GasPrice");
		const gasPrice = await GasPriceFactory.deploy(BigNumber.from("10000000000"));

		 const DisruptVaultFactory = await ethers.getContractFactory('DisruptVault');
		 disruptVault = await DisruptVaultFactory.deploy("DisruptTUSKBNB", "DisruptTUSKBNB", 0);
	


		 const BlizzardLPStrategyFactory = await ethers.getContractFactory("StrategyBlizzardLP");
		 blizzardLPStrategy = await BlizzardLPStrategyFactory.deploy(fakeTuskWBNB.address, disruptVault.address, fakePancakeRouter.address, owner.address, owner.address, fakeMasterChef.address,
			fakeWBNB.address, fakeTusk.address, fakeBusd.address, gasPrice.address);

			await disruptVault.setInitialStrategy(blizzardLPStrategy.address);
			await fakeTusk.mint(fakeMasterChef.address, BigNumber.from("10000000000000000000000"));
			await fakeTuskWBNB.mint(owner.address, BigNumber.from("10000000000000000000000"));
			await fakeTusk.mint(fakePancakeRouter.address, BigNumber.from("10000000000000000000000"))
			await fakeWBNB.mint(fakePancakeRouter.address, BigNumber.from("10000000000000000000000"))
			await fakeTuskWBNB.mint(fakePancakeRouter.address, BigNumber.from("10000000000000000000000"))
			await fakeTuskWBNB.approve(disruptVault.address, BigNumber.from("10000000000000000000000"));
			
			await fakePancakeRouter.mapTokens(await fakeTuskWBNB.token0(),await fakeTuskWBNB.token1(), fakeTuskWBNB.address);
		});

	it("Should just work", async () => {

		await disruptVault.deposit(BigNumber.from("1000000"));
		await disruptVault.withdraw(BigNumber.from("0"));

		await blizzardLPStrategy.harvest();
	 	var masterChefLPBalance = await fakeTuskWBNB.balanceOf(fakeMasterChef.address);

		 console.log("masterChefLPBalance: %s", masterChefLPBalance.toString());
	})
});


