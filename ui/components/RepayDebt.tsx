'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import { useRepayDebt, useUserDebt } from '../lib/hooks/useCollateral';
import { parseUnits, formatUnits } from 'viem';

export function RepayDebt() {
  const { address } = useAccount();
  const [amount, setAmount] = useState('');
  const { data: debt } = useUserDebt(address);
  const { repay, isPending, isSuccess } = useRepayDebt();

  const handleRepay = () => {
    if (!amount) return;
    const amountBigInt = parseUnits(amount, 18);
    repay(amountBigInt);
  };

  return (
    <div className="p-6 bg-white rounded-lg shadow-md">
      <h2 className="text-2xl font-bold mb-4">Repay Debt</h2>
      
      <div className="space-y-4">
        {debt && (
          <div className="p-3 bg-gray-100 rounded">
            <p className="text-sm text-gray-600">Current Debt</p>
            <p className="text-lg font-semibold">{formatUnits(debt, 18)} STABLE</p>
          </div>
        )}

        <div>
          <label className="block text-sm font-medium mb-2">Amount to Repay</label>
          <input
            type="text"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.0"
            className="w-full p-2 border rounded"
          />
        </div>

        <button
          onClick={handleRepay}
          disabled={!amount || isPending}
          className="w-full bg-red-600 text-white py-2 px-4 rounded hover:bg-red-700 disabled:opacity-50"
        >
          {isPending ? 'Repaying...' : 'Repay Debt'}
        </button>

        {isSuccess && (
          <p className="text-green-600">Debt repaid successfully!</p>
        )}
      </div>
    </div>
  );
}

