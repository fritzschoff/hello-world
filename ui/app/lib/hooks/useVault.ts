"use client";

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { useAccount } from "wagmi";
import { Address, formatUnits, parseUnits } from "viem";
import { CONTRACTS } from "../contracts";

const VAULT_ABI = [
  {
    inputs: [],
    name: "totalAssets",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "assets", type: "uint256" }],
    name: "convertToShares",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "shares", type: "uint256" }],
    name: "convertToAssets",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "assets", type: "uint256" },
      { name: "receiver", type: "address" },
    ],
    name: "deposit",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "owner", type: "address" }],
    name: "balanceOf",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
] as const;

const ERC20_ABI = [
  {
    inputs: [{ name: "account", type: "address" }],
    name: "balanceOf",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    name: "approve",
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

// These functions are for ERC4626 attack demo - not used in reentrancy demo
// Keeping for backward compatibility
export function useVaultTotalAssets() {
  return useReadContract({
    address: "0x0000000000000000000000000000000000000000" as Address,
    abi: VAULT_ABI,
    functionName: "totalAssets",
    query: {
      refetchInterval: 2000,
    },
  });
}

export function useVaultTotalSupply() {
  return useReadContract({
    address: "0x0000000000000000000000000000000000000000" as Address,
    abi: VAULT_ABI,
    functionName: "totalSupply",
    query: {
      refetchInterval: 2000,
    },
  });
}

export function useVaultBalance(userAddress?: Address) {
  return useReadContract({
    address: "0x0000000000000000000000000000000000000000" as Address,
    abi: VAULT_ABI,
    functionName: "balanceOf",
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress,
      refetchInterval: 2000,
    },
  });
}

export function useAssetBalance(userAddress?: Address) {
  return useReadContract({
    address: "0x0000000000000000000000000000000000000000" as Address,
    abi: ERC20_ABI,
    functionName: "balanceOf",
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress,
      refetchInterval: 2000,
    },
  });
}

export function useConvertToShares(assets: bigint) {
  return useReadContract({
    address: "0x0000000000000000000000000000000000000000" as Address,
    abi: VAULT_ABI,
    functionName: "convertToShares",
    args: [assets],
    query: {
      enabled: assets > 0n,
    },
  });
}

export function useDeposit() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const deposit = (assets: bigint, receiver: Address) => {
    writeContract({
      address: "0x0000000000000000000000000000000000000000" as Address,
      abi: VAULT_ABI,
      functionName: "deposit",
      args: [assets, receiver],
    });
  };

  return {
    deposit,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

export function useApproveAsset() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const approve = (amount: bigint) => {
    writeContract({
      address: "0x0000000000000000000000000000000000000000" as Address,
      abi: ERC20_ABI,
      functionName: "approve",
      args: ["0x0000000000000000000000000000000000000000" as Address, amount],
    });
  };

  return {
    approve,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

