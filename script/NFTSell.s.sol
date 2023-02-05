// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import "../src/NFTSell.sol";
import "../src/NFT.sol";

contract DeployNFTSell is Script {
    NFT public nft;

    function run() public {
        vm.startBroadcast();
        new NFTSell(nft);
        vm.stopBroadcast();
    }
}
