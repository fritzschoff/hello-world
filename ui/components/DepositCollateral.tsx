'use client';

import { useState } from 'react';
import { useAccount, useReadContract } from 'wagmi';
import { useDepositCollateral, useSupportedVaults } from '../lib/hooks/useCollateral';
import { Address, parseUnits } from 'viem';
import { CONTRACTS } from '../lib/contracts';

export function DepositCollateral() {
  const { address } = useAccount();
  const [selectedVault, setSelectedVault] = useState<Address | ''>('');
  const [shares, setShares] = useState('');
  const { data: vaults } = useSupportedVaults();
  const { deposit, isPending, isSuccess } = useDepositCollateral();

  const handleDeposit = async () => {
    if (!selectedVault || !shares || !address) return;
    
    const sharesBigInt = parseUnits(shares, 18);
    deposit(selectedVault as Address, sharesBigInt);
  };

  return (
    <div className="p-6 bg-white rounded-lg shadow-md">
      <h2 className="text-2xl font-bold mb-4">Deposit Collateral</h2>
      
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-2">Select Vault</label>
          <select
            value={selectedVault}
            onChange={(e) => setSelectedVault(e.target.value as Address)}
            className="w-full p-2 border rounded"
          >
            <option value="">Select a vault</option>
            {vaults && Array.isArray(vaults) && vaults.map((vault: Address, idx: number) => (
              <option key={idx} value={vault}>
                {vault}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">Shares Amount</label>
          <input
            type="text"
            value={shares}
            onChange={(e) => setShares(e.target.value)}
            placeholder="0.0"
            className="w-full p-2 border rounded"
          />
        </div>

        <button
          onClick={handleDeposit}
          disabled={!selectedVault || !shares || isPending}
          className="w-full bg-blue-600 text-white py-2 px-4 rounded hover:bg-blue-700 disabled:opacity-50"
        >
          {isPending ? 'Depositing...' : 'Deposit Collateral'}
        </button>

        {isSuccess && (
          <p className="text-green-600">Deposit successful!</p>
        )}
      </div>
    </div>
  );
}

