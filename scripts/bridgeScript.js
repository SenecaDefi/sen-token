const hre = require("hardhat");
const { Contract } = require("hardhat/internal/hardhat-network/stack-traces/model");
const fs = require('fs');
const { parseEther } = require("ethers/lib/utils");
const { ethers, hardhatArguments } = require('hardhat');
const { parseUnits } = require('ethers/lib/utils');
// eslint-disable-next-line max-lines-per-function
async function main() {
  const [owner, addr1, addr2, addr3] = await ethers.getSigners();

  const sen = await ethers.getContractAt("SenTokenOFT", '0x8de6aEe2226C6C176461B05f49d293eeb05A788d');
  const Seneca = sen.attach('0x8de6aEe2226C6C176461B05f49d293eeb05A788d');

  const senarb = await ethers.getContractAt("SenTokenOFT", '0x0A9B14d6DC37219dD56320Afb2A5eff090784572');
  const SenecaArbi = senarb.attach('0x0A9B14d6DC37219dD56320Afb2A5eff090784572');
  
  const otherChainId = 101;
  const mainchainId = 110;
  const totalAmount = parseUnits("100", 18);
  const depositAmount = parseUnits("100", 18);
  //await Seneca.approve(Seneca.address, parseUnits('10000000000000000', 18));
  //await SenecaArbi.approve(SenecaArbi.address, parseUnits('10000000000000000', 18));
  //await Seneca.setTrustedRemoteAddress(otherChainId, SenecaArbi.address)
  //await SenecaArbi.setTrustedRemoteAddress(mainchainId, Seneca.address)
  //await SenecaArbi.setUseCustomAdapterParams(false);
  //await Seneca.setUseCustomAdapterParams(false);

  let nativeFee = (await Seneca.estimateSendFee(otherChainId, owner.address, totalAmount, false, "0x")).nativeFee
  console.log('fee', nativeFee);
  //let otherChainFee = (await Seneca.estimateSendFee(otherChainId, owner.address, totalAmount, false, "0x")).nativeFee
  
  //await Seneca.sendFrom(owner.address, otherChainId, owner.address, totalAmount, owner.address, ethers.constants.AddressZero, "0x", { value: nativeFee.add(totalAmount.sub(depositAmount)) } )
  //await SenecaArbi.enableTrading();
  //await Seneca.enableTrading();
  // await Seneca.removeLimits();
  //await Seneca.transfer('0xe433CF97Fe2638A212Ce7F6Bf095F71383a5C9A6', parseUnits('10', 18));
  //await Seneca.setUniswapV2Pair('0x17f5761E749D05e822f8EEbaB9fbF8959a1ecA25');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
