// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {SenToken} from "../../contracts/Sen.sol";

contract TokenScriptL1 is Script {
    address EthMainnetLzEndpoint = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675; //TODO
    // uint16 EthMainnetChainId = 101;
    // address ArbLzEndpoint = 0x3c2269811836af69497E5F486A85D7316753cf62;
    // uint16 ArbChainId = 110;

    function run() public returns (SenToken token1) {
        vm.startBroadcast();

        // Deploy the token on the mainnet
        token1 = new SenToken(EthMainnetLzEndpoint);
        console.log("Token deployed on mainnet: ", address(token1));

        vm.stopBroadcast();
    }
}
