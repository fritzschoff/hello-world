## Project Overview

This project implements a collateralized stablecoin system using ERC4626 vault shares as collateral. Users can deposit vault shares and automatically receive stablecoin based on a 150% collateralization ratio.

### Contracts

- **Stablecoin**: Upgradeable ERC20 stablecoin token
- **CollateralManager**: Manages collateral deposits and stablecoin minting
- **Vault**: ERC4626 vault for asset management
- **Treasury**: Holds protocol fees collected from minting operations

All contracts use the UUPS (Universal Upgradeable Proxy Standard) pattern for upgradeability.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

#### Deploy All Contracts

Deploy all contracts (Stablecoin, Treasury, CollateralManager, Governor) using UUPS proxy pattern:

```shell
$ forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --broadcast --private-key <your_private_key>
```

The script will:
- Deploy implementation contracts
- Deploy ERC1967Proxy for each contract
- Initialize each proxy
- Set CollateralManager as minter for Stablecoin
- Output all contract addresses

**Important**: Use the proxy addresses (not implementation addresses) for interactions.

#### Add Supported Vault

Add an ERC4626 vault to the CollateralManager:

```shell
$ export COLLATERAL_MANAGER_ADDRESS=0x...
$ export VAULT_ADDRESS=0x...
$ forge script script/AddVault.s.sol:AddVaultScript --rpc-url <your_rpc_url> --broadcast --private-key <your_private_key>
```

#### Deploy Counter (Example)

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
