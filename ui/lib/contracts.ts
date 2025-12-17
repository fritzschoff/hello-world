import { Address } from 'viem';
import StablecoinABI from './abis/Stablecoin.json';
import CollateralManagerABI from './abis/CollateralManager.json';
import GovernorABI from './abis/Governor.json';

export const CONTRACTS = {
  Stablecoin: {
    address: process.env.NEXT_PUBLIC_STABLECOIN_ADDRESS as Address,
    abi: StablecoinABI,
  },
  CollateralManager: {
    address: process.env.NEXT_PUBLIC_COLLATERAL_MANAGER_ADDRESS as Address,
    abi: CollateralManagerABI,
  },
  Governor: {
    address: process.env.NEXT_PUBLIC_GOVERNOR_ADDRESS as Address,
    abi: GovernorABI,
  },
} as const;

