'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import {
  useProposalThreshold,
  useVotingDelay,
  useVotingPeriod,
  useQuorum,
  useCreateProposal,
  useCastVote,
} from '../lib/hooks/useGovernance';
import { useStablecoinBalance } from '../lib/hooks/useStablecoin';
import { formatUnits } from 'viem';
import { CONTRACTS } from '../lib/contracts';
import { Address } from 'viem';

export function Governance() {
  const { address } = useAccount();
  const { data: threshold } = useProposalThreshold();
  const { data: votingDelay } = useVotingDelay();
  const { data: votingPeriod } = useVotingPeriod();
  const { data: quorum } = useQuorum();
  const { data: balance } = useStablecoinBalance(address);
  const { createProposal, isPending: isCreating, isSuccess: isCreated } = useCreateProposal();
  const { castVote, isPending: isVoting } = useCastVote();

  const [isExpanded, setIsExpanded] = useState(false);
  const [proposalDescription, setProposalDescription] = useState('');
  const [proposalTarget, setProposalTarget] = useState('');
  const [proposalCalldata, setProposalCalldata] = useState('');
  const [proposalId, setProposalId] = useState('');
  const [voteSupport, setVoteSupport] = useState<0 | 1 | 2>(1);

  if (!address) {
    return null;
  }

  const canPropose = threshold && balance && balance >= threshold;

  const handleCreateProposal = () => {
    if (!proposalTarget || !proposalCalldata || !proposalDescription) return;

    const targets: Address[] = [proposalTarget as Address];
    const values: bigint[] = [BigInt(0)];
    const calldatas: `0x${string}`[] = [proposalCalldata as `0x${string}`];

    createProposal(targets, values, calldatas, proposalDescription);
  };

  const handleCastVote = () => {
    if (!proposalId) return;
    castVote(BigInt(proposalId), voteSupport);
  };

  return (
    <div className="p-6 bg-white rounded-lg shadow-md">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold">Governance</h2>
        <button
          onClick={() => setIsExpanded(!isExpanded)}
          className="text-blue-600 hover:text-blue-800"
        >
          {isExpanded ? '−' : '+'}
        </button>
      </div>

      <div className="space-y-3 mb-4">
        <div className="text-sm">
          <span className="font-medium">Proposal Threshold: </span>
          {threshold ? formatUnits(threshold, 18) : '...'} STABLE
        </div>
        <div className="text-sm">
          <span className="font-medium">Voting Delay: </span>
          {votingDelay ? `${Number(votingDelay)} blocks` : '...'}
        </div>
        <div className="text-sm">
          <span className="font-medium">Voting Period: </span>
          {votingPeriod ? `${Number(votingPeriod)} blocks` : '...'}
        </div>
        <div className="text-sm">
          <span className="font-medium">Quorum: </span>
          {quorum ? `${Number(quorum)}%` : '...'}
        </div>
        <div className="text-sm">
          <span className="font-medium">Your Balance: </span>
          {balance ? formatUnits(balance, 18) : '...'} STABLE
        </div>
        {canPropose === false && (
          <p className="text-red-600 text-sm">
            You need at least {threshold ? formatUnits(threshold, 18) : '...'} STABLE to create a proposal
          </p>
        )}
      </div>

      {isExpanded && (
        <div className="space-y-4 border-t pt-4">
          <div>
            <h3 className="font-medium mb-2">Create Proposal</h3>
            <input
              type="text"
              placeholder="Target Address"
              value={proposalTarget}
              onChange={(e) => setProposalTarget(e.target.value)}
              className="w-full p-2 border rounded mb-2"
            />
            <input
              type="text"
              placeholder="Calldata (0x...)"
              value={proposalCalldata}
              onChange={(e) => setProposalCalldata(e.target.value)}
              className="w-full p-2 border rounded mb-2"
            />
            <textarea
              placeholder="Description"
              value={proposalDescription}
              onChange={(e) => setProposalDescription(e.target.value)}
              className="w-full p-2 border rounded mb-2"
              rows={3}
            />
            <button
              onClick={handleCreateProposal}
              disabled={isCreating || !canPropose}
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isCreating ? 'Creating...' : 'Create Proposal'}
            </button>
            {isCreated && (
              <p className="text-green-600 text-sm mt-2">Proposal created successfully!</p>
            )}
          </div>

          <div className="border-t pt-4">
            <h3 className="font-medium mb-2">Cast Vote</h3>
            <input
              type="text"
              placeholder="Proposal ID"
              value={proposalId}
              onChange={(e) => setProposalId(e.target.value)}
              className="w-full p-2 border rounded mb-2"
            />
            <select
              value={voteSupport}
              onChange={(e) => setVoteSupport(Number(e.target.value) as 0 | 1 | 2)}
              className="w-full p-2 border rounded mb-2"
            >
              <option value={0}>Against</option>
              <option value={1}>For</option>
              <option value={2}>Abstain</option>
            </select>
            <button
              onClick={handleCastVote}
              disabled={isVoting || !proposalId}
              className="w-full bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isVoting ? 'Voting...' : 'Cast Vote'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

