import { Address } from "viem";

// These addresses should be set in .env.local after deploying
// Run: npm run deploy:reentrancy-demo
export const CONTRACTS = {
  VulnerableDAO: {
    address: (process.env.NEXT_PUBLIC_VULNERABLE_DAO_ADDRESS || "0x0000000000000000000000000000000000000000") as Address,
  },
  SecureDAO: {
    address: (process.env.NEXT_PUBLIC_SECURE_DAO_ADDRESS || "0x0000000000000000000000000000000000000000") as Address,
  },
  Attacker: {
    address: (process.env.NEXT_PUBLIC_ATTACKER_ADDRESS || "0x0000000000000000000000000000000000000000") as Address,
  },
} as const;

