"use client";

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { Address, formatEther, parseEther } from "viem";
import { CONTRACTS } from "../contracts";

const ATTACKER_ABI = [
  {
    inputs: [],
    name: "attack",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "getBalance",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "attackCount",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "withdrawStolenFunds",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

export function useAttack() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const execute = (amount: bigint) => {
    writeContract({
      address: CONTRACTS.Attacker.address,
      abi: ATTACKER_ABI,
      functionName: "attack",
      value: amount,
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

export function useAttackerBalance() {
  return useReadContract({
    address: CONTRACTS.Attacker.address,
    abi: ATTACKER_ABI,
    functionName: "getBalance",
    query: {
      refetchInterval: 2000,
    },
  });
}

export function useAttackCount() {
  return useReadContract({
    address: CONTRACTS.Attacker.address,
    abi: ATTACKER_ABI,
    functionName: "attackCount",
    query: {
      refetchInterval: 2000,
    },
  });
}

export function useWithdrawStolenFunds() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const execute = () => {
    writeContract({
      address: CONTRACTS.Attacker.address,
      abi: ATTACKER_ABI,
      functionName: "withdrawStolenFunds",
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

