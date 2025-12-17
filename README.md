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
- **CollateralManager**: Manages collateral deposits and stablecoin minting
- **Governor**: Governance contract for protocol parameter changes

### Commands

```bash
cd contracts
forge build          # Build contracts
forge test           # Run tests
forge test --fuzz-runs 1000  # Run tests with fuzzing
forge script script/Deploy.s.sol:DeployScript  # Deploy contracts
```

## Frontend UI

The ui directory contains a Next.js application for interacting with the protocol.

### Features

- Wallet connection via RainbowKit
- View position (collateral, debt, health factor)
- Deposit collateral and mint stablecoin
- Repay debt
- All queries use React Query
- Blockchain operations use Viem

### Setup

1. Install dependencies:

```bash
cd ui
npm install
```

2. Copy environment variables:

```bash
cp .env.example .env.local
```

3. Set contract addresses in `.env.local`:

```
NEXT_PUBLIC_STABLECOIN_ADDRESS=0x...
NEXT_PUBLIC_COLLATERAL_MANAGER_ADDRESS=0x...
NEXT_PUBLIC_GOVERNOR_ADDRESS=0x...
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
```

4. Run development server:

```bash
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
