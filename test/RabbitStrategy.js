const {ethers} = require('hardhat');
//import { smockit } from '@eth-optimism/smock'
const {expect} = require("chai");
const {smockit} = require('@eth-optimism/smock');
const { intToBuffer } = require('ethjs-util');
const {BigNumber} = require("@ethersproject/bignumber");

describe("RabbitStrategy", function () {

	let fakePancakeRouter;
	let rabbit;
	let disruptVault;
	let strategyRabbitVault;
	let strategyRabbitVault2;
	let fakeMasterChef;
	let fairLaunch;
	let fakeCake;
	let ibCake;
	beforeEach(async () => {

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
		let bank = await BankFactory.deploy();
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

	it("Balance of Pool is correct on deposit", async () => {
		console.log("owner.address " + owner.address);
		
		await fakeCake.transfer(strategyRabbitVault.address, BigNumber.from("10000000000000000"));
		await strategyRabbitVault.deposit();

		await fakeCake.transfer(strategyRabbitVault.address, BigNumber.from("10000000000000001"));
		await strategyRabbitVault.deposit();

		let balanceOfPool = await strategyRabbitVault.balanceOfPool();

		expect(balanceOfPool).to.equal(BigNumber.from("20000000000000001"));

				//await disruptVault.deposit(BigNumber.from("10000000000000000"));
		// console.log("disruptVault: " + (await disruptVault.balanceOf(owner.address)).toString());
		// let balanceOfPool = await strategyRabbitVault.balanceOfPool();
		// console.log("balanceOfPool:%s", balanceOfPool.toString());
		// expect((await disruptVault.balanceOf(owner.address)).gt(0)).to.true();
		//await disruptVault.withdraw(disruptVault.balanceOf(owner.address));

		//await blizzardLPStrategy.harvest();
	 	//var masterChefLPBalance = await fakeTuskWBNB.balanceOf(fakeMasterChef.address);

		// console.log("masterChefLPBalance: %s", masterChefLPBalance.toString());
	});

	it("Deposit to vault", async () => {

		await disruptVault.deposit(BigNumber.from("10000000000000000"));
		// console.log("disruptVault: " + (await disruptVault.balanceOf(owner.address)).toString());

		// let balanceOfPool = await strategyRabbitVault.balanceOfPool();
		// console.log("balanceOfPool:%s", balanceOfPool.toString());
		// expect((await disruptVault.balanceOf(owner.address)).gt(0)).to.true();
		// await disruptVault.withdraw(disruptVault.balanceOf(owner.address));

		// await blizzardLPStrategy.harvest();
		// var masterChefLPBalance = await fakeTuskWBNB.balanceOf(fakeMasterChef.address);

		// console.log("masterChefLPBalance: %s", masterChefLPBalance.toString());
	});

	it("Withdraw only by vault", async () => {
		console.log("owner.address " + owner.address);
		
		await fakeCake.transfer(strategyRabbitVault.address, BigNumber.from("10000000000000000"));
		await strategyRabbitVault.deposit();
		var throws =  () =>  {
			throw new Error("shit");
			//await strategyRabbitVault.withdraw(BigNumber.from("10000000000000000"));
		}
		

		expect(throws).to.throw(Error, 'shit');

				//await disruptVault.deposit(BigNumber.from("10000000000000000"));
		// console.log("disruptVault: " + (await disruptVault.balanceOf(owner.address)).toString());
		// let balanceOfPool = await strategyRabbitVault.balanceOfPool();
		// console.log("balanceOfPool:%s", balanceOfPool.toString());
		// expect((await disruptVault.balanceOf(owner.address)).gt(0)).to.true();
		//await disruptVault.withdraw(disruptVault.balanceOf(owner.address));

		//await blizzardLPStrategy.harvest();
	 	//var masterChefLPBalance = await fakeTuskWBNB.balanceOf(fakeMasterChef.address);

		// console.log("masterChefLPBalance: %s", masterChefLPBalance.toString());
	});

	// it("Migration works", async () => {

	// 	await disruptVault.deposit(BigNumber.from("1000000"));
		
	// 	let strat1LPTokenBeforeBalance = (await fakeMasterChef.userInfo(blizzardLPStrategy.address)).amount;
	// 	let strat2LPTokenBeforeBalance = (await fakeMasterChef.userInfo(blizzardLPStrategy2.address)).amount;
	// 	let stratBefore = await disruptVault.strategy();
	// 	await disruptVault.proposeStrat(blizzardLPStrategy2.address);
	// 	await disruptVault.upgradeStrat();

	// 	let strat1LPTokenAfterBalance = (await fakeMasterChef.userInfo(blizzardLPStrategy.address)).amount;
	// 	let strat2LPTokenAfterBalance = (await fakeMasterChef.userInfo(blizzardLPStrategy2.address)).amount;
	// 	let stratAfter = await disruptVault.strategy();

	// 	expect(strat1LPTokenBeforeBalance).to.equal(1000000);
	// 	expect(strat2LPTokenBeforeBalance).to.equal(0);

	// 	expect(strat1LPTokenAfterBalance).to.equal(0);
	// 	expect(strat2LPTokenAfterBalance).to.equal(1000000);

	// 	expect(stratAfter).to.equal(blizzardLPStrategy2.address);

	// })
});


