# Stablecoin Protocol

A collateralized stablecoin system using ERC4626 vault shares as collateral. Users can deposit vault shares and automatically receive stablecoin based on a configurable collateralization ratio.

## Contracts

### Key Contracts

- **Stablecoin**: ERC20 governance token with voting capabilities
- **CollateralManager**: Manages collateral deposits and stablecoin minting with configurable fees
- **Governor**: Governance contract for protocol parameter changes
- **Treasury**: Holds protocol fees collected from minting operations

All contracts use the UUPS (Universal Upgradeable Proxy Standard) pattern for upgradeability.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
npm run build
# or
forge build
```

### Test

```shell
npm run test
# or
forge test
```

### Fuzz Testing

```shell
npm run test:fuzz
# or
forge test --fuzz-runs 1000
```

### Format

```shell
npm run format
# or
forge fmt
```

### Format Check

```shell
npm run format:check
# or
forge fmt --check
```

### Gas Snapshots

```shell
forge snapshot
```

### Anvil (Local Blockchain)

```shell
npm run anvil
# or
anvil
```

### Deploy

#### Deploy All Contracts

Deploy all contracts (Stablecoin, Treasury, CollateralManager, Governor) using UUPS proxy pattern:

```shell
npm run deploy:local
# or
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

For other networks:

```shell
forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --broadcast --private-key <your_private_key>
```

The script will:

- Deploy implementation contracts
- Deploy ERC1967Proxy for each contract
- Initialize each proxy
- Set CollateralManager as minter for Stablecoin
- Transfer ownership to Governor
- Output all contract addresses

**Important**: Use the proxy addresses (not implementation addresses) for interactions.

#### Add Supported Vault

Add an ERC4626 vault to the CollateralManager:

```shell
export COLLATERAL_MANAGER_ADDRESS=0x...
export VAULT_ADDRESS=0x...
forge script script/AddVault.s.sol:AddVaultScript --rpc-url <your_rpc_url> --broadcast --private-key <your_private_key>
```

### Cast

```shell
cast <subcommand>
```

### Help

```shell
forge --help
anvil --help
cast --help
```

## Pre-commit Hooks

This repository uses Husky to run pre-commit hooks that:

- Format Solidity contracts with `forge fmt`

The hooks run automatically on `git commit`. To manually run:

```bash
npm run format
```

## ERC-4626 Inflation Attack Demo

This repository includes a demonstration of the ERC-4626 inflation attack vulnerability, as described in the [MixBytes article](https://mixbytes.io/blog/overview-of-the-inflation-attack).

### Attack Overview

The inflation attack exploits rounding issues in ERC-4626 vaults. Attackers can manipulate the share calculation formula to make victims receive zero or minimal shares, allowing them to steal deposits.

**Attack Formula:**

```
shares = totalSupply × assets / totalAssets
```

### Running the Demo

1. **Start Anvil (local blockchain):**

```bash
npm run anvil
```

2. **Deploy the demo contracts:**

```bash
npm run deploy:attack-demo
```

3. **Set environment variables in `ui/.env.local`:**

```env
NEXT_PUBLIC_ASSET_ADDRESS=0x...
NEXT_PUBLIC_VAULT_ADDRESS=0x...
NEXT_PUBLIC_ATTACKER_ADDRESS=0x...
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
```

4. **Start the UI:**

```bash
cd ui
npm install
npm run dev
```

5. **Run the attack tests:**

```bash
forge test --match-contract InflationAttackTest -vv
```

### Attack Steps

1. **Mint Initial Share**: Attacker deposits 1 wei to mint the first share
2. **Inflate Denominator**: Attacker transfers assets directly to vault, manipulating the formula
3. **Victim Deposits**: Victim receives zero or minimal shares due to rounding
4. **Attacker Steals**: Attacker redeems their share and receives almost all assets

### Files

- `src/VulnerableVault.sol` - Vulnerable ERC-4626 implementation
- `src/Attacker.sol` - Attack contract demonstrating the exploit
- `test/InflationAttack.t.sol` - Test cases showing the attack
- `ui/` - React UI for visualizing the attack

## Reentrancy Attack Demo (The DAO Hack)

This repository also includes a demonstration of the reentrancy attack that led to the Ethereum hard fork in 2016, as described in the [Chainlink article](https://blog.chain.link/reentrancy-attacks-and-the-dao-hack/).

### Attack Overview

The reentrancy attack exploits the order of operations in smart contracts. When a contract sends ETH before updating state, an attacker can re-enter the function and drain funds.

**The Vulnerability:**

```solidity
function withdraw() public {
    uint256 bal = balances[msg.sender];
    (bool sent, ) = msg.sender.call{value: bal}(""); // Send ETH first
    balances[msg.sender] = 0; // Update balance after - TOO LATE!
}
```

### Running the Demo

1. **Start Anvil (local blockchain):**

```bash
npm run anvil
```

2. **Deploy the demo contracts:**

```bash
npm run deploy:reentrancy-demo
```

3. **Set environment variables in `ui/.env.local`:**

```env
NEXT_PUBLIC_VULNERABLE_DAO_ADDRESS=0x...
NEXT_PUBLIC_SECURE_DAO_ADDRESS=0x...
NEXT_PUBLIC_ATTACKER_ADDRESS=0x...
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
```

4. **Start the UI:**

```bash
cd ui
npm run dev
```

5. **Run the attack tests:**

```bash
forge test --match-contract ReentrancyAttackTest -vv
```

### Attack Steps

1. **Attacker Deposits**: Attacker deposits 1 ETH to the vulnerable DAO
2. **Attacker Withdraws**: Calls `withdraw()` function
3. **DAO Sends ETH**: Vulnerable DAO sends ETH to attacker before updating balance
4. **Reentrancy**: Attacker's `receive()` function calls `withdraw()` again
5. **Repeat**: Process repeats until DAO is drained
6. **Balance Updated**: Only after all reentrancy calls complete does the balance get set to 0

### Files

- `src/VulnerableDAO.sol` - Vulnerable contract with reentrancy flaw
- `src/SecureDAO.sol` - Fixed version with reentrancy guard
- `src/ReentrancyAttacker.sol` - Attack contract demonstrating the exploit
- `test/ReentrancyAttack.t.sol` - Test cases showing the attack
- `ui/app/components/ReentrancyVisualization.tsx` - React UI for visualizing the attack

### Historical Context

The DAO hack in 2016:

- Drained $150M worth of ETH from The DAO
- Led to a hard fork of Ethereum
- Created Ethereum (current chain) and Ethereum Classic (original chain)
- 85% of the community voted for the fork to recover funds

## License

MIT
