"use client";

import { useState } from "react";
import { useAccount } from "wagmi";
import { formatUnits, parseUnits } from "viem";
import {
  useVaultTotalAssets,
  useVaultTotalSupply,
  useVaultBalance,
  useAssetBalance,
  useConvertToShares,
  useDeposit,
  useApproveAsset,
} from "../lib/hooks/useVault";
import {
  useAttackStep1,
  useAttackStep2,
  useAttackStep3,
  useAttackerStats,
  useApproveForAttacker,
} from "../lib/hooks/useAttacker";

export function AttackVisualization() {
  const { address } = useAccount();
  const [attackStep, setAttackStep] = useState<number>(0);
  const [victimDeposit, setVictimDeposit] = useState("20000");
  const [inflationAmount, setInflationAmount] = useState("20000");

  const { data: totalAssets } = useVaultTotalAssets();
  const { data: totalSupply } = useVaultTotalSupply();
  const { data: userShares } = useVaultBalance(address);
  const { data: userAssetBalance } = useAssetBalance(address);
  const { data: attackerShares } = useAttackerStats().myShares;
  const { data: attackerBalance } = useAttackerStats().myBalance;

  const victimDepositBigInt = parseUnits(victimDeposit || "0", 6);
  const { data: sharesPreview } = useConvertToShares(victimDepositBigInt);

  const {
    deposit,
    isPending: isDepositing,
    isSuccess: depositSuccess,
  } = useDeposit();
  const { approve: approveVault, isPending: isApprovingVault } =
    useApproveAsset();
  const { approve: approveAttacker, isPending: isApprovingAttacker } =
    useApproveForAttacker();
  const {
    execute: step1,
    isPending: step1Pending,
    isSuccess: step1Success,
  } = useAttackStep1();
  const {
    execute: step2,
    isPending: step2Pending,
    isSuccess: step2Success,
  } = useAttackStep2();
  const {
    execute: step3,
    isPending: step3Pending,
    isSuccess: step3Success,
  } = useAttackStep3();

  const handleApproveVault = () => {
    approveVault(parseUnits("1000000", 6));
  };

  const handleApproveAttacker = () => {
    approveAttacker(parseUnits("1000000", 6));
  };

  const handleDeposit = () => {
    if (!address) return;
    deposit(parseUnits(victimDeposit, 6), address);
  };

  const handleStep1 = () => {
    step1();
    setAttackStep(1);
  };

  const handleStep2 = () => {
    step2(parseUnits(inflationAmount, 6));
    setAttackStep(2);
  };

  const handleStep3 = () => {
    step3();
    setAttackStep(3);
  };

  const exchangeRate =
    totalAssets && totalSupply && totalSupply > 0n
      ? Number(formatUnits(totalAssets, 6)) /
        Number(formatUnits(totalSupply, 18))
      : 1;

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 text-white p-8">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-4xl font-bold mb-2">
          ERC-4626 Inflation Attack Demo
        </h1>
        <p className="text-gray-300 mb-8">
          This demo showcases how attackers can exploit rounding issues in
          ERC-4626 vaults to steal funds.
        </p>

        {!address && (
          <div className="bg-yellow-900/50 border border-yellow-600 rounded-lg p-4 mb-6">
            <p className="text-yellow-200">
              Please connect your wallet to interact with the demo.
            </p>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
            <h2 className="text-2xl font-semibold mb-4">Vault State</h2>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-400">Total Assets:</span>
                <span className="font-mono">
                  {totalAssets ? formatUnits(totalAssets, 6) : "0"} USDT
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Total Shares:</span>
                <span className="font-mono">
                  {totalSupply ? formatUnits(totalSupply, 18) : "0"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Exchange Rate:</span>
                <span className="font-mono">
                  {exchangeRate.toFixed(6)} assets/share
                </span>
              </div>
              {address && (
                <>
                  <div className="flex justify-between pt-2 border-t border-gray-700">
                    <span className="text-gray-400">Your Shares:</span>
                    <span className="font-mono">
                      {userShares ? formatUnits(userShares, 18) : "0"}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Your Asset Balance:</span>
                    <span className="font-mono">
                      {userAssetBalance
                        ? formatUnits(userAssetBalance, 6)
                        : "0"}{" "}
                      USDT
                    </span>
                  </div>
                </>
              )}
            </div>
          </div>

          <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
            <h2 className="text-2xl font-semibold mb-4">Attacker State</h2>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-400">Attacker Shares:</span>
                <span className="font-mono text-red-400">
                  {attackerShares ? formatUnits(attackerShares, 18) : "0"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Attacker Balance:</span>
                <span className="font-mono text-red-400">
                  {attackerBalance ? formatUnits(attackerBalance, 6) : "0"} USDT
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 mb-6">
          <h2 className="text-2xl font-semibold mb-4">Attack Steps</h2>
          <div className="space-y-4">
            <div
              className={`p-4 rounded-lg border-2 ${
                attackStep >= 1
                  ? "border-green-500 bg-green-900/20"
                  : "border-gray-700"
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-semibold">
                  Step 1: Mint Initial Share
                </h3>
                {step1Success && (
                  <span className="text-green-400">✓ Complete</span>
                )}
              </div>
              <p className="text-gray-300 text-sm mb-3">
                Attacker deposits 1 wei to mint the first share, setting
                totalSupply = 1 and totalAssets = 1.
              </p>
              {address && (
                <div className="flex gap-2">
                  <button
                    onClick={handleApproveAttacker}
                    disabled={isApprovingAttacker}
                    className="bg-blue-600 hover:bg-blue-700 disabled:opacity-50 px-4 py-2 rounded"
                  >
                    {isApprovingAttacker ? "Approving..." : "Approve Asset"}
                  </button>
                  <button
                    onClick={handleStep1}
                    disabled={step1Pending || step1Success}
                    className="bg-red-600 hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed px-4 py-2 rounded"
                  >
                    {step1Pending
                      ? "Executing..."
                      : step1Success
                      ? "Completed"
                      : "Execute Step 1"}
                  </button>
                </div>
              )}
            </div>

            <div
              className={`p-4 rounded-lg border-2 ${
                attackStep >= 2
                  ? "border-green-500 bg-green-900/20"
                  : "border-gray-700"
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-semibold">
                  Step 2: Inflate Denominator
                </h3>
                {step2Success && (
                  <span className="text-green-400">✓ Complete</span>
                )}
              </div>
              <p className="text-gray-300 text-sm mb-3">
                Attacker transfers assets directly to the vault, inflating
                totalAssets without minting shares. This manipulates the share
                calculation formula.
              </p>
              <div className="flex gap-2 mb-3">
                <input
                  type="number"
                  value={inflationAmount}
                  onChange={(e) => setInflationAmount(e.target.value)}
                  placeholder="Inflation amount"
                  className="bg-gray-700 text-white px-3 py-2 rounded flex-1"
                  disabled={step2Pending || step2Success}
                />
                <span className="text-gray-400 self-center">USDT</span>
              </div>
              {address && (
                <button
                  onClick={handleStep2}
                  disabled={step2Pending || step2Success || !step1Success}
                  className="bg-red-600 hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed px-4 py-2 rounded"
                >
                  {step2Pending
                    ? "Executing..."
                    : step2Success
                    ? "Completed"
                    : "Execute Step 2"}
                </button>
              )}
            </div>

            <div
              className={`p-4 rounded-lg border-2 ${
                attackStep >= 3
                  ? "border-green-500 bg-green-900/20"
                  : "border-gray-700"
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-semibold">
                  Step 3: Victim Deposits
                </h3>
              </div>
              <p className="text-gray-300 text-sm mb-3">
                Victim tries to deposit. Due to rounding, they receive zero or
                minimal shares. Formula: shares = totalSupply * assets /
                totalAssets
              </p>
              <div className="bg-gray-900 p-3 rounded mb-3 font-mono text-sm">
                <div className="text-gray-400">
                  Preview shares for {victimDeposit} USDT:
                </div>
                <div className="text-red-400 text-lg mt-1">
                  {sharesPreview ? formatUnits(sharesPreview, 18) : "0"} shares
                </div>
              </div>
              <div className="flex gap-2 mb-3">
                <input
                  type="number"
                  value={victimDeposit}
                  onChange={(e) => setVictimDeposit(e.target.value)}
                  placeholder="Deposit amount"
                  className="bg-gray-700 text-white px-3 py-2 rounded flex-1"
                  disabled={isDepositing}
                />
                <span className="text-gray-400 self-center">USDT</span>
              </div>
              {address && (
                <div className="flex gap-2">
                  <button
                    onClick={handleApproveVault}
                    disabled={isApprovingVault}
                    className="bg-blue-600 hover:bg-blue-700 disabled:opacity-50 px-4 py-2 rounded"
                  >
                    {isApprovingVault ? "Approving..." : "Approve"}
                  </button>
                  <button
                    onClick={handleDeposit}
                    disabled={isDepositing || !step2Success}
                    className="bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed px-4 py-2 rounded flex-1"
                  >
                    {isDepositing
                      ? "Depositing..."
                      : depositSuccess
                      ? "Deposited"
                      : "Deposit as Victim"}
                  </button>
                </div>
              )}
            </div>

            <div
              className={`p-4 rounded-lg border-2 ${
                attackStep >= 3
                  ? "border-green-500 bg-green-900/20"
                  : "border-gray-700"
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-semibold">
                  Step 4: Attacker Steals
                </h3>
                {step3Success && (
                  <span className="text-green-400">✓ Complete</span>
                )}
              </div>
              <p className="text-gray-300 text-sm mb-3">
                Attacker redeems their share and receives almost all the vault
                assets, including the victim's deposit.
              </p>
              {address && (
                <button
                  onClick={handleStep3}
                  disabled={step3Pending || step3Success || !depositSuccess}
                  className="bg-red-600 hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed px-4 py-2 rounded"
                >
                  {step3Pending
                    ? "Executing..."
                    : step3Success
                    ? "Completed"
                    : "Execute Step 4"}
                </button>
              )}
            </div>
          </div>
        </div>

        <div className="bg-blue-900/30 border border-blue-600 rounded-lg p-6">
          <h2 className="text-2xl font-semibold mb-4">How the Attack Works</h2>
          <div className="space-y-3 text-gray-200">
            <p>
              The attack exploits the rounding in the share calculation formula:
            </p>
            <div className="bg-gray-900 p-4 rounded font-mono text-center text-lg">
              shares = totalSupply × assets / totalAssets
            </div>
            <p>
              By manipulating{" "}
              <code className="bg-gray-800 px-2 py-1 rounded">totalAssets</code>{" "}
              through direct transfers, attackers can make victims receive zero
              or minimal shares, allowing them to steal the deposits.
            </p>
            <p className="text-yellow-300 font-semibold">
              This is a real vulnerability that has affected multiple DeFi
              protocols. Always use protected vault implementations!
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
