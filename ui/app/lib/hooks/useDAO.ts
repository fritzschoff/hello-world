"use client";

import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { useAccount } from "wagmi";
import { Address, formatEther, parseEther } from "viem";
import { CONTRACTS } from "../contracts";

const DAO_ABI = [
  {
    inputs: [],
    name: "daoBalance",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "user", type: "address" }],
    name: "getBalance",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "deposit",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "withdraw",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

export function useDAOBalance(daoAddress: Address) {
  return useReadContract({
    address: daoAddress,
    abi: DAO_ABI,
    functionName: "daoBalance",
    query: {
      refetchInterval: 2000,
    },
  });
}

export function useUserBalance(daoAddress: Address, userAddress?: Address) {
  return useReadContract({
    address: daoAddress,
    abi: DAO_ABI,
    functionName: "getBalance",
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress,
      refetchInterval: 2000,
    },
  });
}

export function useDeposit(daoAddress: Address) {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const deposit = (amount: bigint) => {
    writeContract({
      address: daoAddress,
      abi: DAO_ABI,
      functionName: "deposit",
      value: amount,
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

export function useWithdraw(daoAddress: Address) {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const withdraw = () => {
    writeContract({
      address: daoAddress,
      abi: DAO_ABI,
      functionName: "withdraw",
    });
  };

  return {
    withdraw,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

