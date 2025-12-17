# Stablecoin Protocol Monorepo

A monorepo containing the Stablecoin Protocol smart contracts and Next.js frontend application.

## Structure

```
hello-world/
├── contracts/          # Solidity smart contracts (Foundry)
├── ui/                # Next.js frontend application
└── package.json        # Root workspace configuration
```

## Contracts

The contracts directory contains all Solidity smart contracts, tests, and deployment scripts.

### Key Contracts

- **Stablecoin**: ERC20 governance token with voting capabilities
- **CollateralManager**: Manages collateral deposits and stablecoin minting with configurable fees
- **Governor**: Governance contract for protocol parameter changes
- **Treasury**: Holds protocol fees collected from minting operations

### Commands

```bash
cd contracts
forge build          # Build contracts
forge test           # Run tests
forge test --fuzz-runs 1000  # Run tests with fuzzing
forge script script/Deploy.s.sol:DeployScript  # Deploy contracts

# Local development
npm run anvil        # Start local blockchain (Anvil)
npm run deploy:local # Deploy contracts to local Anvil instance
```

## Frontend UI

The ui directory contains a Next.js application for interacting with the protocol.

### Features

- Wallet connection via RainbowKit
- View position (collateral, debt, health factor)
- Deposit collateral and mint stablecoin
- Mint more stablecoin on existing collateral
- Repay debt
- Governance: Create proposals, vote, and execute
- Treasury: View and withdraw protocol fees
- All queries use React Query
- Blockchain operations use Viem

### Setup

1. Install dependencies:

```bash
cd ui
npm install
```

2. Deploy contracts to local Anvil (if not already deployed):

```bash
cd contracts
npm run anvil  # In one terminal (keep it running)
npm run deploy:local  # In another terminal
```

3. Copy environment variables:

```bash
cd ui
cp .env.example .env.local
```

4. Get contract addresses from the deployment output. The proxy addresses are shown in the "Deployment Summary" section. For example:

```
Stablecoin (proxy): 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
CollateralManager (proxy): 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
Governor (proxy): 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6
```

5. Set contract addresses in `ui/.env.local`:

```
NEXT_PUBLIC_STABLECOIN_ADDRESS=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
NEXT_PUBLIC_COLLATERAL_MANAGER_ADDRESS=0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
NEXT_PUBLIC_GOVERNOR_ADDRESS=0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6
NEXT_PUBLIC_TREASURY_ADDRESS=0x...
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
```

**Note**: For localhost testing, WalletConnect project ID is optional. The localhost chain (Anvil, chain ID 31337) is already configured in the UI.

6. Run development server:

```bash
cd ui
npm run dev
```

### Tech Stack

- **Next.js 16**: React framework
- **Wagmi**: React hooks for Ethereum
- **RainbowKit**: Wallet connection UI
- **Viem**: TypeScript Ethereum library
- **React Query**: Data fetching and caching
- **Tailwind CSS**: Styling

## Development

### From Root

```bash
# Install all dependencies
npm install

# Run frontend
npm run dev

# Test contracts
npm run test:contracts

# Build contracts
npm run build:contracts

# Format contracts
npm run format:contracts

# Lint UI
npm run lint:ui
```

### Pre-commit Hooks

This repository uses Husky to run pre-commit hooks that:

- Format Solidity contracts with `forge fmt`
- Lint the UI with Next.js ESLint

The hooks run automatically on `git commit`. To manually run:

```bash
# Format all contracts
npm run format:contracts

# Lint UI
npm run lint:ui
```

## Deployment

### Contracts

Deploy contracts using the deployment script:

```bash
cd contracts
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY
```

### Frontend

Deploy to Vercel or your preferred hosting:

```bash
cd ui
npm run build
```

## License

MIT
