import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { useQuery } from '@tanstack/react-query';
import { CONTRACTS } from '../contracts';
import { Address, formatUnits, parseUnits } from 'viem';

export function useCollateralBalance(userAddress?: Address) {
  return useReadContract({
    address: CONTRACTS.CollateralManager.address,
    abi: CONTRACTS.CollateralManager.abi,
    functionName: 'getTotalCollateralValue',
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress,
    },
  });
}

export function useUserDebt(userAddress?: Address) {
  return useReadContract({
    address: CONTRACTS.CollateralManager.address,
    abi: CONTRACTS.CollateralManager.abi,
    functionName: 'userDebt',
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress,
    },
  });
}

export function useHealthFactor(userAddress?: Address) {
  return useReadContract({
    address: CONTRACTS.CollateralManager.address,
    abi: CONTRACTS.CollateralManager.abi,
    functionName: 'getHealthFactor',
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress,
    },
  });
}

export function useIsLiquidatable(userAddress?: Address) {
  return useReadContract({
    address: CONTRACTS.CollateralManager.address,
    abi: CONTRACTS.CollateralManager.abi,
    functionName: 'isLiquidatable',
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress,
    },
  });
}

export function useSupportedVaults() {
  return useReadContract({
    address: CONTRACTS.CollateralManager.address,
    abi: CONTRACTS.CollateralManager.abi,
    functionName: 'supportedVaults',
    args: [],
  });
}

export function useDepositCollateral() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const deposit = (vaultAddress: Address, shares: bigint) => {
    writeContract({
      address: CONTRACTS.CollateralManager.address,
      abi: CONTRACTS.CollateralManager.abi,
      functionName: 'depositCollateral',
      args: [vaultAddress, shares],
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

export function useWithdrawCollateral() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const withdraw = (vaultAddress: Address, shares: bigint) => {
    writeContract({
      address: CONTRACTS.CollateralManager.address,
      abi: CONTRACTS.CollateralManager.abi,
      functionName: 'withdrawCollateral',
      args: [vaultAddress, shares],
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

export function useRepayDebt() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const repay = (amount: bigint) => {
    writeContract({
      address: CONTRACTS.CollateralManager.address,
      abi: CONTRACTS.CollateralManager.abi,
      functionName: 'repayDebt',
      args: [amount],
    });
  };

  return {
    repay,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

export function useLiquidate() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const liquidate = (userAddress: Address, vaultAddress: Address, debtToRepay: bigint) => {
    writeContract({
      address: CONTRACTS.CollateralManager.address,
      abi: CONTRACTS.CollateralManager.abi,
      functionName: 'liquidate',
      args: [userAddress, vaultAddress, debtToRepay],
    });
  };

  return {
    liquidate,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

