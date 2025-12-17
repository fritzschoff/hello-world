import { useReadContract, useWriteContract, useWaitForTransactionReceipt, useAccount } from 'wagmi';
import { useQuery } from '@tanstack/react-query';
import { CONTRACTS } from '../contracts';
import { Address } from 'viem';

export function useProposalThreshold() {
  return useReadContract({
    address: CONTRACTS.Governor.address,
    abi: CONTRACTS.Governor.abi,
    functionName: 'proposalThreshold',
  });
}

export function useVotingDelay() {
  return useReadContract({
    address: CONTRACTS.Governor.address,
    abi: CONTRACTS.Governor.abi,
    functionName: 'votingDelay',
  });
}

export function useVotingPeriod() {
  return useReadContract({
    address: CONTRACTS.Governor.address,
    abi: CONTRACTS.Governor.abi,
    functionName: 'votingPeriod',
  });
}

export function useQuorum() {
  return useReadContract({
    address: CONTRACTS.Governor.address,
    abi: CONTRACTS.Governor.abi,
    functionName: 'quorum',
    args: [BigInt(0)],
  });
}

export function useProposal(proposalId?: bigint) {
  return useReadContract({
    address: CONTRACTS.Governor.address,
    abi: CONTRACTS.Governor.abi,
    functionName: 'proposalVotes',
    args: proposalId !== undefined ? [proposalId] : undefined,
    query: {
      enabled: proposalId !== undefined,
    },
  });
}

export function useProposalState(proposalId?: bigint) {
  return useReadContract({
    address: CONTRACTS.Governor.address,
    abi: CONTRACTS.Governor.abi,
    functionName: 'state',
    args: proposalId !== undefined ? [proposalId] : undefined,
    query: {
      enabled: proposalId !== undefined,
    },
  });
}

export function useCreateProposal() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const createProposal = (
    targets: Address[],
    values: bigint[],
    calldatas: `0x${string}`[],
    description: string
  ) => {
    writeContract({
      address: CONTRACTS.Governor.address,
      abi: CONTRACTS.Governor.abi,
      functionName: 'propose',
      args: [targets, values, calldatas, description],
    });
  };

  return {
    createProposal,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

export function useCastVote() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const castVote = (proposalId: bigint, support: 0 | 1 | 2) => {
    writeContract({
      address: CONTRACTS.Governor.address,
      abi: CONTRACTS.Governor.abi,
      functionName: 'castVote',
      args: [proposalId, support],
    });
  };

  return {
    castVote,
    hash,
    isPending,
    isConfirming,
    isSuccess,
  };
}

export function useExecuteProposal() {
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const execute = (
    targets: Address[],
    values: bigint[],
    calldatas: `0x${string}`[],
    descriptionHash: `0x${string}`
  ) => {
    writeContract({
      address: CONTRACTS.Governor.address,
      abi: CONTRACTS.Governor.abi,
      functionName: 'execute',
      args: [targets, values, calldatas, descriptionHash],
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

