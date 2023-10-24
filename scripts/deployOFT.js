const hre = require("hardhat");
const { Contract } = require("hardhat/internal/hardhat-network/stack-traces/model");
const fs = require('fs');

async function main() {

  const sen = await hre.ethers.getContractFactory("SenTokenOFT");
  console.log('Deploying Seneca...')
  const Seneca = await sen.deploy('0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab', '0xA91527e5a4CE620e5a18728e52572769DcEcdb99');
  console.log('deployed');

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
