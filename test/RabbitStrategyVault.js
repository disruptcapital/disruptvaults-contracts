const { ethers } = require('hardhat');
//import { smockit } from '@eth-optimism/smock'
const { expect } = require("chai");
const { smockit } = require('@eth-optimism/smock');
const { intToBuffer } = require('ethjs-util');
const { BigNumber } = require("@ethersproject/bignumber");

describe("RabbitStrategyVault", function ()
{

	let fakePancakeRouter;
	let rabbit;
	let disruptVault;
	let strategyRabbitVault;
	let strategyRabbitVault2;
	let fakeMasterChef;
	let fairLaunch;
	let fakeCake;
	let ibCake;
	let bank;
	beforeEach(async () =>
	{

		[owner, user2] = await ethers.getSigners();

		const FakePancakeRouterFactory = await ethers.getContractFactory('FakePancakeRouter');
		fakePancakeRouter = await FakePancakeRouterFactory.deploy();

		const FakeWBNBFactory = await ethers.getContractFactory('FakeWBNB');
		const fakeWBNB = await FakeWBNBFactory.deploy();




		const FakeCakeFactory = await ethers.getContractFactory('FakeCake');
		fakeCake = await FakeCakeFactory.deploy();
		fakeCake.mint(owner.address, BigNumber.from("9000000000000000000"));

		const rabbitFactory = await ethers.getContractFactory('Rabbit');
		rabbit = await rabbitFactory.deploy();



		const GasPriceFactory = await ethers.getContractFactory("GasPrice");
		const gasPrice = await GasPriceFactory.deploy(BigNumber.from("10000000000"));

		const DisruptVaultFactory = await ethers.getContractFactory('DisruptVault');
		disruptVault = await DisruptVaultFactory.deploy("DisruptRabbitCake", "DisruptRabbitCake", 0);



		const BankFactory = await ethers.getContractFactory("Bank");
		bank = await BankFactory.deploy();
		await bank.addBank(fakeCake.address, "ibCake");
		let banks = await bank.banks(fakeCake.address);


		const tokenArtifact = await artifacts.readArtifact("IBToken");
		ibCake = new ethers.Contract(banks.ibTokenAddr, tokenArtifact.abi, ethers.provider);

		const FairLaunchFactory = await ethers.getContractFactory('FairLaunch');
		fairLaunch = await FairLaunchFactory.deploy(rabbit.address, owner.address, 5, 1, 999999999);
		await fairLaunch.addPool(BigNumber.from("100000000000000000000"), ibCake.address, false)
		await fairLaunch.addPool(BigNumber.from("100000000000000000000"), fakeCake.address, false)


		const StrategyRabbitVaultFactory = await ethers.getContractFactory("StrategyRabbitVault");
		strategyRabbitVault = await StrategyRabbitVaultFactory.deploy(fakeCake.address,
			disruptVault.address, fakePancakeRouter.address, owner.address, owner.address,
			bank.address, fairLaunch.address, fakeWBNB.address, rabbit.address, gasPrice.address, ibCake.address, 0);

		await disruptVault.setInitialStrategy(strategyRabbitVault.address);

		//await fakePancakeRouter.mapTokens(await fakeTuskWBNB.token0(),await fakeTuskWBNB.token1(), fakeTuskWBNB.address);

		fakeCake.approve(disruptVault.address, BigNumber.from("9000000000000000000"));
		fakeCake.approve(fairLaunch.address, BigNumber.from("9000000000000000000"));
		fakeCake.approve(strategyRabbitVault.address, BigNumber.from("9000000000000000000"));
	});


	describe("wantToIBTokens", async () => {
		it("Single staker, no interest", async () => {
			await fakeCake.mint(strategyRabbitVault.address, BigNumber.from("100000000000000000"));
			await strategyRabbitVault.deposit();
	
			let wantToIBToken = await strategyRabbitVault.wantToIBToken(BigNumber.from("100000000000000000"));
	
			expect(wantToIBToken.toString()).to.equal(BigNumber.from("100000000000000000").toString());
		
		});

		it("Single staker, with interest", async () => {
			await fakeCake.mint(strategyRabbitVault.address, BigNumber.from("100000000000000000"));
			await strategyRabbitVault.deposit();
			await fakeCake.mint(bank.address, BigNumber.from("20000000000000000"));
			await bank.addFunds(fakeCake.address, BigNumber.from("20000000000000000"));

			let wantToIBToken = await strategyRabbitVault.wantToIBToken(BigNumber.from("120000000000000000"));
	
			expect(wantToIBToken.toString()).to.equal(BigNumber.from("100000000000000000").toString());
		
		});

		it("Multi staker, with interest", async () => {
			await fakeCake.mint(strategyRabbitVault.address, BigNumber.from("100000000000000000"));
			await strategyRabbitVault.deposit();
			await fakeCake.mint(bank.address, BigNumber.from("20000000000000000"));
			await bank.addFunds(fakeCake.address, BigNumber.from("20000000000000000"));

			let wantToIBToken = await strategyRabbitVault.wantToIBToken(BigNumber.from("60000000000000000"));
	
			expect(wantToIBToken.toString()).to.equal(BigNumber.from("50000000000000000").toString());
		
		});
	});

	describe("withdrawing", async () =>
	{
		it("Can withdrawAll after interest", async () =>
		{
			let startingOwnerBalance = await fakeCake.balanceOf(owner.address);
			await fakeCake.transfer(strategyRabbitVault.address, BigNumber.from("10000000000000003"));
			let ownerBalanceAfterTransfer = await fakeCake.balanceOf(owner.address);

			await strategyRabbitVault.deposit()

			await fakeCake.mint(bank.address, BigNumber.from("300000000000009"));
			await bank.addFunds(fakeCake.address, BigNumber.from("300000000000009"));
			await strategyRabbitVault.withdraw(BigNumber.from("40000000000000012"));

			let afterBalance = await fakeCake.balanceOf(owner.address);

			console.log("startingOwnerBalance: %s", startingOwnerBalance.toString());
			console.log("ownerBalanceAfterTransfer: %s", ownerBalanceAfterTransfer.toString());
			console.log("afterBalance: %s", afterBalance.toString());

			expect(startingOwnerBalance).to.equal(afterBalance);
			expect(await strategyRabbitVault.balanceOfPool()).to.equal(BigNumber.from("0"));

			//expect(currentBalance.toString()).to.equal(afterBalance.toString());
			// console.log("disruptVault: " + (await disruptVault.balanceOf(owner.address)).toString());

			// let balanceOfPool = await strategyRabbitVault.balanceOfPool();
			// console.log("balanceOfPool:%s", balanceOfPool.toString());
			// expect((await disruptVault.balanceOf(owner.address)).gt(0)).to.true();
			// await disruptVault.withdraw(disruptVault.balanceOf(owner.address));

			// await blizzardLPStrategy.harvest();
			// var masterChefLPBalance = await fakeTuskWBNB.balanceOf(fakeMasterChef.address);

			// console.log("masterChefLPBalance: %s", masterChefLPBalance.toString());
		});
	});

	describe("Depositing", async () =>
	{
		it("Balance of pool is correct", async () =>
		{

			await disruptVault.deposit(BigNumber.from("10000000000000003"));
			await disruptVault.deposit(BigNumber.from("10000000000000001"));


			expect(await strategyRabbitVault.balanceOfPool()).to.equal(BigNumber.from("20000000000000004"));
		});

		it("Can withdrawAll", async () =>
		{
			let startingOwnerBalance = await fakeCake.balanceOf(owner.address);
			await fakeCake.transfer(strategyRabbitVault.address, BigNumber.from("10000000000000003"));
			let ownerBalanceAfterTransfer = await fakeCake.balanceOf(owner.address);

			await strategyRabbitVault.deposit()
			await strategyRabbitVault.withdraw(BigNumber.from("10000000000000003"));

			let afterBalance = await fakeCake.balanceOf(owner.address);

			console.log("startingOwnerBalance: %s", startingOwnerBalance.toString());
			console.log("ownerBalanceAfterTransfer: %s", ownerBalanceAfterTransfer.toString());
			console.log("afterBalance: %s", afterBalance.toString());

			expect(startingOwnerBalance).to.equal(afterBalance);
			expect(await strategyRabbitVault.balanceOfPool()).to.equal(BigNumber.from("0"));


		});

	})



});


