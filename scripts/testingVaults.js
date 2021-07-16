import 
const hre = require("hardhat");
require("@nomiclabs/hardhat-ethers");
// const hre = require("hardhat");


hre.network.provider.request({method: "hardhat_impersonateAccount", params: ["0xBb32eb776DFAe148d9515A5583823fF272c0737A"]});

// const provider = new ethers.providers.JsonRpcProvider();
// const fs = require('fs');
// const abi = JSON.parse(fs.readFileSync('./abi/SomeContract.json', 'utf8'));
// const contractInstance = new ethers.Contract('contract address goes here', abi, provider);