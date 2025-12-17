'use client';

import { useAccount } from 'wagmi';
import { useCollateralBalance, useUserDebt, useHealthFactor, useIsLiquidatable } from '../lib/hooks/useCollateral';
import { useStablecoinBalance } from '../lib/hooks/useStablecoin';
import { formatUnits } from 'viem';

export function PositionOverview() {
  const { address } = useAccount();
  const { data: collateral } = useCollateralBalance(address);
  const { data: debt } = useUserDebt(address);
  const { data: healthFactor } = useHealthFactor(address);
  const { data: isLiquidatable } = useIsLiquidatable(address);
  const { data: stablecoinBalance } = useStablecoinBalance(address);

  if (!address) {
    return (
      <div className="p-6 bg-white rounded-lg shadow-md">
        <p className="text-gray-500">Please connect your wallet to view your position</p>
      </div>
    );
  }

  return (
    <div className="p-6 bg-white rounded-lg shadow-md">
      <h2 className="text-2xl font-bold mb-4">Your Position</h2>
      
      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div className="p-4 bg-blue-50 rounded">
            <p className="text-sm text-gray-600">Collateral Value</p>
            <p className="text-2xl font-bold">
              {collateral ? formatUnits(collateral, 18) : '0.0'}
            </p>
          </div>

          <div className="p-4 bg-red-50 rounded">
            <p className="text-sm text-gray-600">Debt</p>
            <p className="text-2xl font-bold">
              {debt ? formatUnits(debt, 18) : '0.0'} STABLE
            </p>
          </div>

          <div className="p-4 bg-green-50 rounded">
            <p className="text-sm text-gray-600">STABLE Balance</p>
            <p className="text-2xl font-bold">
              {stablecoinBalance ? formatUnits(stablecoinBalance, 18) : '0.0'} STABLE
            </p>
          </div>

          <div className={`p-4 rounded ${isLiquidatable ? 'bg-red-100' : 'bg-gray-50'}`}>
            <p className="text-sm text-gray-600">Health Factor</p>
            <p className="text-2xl font-bold">
              {healthFactor ? (Number(healthFactor) / 10000).toFixed(2) : 'N/A'}%
            </p>
            {isLiquidatable && (
              <p className="text-red-600 text-sm mt-1">⚠️ Position is liquidatable</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

