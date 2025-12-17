'use client';

import { ConnectWallet } from '../components/ConnectWallet';
import { PositionOverview } from '../components/PositionOverview';
import { DepositCollateral } from '../components/DepositCollateral';
import { RepayDebt } from '../components/RepayDebt';
import { MintMoreStablecoin } from '../components/MintMoreStablecoin';
import { Governance } from '../components/Governance';
import { Treasury } from '../components/Treasury';

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <h1 className="text-2xl font-bold">Stablecoin Protocol</h1>
            <ConnectWallet />
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <PositionOverview />
          <DepositCollateral />
          <MintMoreStablecoin />
          <RepayDebt />
          <Governance />
          <Treasury />
        </div>
      </main>
    </div>
  );
}
