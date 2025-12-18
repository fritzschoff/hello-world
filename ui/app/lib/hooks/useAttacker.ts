"use client";

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { Address, formatUnits, parseUnits } from "viem";
import { CONTRACTS } from "../contracts";

const ATTACKER_ABI = [
  {
    inputs: [],
    name: "attackStep1_MintInitialShare",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "amount", type: "uint256" }],
    name: "attackStep2_InflateDenominator",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "attackStep3_BurnAndSteal",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "getVaultBalance",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getVaultShares",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getMyShares",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getMyBalance",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
] as const;

const ERC20_ABI = [
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

// This function is no longer needed for reentrancy attack demo
// Keeping it for backward compatibility but it won't be used
export function useApproveForAttacker() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const approve = (_amount: bigint) => {
    // Not used in reentrancy attack - this is for ERC4626 attack demo
    // This function is kept for compatibility but should not be called
  };

  return {
    approve,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

export function useAttackStep1() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const execute = () => {
    writeContract({
      address: CONTRACTS.Attacker.address,
      abi: ATTACKER_ABI,
      functionName: "attackStep1_MintInitialShare",
      args: [],
    });
  };

  return {
    execute,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

export function useAttackStep2() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const execute = (amount: bigint) => {
    writeContract({
      address: CONTRACTS.Attacker.address,
      abi: ATTACKER_ABI,
      functionName: "attackStep2_InflateDenominator",
      args: [amount],
    });
  };

  return {
    execute,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

export function useAttackStep3() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const execute = () => {
    writeContract({
      address: CONTRACTS.Attacker.address,
      abi: ATTACKER_ABI,
      functionName: "attackStep3_BurnAndSteal",
      args: [],
    });
  };

  return {
    execute,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

export function useAttackerStats() {
  const vaultBalance = useReadContract({
    address: CONTRACTS.Attacker.address,
    abi: ATTACKER_ABI,
    functionName: "getVaultBalance",
    query: {
      refetchInterval: 2000,
    },
  });

  const vaultShares = useReadContract({
    address: CONTRACTS.Attacker.address,
    abi: ATTACKER_ABI,
    functionName: "getVaultShares",
    query: {
      refetchInterval: 2000,
    },
  });

  const myShares = useReadContract({
    address: CONTRACTS.Attacker.address,
    abi: ATTACKER_ABI,
    functionName: "getMyShares",
    query: {
      refetchInterval: 2000,
    },
  });

  const myBalance = useReadContract({
    address: CONTRACTS.Attacker.address,
    abi: ATTACKER_ABI,
    functionName: "getMyBalance",
    query: {
      refetchInterval: 2000,
    },
  });

  return {
    vaultBalance,
    vaultShares,
    myShares,
    myBalance,
  };
}

