'use client';

import { useAccount } from 'wagmi';
import { useTreasuryBalance, useWithdrawTreasury } from '../lib/hooks/useTreasury';
import { formatUnits } from 'viem';
import { CONTRACTS } from '../lib/contracts';
import { Address, parseUnits } from 'viem';
import { useState } from 'react';

export function Treasury() {
  const { address } = useAccount();
  const { data: stablecoinBalance } = useTreasuryBalance(CONTRACTS.Stablecoin.address);
  const { withdraw, withdrawAll, isPending, isSuccess } = useWithdrawTreasury();
  const [withdrawAmount, setWithdrawAmount] = useState('');
  const [recipient, setRecipient] = useState('');

  if (!address) {
    return null;
  }

  const handleWithdraw = () => {
    if (!withdrawAmount || !recipient || !CONTRACTS.Stablecoin.address) return;
    const amount = parseUnits(withdrawAmount, 18);
    withdraw(CONTRACTS.Stablecoin.address, amount, recipient as Address);
  };

  const handleWithdrawAll = () => {
    if (!recipient || !CONTRACTS.Stablecoin.address) return;
    withdrawAll(CONTRACTS.Stablecoin.address, recipient as Address);
  };

  return (
    <div className="p-6 bg-white rounded-lg shadow-md">
      <h2 className="text-xl font-semibold mb-4">Treasury</h2>

      <div className="space-y-4">
        <div>
          <div className="text-sm text-gray-600 mb-1">Stablecoin Balance</div>
          <div className="text-2xl font-bold">
            {stablecoinBalance ? formatUnits(stablecoinBalance, 18) : '...'} STABLE
          </div>
        </div>

        <div className="border-t pt-4">
          <h3 className="font-medium mb-2">Withdraw Funds</h3>
          <input
            type="text"
            placeholder="Recipient Address"
            value={recipient}
            onChange={(e) => setRecipient(e.target.value)}
            className="w-full p-2 border rounded mb-2"
          />
          <input
            type="text"
            placeholder="Amount (leave empty for all)"
            value={withdrawAmount}
            onChange={(e) => setWithdrawAmount(e.target.value)}
            className="w-full p-2 border rounded mb-2"
          />
          <div className="flex gap-2">
            <button
              onClick={handleWithdraw}
              disabled={isPending || !withdrawAmount || !recipient}
              className="flex-1 bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending ? 'Withdrawing...' : 'Withdraw'}
            </button>
            <button
              onClick={handleWithdrawAll}
              disabled={isPending || !recipient}
              className="flex-1 bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending ? 'Withdrawing...' : 'Withdraw All'}
            </button>
          </div>
          {isSuccess && (
            <p className="text-green-600 text-sm mt-2">Withdrawal successful!</p>
          )}
        </div>
      </div>
    </div>
  );
}

