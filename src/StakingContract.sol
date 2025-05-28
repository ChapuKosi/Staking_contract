// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "./RewardToken.sol";

contract StakingContract is ReentrancyGuard, Ownable(msg.sender) {
    RewardToken public rewardToken;
    uint256 public constant LOCK_TIME = 2 minutes;
    uint256 public constant REWARD_RATE = 1; // 10 RWD per ETH per week
    uint256 public constant MINUTE = 1 minutes;

    struct Stake {
        uint256 ethAmount;
        uint256 stakedAt;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 ethReturned, uint256 rewards);

    constructor(address _rewardToken) {
        rewardToken = RewardToken(_rewardToken);
    }

    function stake() external payable nonReentrant {
        require(msg.value > 0, "Cannot stake 0 ETH");
        stakes[msg.sender] = Stake(msg.value, block.timestamp);
        emit Staked(msg.sender, msg.value);
    }

    function unstake() external nonReentrant {
        Stake memory userStake = stakes[msg.sender];
        require(userStake.ethAmount > 0, "No stake found");
        uint256 unlockTime = userStake.stakedAt + LOCK_TIME;
        if (block.timestamp < unlockTime) {
            uint256 remaining = unlockTime - block.timestamp;
            revert(
                string(
                    abi.encodePacked(
                        "ETH locked. Remaining time: ",
                        Strings.toString(remaining),
                        " seconds"
                    )
                )
            );
        }

        // Calculate RWD rewards (e.g., 10 RWD per ETH per week)
        uint256 duration = block.timestamp - userStake.stakedAt;
        uint256 rewards = (userStake.ethAmount * REWARD_RATE * duration) / MINUTE; // Weekly rewards

        // Transfer ETH back to user
        (bool success, ) = msg.sender.call{value: userStake.ethAmount}("");
        require(success, "ETH transfer failed");

        // Reset stake
        delete stakes[msg.sender];
        emit Unstaked(msg.sender, userStake.ethAmount, rewards);

        // Mint and send RWD rewards
        rewardToken.mint(msg.sender, rewards);
    }
}