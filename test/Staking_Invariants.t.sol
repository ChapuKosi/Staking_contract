// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {StakingContract} from "../src/StakingContract.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract StakingInvariantTest is Test {
    StakingContract public staking;
    RewardToken public rewardToken;

    address[] public stakers;
    mapping(address => bool) public isStaker;

    function setUp() public {
        rewardToken = new RewardToken();
        staking = new StakingContract(address(rewardToken));
        rewardToken.transferOwnership(address(staking));
    }

    // Helper to register new stakers
    function _register(address user) internal {
        if (!isStaker[user]) {
            isStaker[user] = true;
            stakers.push(user);
        }
    }

    function stakeEth(uint96 amount) public {
        vm.deal(msg.sender, amount);
        vm.prank(msg.sender);
        staking.stake{value: amount}();
        _register(msg.sender);
    }

    function unstakeEth() public {
        vm.prank(msg.sender);
        try staking.unstake() {
            // OK
        } catch {
            // Ignore revert due to lock period or 0 stake
        }
    }

    function invariant_totalEthBalanceMatchesStakes() public view {
    uint256 totalStaked = 0;

    for (uint256 i = 0; i < stakers.length; i++) {
        (uint256 ethAmount, ) = staking.stakes(stakers[i]);
        totalStaked += ethAmount;
    }

    assertEq(address(staking).balance, totalStaked, "Contract ETH balance should match total staked ETH");
}


    // Include fuzz functions to trigger staking and unstaking
    function testFuzz_stakeAndUnstake(uint96 amount) public {
        amount = uint96(bound(amount, 1 ether, 10 ether));
        stakeEth(amount);

        // Simulate time passing to allow unstake
        vm.warp(block.timestamp + 3 minutes);
        unstakeEth();
    }

    function testUnit_correctRewardAfterUnstake() public {
        address user = address(0xABCD);
        uint256 stakeAmount = 1 ether;
        vm.deal(user, stakeAmount);

        vm.prank(user);
        staking.stake{value: stakeAmount}();
        _register(user);

        vm.warp(block.timestamp + 2 minutes);

        uint256 expectedReward = stakeAmount * 1 * 2; // 1 RWD per ETH per min * 2 min

        vm.prank(user);
        staking.unstake();

        assertEq(rewardToken.balanceOf(user), expectedReward);
    }
}
