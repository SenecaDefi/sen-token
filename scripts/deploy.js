// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const sen = await hre.ethers.getContractFactory("SenTokenOFT");
  console.log('Deploying Seneca...')
  const Seneca = await sen.deploy('0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23', '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');

  await Seneca.deployed();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
