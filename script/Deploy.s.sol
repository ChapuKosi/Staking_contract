// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/RewardToken.sol";
import "../src/StakingContract.sol";

contract DeployScript is Script {
    function run() external {
        // Load the deployer's private key from environment or hardcoded (not safe for prod)
        uint256 deployerKey = vm.envUint("PRIVATE_KEY"); // or use vm.envBytes32 if needed
        vm.startBroadcast(deployerKey);

        // Deploy RewardToken (you will be the owner)
        RewardToken rewardToken = new RewardToken();

        // Deploy StakingContract, passing in reward token address
        StakingContract staking = new StakingContract(address(rewardToken));

        // Transfer ownership of RewardToken to StakingContract
        rewardToken.transferOwnership(address(staking));

        console.log("RewardToken deployed to:", address(rewardToken));
        console.log("StakingContract deployed to:", address(staking));

        vm.stopBroadcast();
    }
}
