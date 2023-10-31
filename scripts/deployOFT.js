const hre = require("hardhat");
const { Contract } = require("hardhat/internal/hardhat-network/stack-traces/model");
const fs = require('fs');

async function main() {

  const sen = await hre.ethers.getContractFactory("TestToken");
  console.log('Deploying Seneca...')
  const Seneca = await sen.deploy('0x3c2269811836af69497E5F486A85D7316753cf62', '0xc873fEcbd354f5A56E00E710B90EF4201db2448d');
  console.log('deployed', Seneca.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
