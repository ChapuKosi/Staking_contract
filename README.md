# Decentralized Staking Platform

A simple decentralized staking platform built with Solidity, featuring an ERC20 reward token and a staking contract. Users can stake ETH, earn reward tokens over time, and withdraw both their ETH and rewards after a lock period.

---

## Features

- **Stake ETH:** Users can stake any amount of ETH.
- **Lock Period:** Staked ETH is locked for a configurable period (default: 2 minutes for testing).
- **Rewards:** Users earn ERC20 reward tokens (`RewardToken`) based on the amount and duration of their stake.
- **Unstake:** After the lock period, users can withdraw their ETH and claim their accumulated rewards.
- **Ownership:** The staking contract is the owner of the reward token and is the only address allowed to mint new rewards.
- **Reentrancy Protection:** All external calls are protected with OpenZeppelin's `ReentrancyGuard`.

---

## Contracts

### 1. `RewardToken.sol`
- ERC20 token used as the staking reward.
- Only the staking contract (as owner) can mint new tokens.

### 2. `StakingContract.sol`
- Handles ETH staking, lock period, reward calculation, and unstaking.
- Calculates rewards based on time staked and amount.
- Emits events for staking and unstaking.

---

## Directory Structure

```
src/
  ├── RewardToken.sol
  └── StakingContract.sol
test/
  ├── Staking.t.sol
  └── Staking_Invariants.t.sol
script/
  └── Deploy.s.sol
lib/
  └── openzeppelin-contracts/
```

---

## How It Works

1. **Deploy `RewardToken` contract.**
2. **Deploy `StakingContract`, passing the `RewardToken` address.**
3. **Transfer ownership of `RewardToken` to `StakingContract`.**
4. **Users stake ETH via `stake()`.**
5. **After the lock period, users call `unstake()` to withdraw ETH and claim rewards.**

---

## Reward Calculation

- **Formula:**  
  ```
  rewards = (staked ETH) * REWARD_RATE * (duration staked in seconds) / 60
  ```
  - `REWARD_RATE` is set to `1` (1 RWD per ETH per minute) for testing.
  - The lock period is set to `2 minutes` for quick testing.

---

## Deployment

You can deploy the contracts using Foundry's scripting system:

```bash
forge script script/Deploy.s.sol --broadcast --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY>
```

---

## Testing

Run the full test suite with:

```bash
forge test
```

- Includes unit tests, fuzz tests, and invariant tests.
- Tests cover staking, unstaking, reward calculation, and edge cases.

---

## Security Notes

- **Reentrancy:** All external calls are protected with `nonReentrant`.
- **Ownership:** Only the staking contract can mint reward tokens.
- **Lock Period:** Users cannot unstake before the lock period ends; error message shows remaining time.

---

## Customization

- **Change Lock Time:** Edit `LOCK_TIME` in `StakingContract.sol`.
- **Change Reward Rate:** Edit `REWARD_RATE` in `StakingContract.sol`.

---

## License

MIT

---

## Acknowledgements

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Foundry](https://github.com/foundry-rs/foundry)