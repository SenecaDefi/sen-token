const hre = require("hardhat");
const { Contract } = require("hardhat/internal/hardhat-network/stack-traces/model");
const fs = require('fs');

async function main() {

  const sen = await hre.ethers.getContractFactory("SenTokenNativeOFT");
  console.log('Deploying Seneca...')
  const Seneca = await sen.deploy('0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23', '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');
  console.log('deployed');

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
