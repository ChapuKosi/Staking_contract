// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {
    constructor() ERC20("Reward Token", "RWD") Ownable(msg.sender) {}

    // Only the staking contract can mint RWD
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
