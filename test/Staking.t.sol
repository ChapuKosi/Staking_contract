// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RewardToken.sol";
import "../src/StakingContract.sol";

contract StakingFuzzTest is Test {
    StakingContract staking;
    RewardToken reward;

    address alice = address(0xABCD);

    uint256 public constant LOCK_TIME = 2 minutes;
    uint256 public constant REWARD_RATE = 1; // 1 RWD per ETH per min

    function setUp() public {
        // Deploy reward token
        reward = new RewardToken();

        // Deploy staking contract
        staking = new StakingContract(address(reward));

        // Transfer ownership to staking contract so it can mint
        reward.transferOwnership(address(staking));

        // Give Alice some ETH to stake
        vm.deal(alice, 10 ether);
    }

    /// @notice Fuzz test: user can stake any non-zero amount
    function testFuzz_StakeETH(uint128 amount) public {
        vm.assume(amount > 0 && amount < 1 ether);

        vm.prank(alice);
        staking.stake{value: amount}();

        (uint256 ethAmount, uint256 stakedAt) = staking.stakes(alice);
        assertEq(ethAmount, amount);
        assertGt(stakedAt, 0);
    }

    /// @notice Fuzz test: user can unstake after 2 minutes and receive correct RWD
    function testFuzz_UnstakeAfterLock(uint128 amount) public {
        vm.assume(amount > 0 && amount < 1 ether);

        // Alice stakes
        vm.prank(alice);
        staking.stake{value: amount}();

        // Move forward 2 minutes
        vm.warp(block.timestamp + 2 minutes);

        uint256 balanceBefore = reward.balanceOf(alice);

        // Unstake
        vm.prank(alice);
        staking.unstake();

        uint256 expectedRewards = (amount * 1 * 2 minutes) / 60; // 1 RWD per ETH per min

        uint256 balanceAfter = reward.balanceOf(alice);
        assertEq(balanceAfter - balanceBefore, expectedRewards);

        // Stake should be reset
        (uint256 ethAmount, ) = staking.stakes(alice);
        assertEq(ethAmount, 0);
    }

    function testStakeStoresCorrectValues() public {
        uint256 amount = 1 ether;

        vm.prank(alice);
        staking.stake{value: amount}();

        (uint256 storedAmount, uint256 stakedAt) = staking.stakes(alice);

        assertEq(storedAmount, amount);
        assertEq(stakedAt, block.timestamp);
    }

    function testStakeRevertsOnZeroAmount() public {
        vm.expectRevert("Cannot stake 0 ETH");

        vm.prank(alice);
        staking.stake{value: 0}();
    }

    function testUnstakeFailsIfNotEnoughTimePassed() public {
        uint256 amount = 1 ether;
        vm.prank(alice);
        staking.stake{value: amount}();

        vm.expectRevert();
        vm.prank(alice);
        staking.unstake();
    }

    function testUnstakeTransfersCorrectReward() public {
        uint256 amount = 2 ether;

        // Stake
        vm.prank(alice);
        staking.stake{value: amount}();

        // Fast forward time
        vm.warp(block.timestamp + 2 minutes);

        // Get reward token balance before
        uint256 before = reward.balanceOf(alice);

        // Unstake
        vm.prank(alice);
        staking.unstake();

        // Calculate expected reward: 2 ETH * 1 RWD/min * 2 mins = 4 RWD
        uint256 expectedReward = 4 ether;

        uint256 afterBalance = reward.balanceOf(alice);
        assertEq(afterBalance - before, expectedReward);

        // Verify stake was deleted
        (uint256 storedAmount, ) = staking.stakes(alice);
        assertEq(storedAmount, 0);
    }

    function testUnstakeFailsIfNoStake() public {
        vm.expectRevert("No stake found");

        vm.prank(alice);
        staking.unstake();
    }
}
