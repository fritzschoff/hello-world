import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { CONTRACTS } from '../contracts';
import { Address, formatUnits } from 'viem';

export function useTreasuryBalance(tokenAddress?: Address) {
  return useReadContract({
    address: CONTRACTS.Treasury.address,
    abi: CONTRACTS.Treasury.abi,
    functionName: 'getBalance',
    args: tokenAddress ? [tokenAddress] : undefined,
    query: {
      enabled: !!tokenAddress && !!CONTRACTS.Treasury.address,
    },
  });
}

export function useWithdrawTreasury() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const withdraw = (tokenAddress: Address, amount: bigint, recipient: Address) => {
    writeContract({
      address: CONTRACTS.Treasury.address,
      abi: CONTRACTS.Treasury.abi,
      functionName: 'withdraw',
      args: [tokenAddress, amount, recipient],
    });
  };

  const withdrawAll = (tokenAddress: Address, recipient: Address) => {
    writeContract({
      address: CONTRACTS.Treasury.address,
      abi: CONTRACTS.Treasury.abi,
      functionName: 'withdrawAll',
      args: [tokenAddress, recipient],
    });
  };

  return {
    withdraw,
    withdrawAll,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

