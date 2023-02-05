// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/NFT.sol";

contract DeployNFT is Script {
    function run() public {
        vm.startBroadcast();
        new NFT("NFT Sell Token", "NST");
        vm.stopBroadcast();
    }
}
