"use client";

import { useState } from "react";
import { useAccount } from "wagmi";
import { useMintMoreStablecoin } from "../lib/hooks/useCollateral";

export function MintMoreStablecoin() {
  const { address } = useAccount();
  const { mintMore, isPending, isSuccess } = useMintMoreStablecoin();
  const [isExpanded, setIsExpanded] = useState(false);

  if (!address) {
    return null;
  }

  const handleMintMore = () => {
    mintMore();
  };

  return (
    <div className="p-6 bg-white rounded-lg shadow-md">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold">Mint More Stablecoin</h2>
        <button
          onClick={() => setIsExpanded(!isExpanded)}
          className="text-blue-600 hover:text-blue-800"
        >
          {isExpanded ? "−" : "+"}
        </button>
      </div>

      {isExpanded && (
        <div className="space-y-4">
          <p className="text-sm text-gray-600">
            Mint additional stablecoin based on your excess collateral. A
            minting fee will be applied.
          </p>

          <button
            onClick={handleMintMore}
            disabled={isPending}
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isPending ? "Minting..." : "Mint More Stablecoin"}
          </button>

          {isSuccess && (
            <p className="text-green-600 text-sm">
              Successfully minted more stablecoin!
            </p>
          )}
        </div>
      )}
    </div>
  );
}
