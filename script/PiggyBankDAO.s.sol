// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/PiggyBankDAO.sol";

contract PiggyBankDAOScript is Script {
    

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        PiggyBankDAO dao = new PiggyBankDAO();
        console2.log("PiggyBank", address(dao));
        vm.stopBroadcast();
    }
}
