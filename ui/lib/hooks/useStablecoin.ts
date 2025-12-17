import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { CONTRACTS } from '../contracts';
import { Address, formatUnits, parseUnits } from 'viem';

export function useStablecoinBalance(userAddress?: Address) {
  return useReadContract({
    address: CONTRACTS.Stablecoin.address,
    abi: CONTRACTS.Stablecoin.abi,
    functionName: 'balanceOf',
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress,
    },
  });
}

export function useStablecoinTotalSupply() {
  return useReadContract({
    address: CONTRACTS.Stablecoin.address,
    abi: CONTRACTS.Stablecoin.abi,
    functionName: 'totalSupply',
    args: [],
  });
}

export function useApproveStablecoin() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const approve = (spender: Address, amount: bigint) => {
    writeContract({
      address: CONTRACTS.Stablecoin.address,
      abi: CONTRACTS.Stablecoin.abi,
      functionName: 'approve',
      args: [spender, amount],
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

