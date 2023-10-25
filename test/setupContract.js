const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { increaseTo } = require('@nomicfoundation/hardhat-network-helpers/dist/src/helpers/time');
const { expect } = require('chai');
const { ethers, hardhatArguments } = require('hardhat');
const { parseUnits } = require('ethers/lib/utils');
// eslint-disable-next-line max-lines-per-function
describe('Seneca Contract', () => {


    describe('SUCCESS SCENARIOS', () => {
        it('it should make a call to contract with no reverts', async () => {
            const [owner, addr1, addr2, addr3] = await ethers.getSigners();

            const sen = await ethers.getContractAt("SenTokenOFT", '0x813706a5B9AD2eb4D7d021CD5C7e2684CFBD5b3E');
            const Seneca = sen.attach('0x813706a5B9AD2eb4D7d021CD5C7e2684CFBD5b3E');

            const senarb = await ethers.getContractAt("SenTokenOFT", '0xe3ab450F05a946Beb89F2f9808A2beB5B905aa47');
            const SenecaArbi = senarb.attach('0xe3ab450F05a946Beb89F2f9808A2beB5B905aa47');
            
            const otherChainId = 10143;
            const mainchainId = 10121;
            const totalAmount = parseUnits("100", 18);
            const depositAmount = parseUnits("100", 18);
            //await Seneca.approve(Seneca.address, parseUnits('10000000000000000', 18));
            //await SenecaArbi.approve(SenecaArbi.address, parseUnits('10000000000000000', 18));
            //await Seneca.setTrustedRemoteAddress(otherChainId, SenecaArbi.address)
            //await SenecaArbi.setTrustedRemoteAddress(mainchainId, Seneca.address)
            //await SenecaArbi.setUseCustomAdapterParams(false);
            //await Seneca.setUseCustomAdapterParams(false);

            //let nativeFee = (await SenecaArbi.estimateSendFee(mainchainId, owner.address, totalAmount, false, "0x")).nativeFee
            //let otherChainFee = (await Seneca.estimateSendFee(otherChainId, owner.address, totalAmount, false, "0x")).nativeFee
            
            //await SenecaArbi.sendFrom(owner.address, mainchainId, owner.address, totalAmount, owner.address, ethers.constants.AddressZero, "0x", { value: nativeFee.add(totalAmount.sub(depositAmount)) } )
            //await SenecaArbi.enableTrading();
            //await Seneca.enableTrading();
            // await Seneca.removeLimits();
            //await Seneca.transfer('0xe433CF97Fe2638A212Ce7F6Bf095F71383a5C9A6', parseUnits('10', 18));
            await Seneca.setUniswapV2Pair('0x17f5761E749D05e822f8EEbaB9fbF8959a1ecA25');
            return {
               owner, addr1, addr2, addr3, Seneca, 
            };
        });
  });
});