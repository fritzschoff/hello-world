"use client";

import { useState } from "react";
import { useAccount, useBalance } from "wagmi";
import { formatEther, parseEther } from "viem";
import {
  useDAOBalance,
  useUserBalance,
  useDeposit,
  useWithdraw,
} from "../lib/hooks/useDAO";
import {
  useAttack,
  useAttackerBalance,
  useAttackCount,
  useWithdrawStolenFunds,
} from "../lib/hooks/useReentrancyAttacker";
import { CONTRACTS } from "../lib/contracts";

export function ReentrancyVisualization() {
  const { address } = useAccount();
  const [depositAmount, setDepositAmount] = useState("1");
  const [attackAmount, setAttackAmount] = useState("1");
  const [selectedDAO, setSelectedDAO] = useState<"vulnerable" | "secure">(
    "vulnerable"
  );

  const daoAddress =
    selectedDAO === "vulnerable"
      ? CONTRACTS.VulnerableDAO.address
      : CONTRACTS.SecureDAO.address;

  const { data: daoBalance } = useDAOBalance(daoAddress);
  const { data: userBalance } = useUserBalance(daoAddress, address);
  const { data: attackerBalance } = useAttackerBalance();
  const { data: attackCount } = useAttackCount();
  const { data: userETHBalance } = useBalance({ address });

  const {
    deposit,
    isPending: isDepositing,
    isSuccess: depositSuccess,
  } = useDeposit(daoAddress);
  const {
    withdraw,
    isPending: isWithdrawing,
    isSuccess: withdrawSuccess,
  } = useWithdraw(daoAddress);
  const {
    execute: attack,
    isPending: isAttacking,
    isSuccess: attackSuccess,
  } = useAttack();
  const {
    execute: withdrawStolen,
    isPending: isWithdrawingStolen,
    isSuccess: withdrawStolenSuccess,
  } = useWithdrawStolenFunds();

  const handleDeposit = () => {
    deposit(parseEther(depositAmount));
  };

  const handleWithdraw = () => {
    withdraw();
  };

  const handleAttack = () => {
    attack(parseEther(attackAmount));
  };

  const handleWithdrawStolen = () => {
    withdrawStolen();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 text-white p-8">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-4xl font-bold mb-2">
          The DAO Hack - Reentrancy Attack Demo
        </h1>
        <p className="text-gray-300 mb-8">
          This demo showcases the reentrancy attack that led to the Ethereum
          hard fork in 2016, splitting Ethereum into Ethereum and Ethereum
          Classic.
        </p>

        {!address && (
          <div className="bg-yellow-900/50 border border-yellow-600 rounded-lg p-4 mb-6">
            <p className="text-yellow-200">
              Please connect your wallet to interact with the demo.
            </p>
          </div>
        )}

        <div className="mb-6">
          <div className="flex gap-4 mb-4">
            <button
              onClick={() => setSelectedDAO("vulnerable")}
              className={`px-6 py-3 rounded-lg font-semibold ${
                selectedDAO === "vulnerable"
                  ? "bg-red-600 hover:bg-red-700"
                  : "bg-gray-700 hover:bg-gray-600"
              }`}
            >
              Vulnerable DAO
            </button>
            <button
              onClick={() => setSelectedDAO("secure")}
              className={`px-6 py-3 rounded-lg font-semibold ${
                selectedDAO === "secure"
                  ? "bg-green-600 hover:bg-green-700"
                  : "bg-gray-700 hover:bg-gray-600"
              }`}
            >
              Secure DAO (Fixed)
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
            <h2 className="text-2xl font-semibold mb-4">
              {selectedDAO === "vulnerable" ? "Vulnerable DAO" : "Secure DAO"}{" "}
              State
            </h2>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-400">DAO Balance:</span>
                <span className="font-mono">
                  {daoBalance ? formatEther(daoBalance) : "0"} ETH
                </span>
              </div>
              {address && (
                <>
                  <div className="flex justify-between pt-2 border-t border-gray-700">
                    <span className="text-gray-400">Your Balance:</span>
                    <span className="font-mono">
                      {userBalance ? formatEther(userBalance) : "0"} ETH
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Your ETH:</span>
                    <span className="font-mono">
                      {userETHBalance ? formatEther(userETHBalance.value) : "0"}{" "}
                      ETH
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
                <span className="text-gray-400">Stolen Funds:</span>
                <span className="font-mono text-red-400">
                  {attackerBalance ? formatEther(attackerBalance) : "0"} ETH
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Reentrancy Count:</span>
                <span className="font-mono text-red-400">
                  {attackCount?.toString() || "0"}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 mb-6">
          <h2 className="text-2xl font-semibold mb-4">DAO Operations</h2>
          <div className="space-y-4">
            <div className="p-4 rounded-lg border border-gray-700">
              <h3 className="text-lg font-semibold mb-2">Deposit ETH</h3>
              <p className="text-gray-300 text-sm mb-3">
                Deposit ETH into the DAO. Minimum deposit is 1 ETH.
              </p>
              <div className="flex gap-2">
                <input
                  type="number"
                  value={depositAmount}
                  onChange={(e) => setDepositAmount(e.target.value)}
                  placeholder="Amount in ETH"
                  className="bg-gray-700 text-white px-3 py-2 rounded flex-1"
                  disabled={isDepositing}
                  min="1"
                  step="0.1"
                />
                <span className="text-gray-400 self-center">ETH</span>
                {address && (
                  <button
                    onClick={handleDeposit}
                    disabled={isDepositing || parseFloat(depositAmount) < 1}
                    className="bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed px-4 py-2 rounded"
                  >
                    {isDepositing
                      ? "Depositing..."
                      : depositSuccess
                      ? "Deposited"
                      : "Deposit"}
                  </button>
                )}
              </div>
            </div>

            <div className="p-4 rounded-lg border border-gray-700">
              <h3 className="text-lg font-semibold mb-2">Withdraw ETH</h3>
              <p className="text-gray-300 text-sm mb-3">
                Withdraw your balance from the DAO.
              </p>
              {address && (
                <button
                  onClick={handleWithdraw}
                  disabled={isWithdrawing || !userBalance || userBalance === 0n}
                  className="bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed px-4 py-2 rounded"
                >
                  {isWithdrawing
                    ? "Withdrawing..."
                    : withdrawSuccess
                    ? "Withdrawn"
                    : "Withdraw"}
                </button>
              )}
            </div>
          </div>
        </div>

        {selectedDAO === "vulnerable" && (
          <div className="bg-red-900/30 border border-red-600 rounded-lg p-6 mb-6">
            <h2 className="text-2xl font-semibold mb-4">Reentrancy Attack</h2>
            <div className="space-y-4">
              <div className="p-4 rounded-lg border border-red-700 bg-red-900/20">
                <h3 className="text-lg font-semibold mb-2">Execute Attack</h3>
                <p className="text-gray-300 text-sm mb-3">
                  The attacker deposits 1 ETH, then calls withdraw(). The
                  vulnerable DAO sends ETH before updating the balance. The
                  attacker's receive() function re-enters withdraw() while their
                  balance is still non-zero, draining the entire DAO.
                </p>
                <div className="bg-gray-900 p-3 rounded mb-3 font-mono text-sm">
                  <div className="text-gray-400">Attack Flow:</div>
                  <div className="text-red-400 mt-1">
                    1. Deposit 1 ETH → 2. Call withdraw() → 3. Receive ETH → 4.
                    Re-enter withdraw() → 5. Repeat until DAO is drained
                  </div>
                </div>
                <div className="flex gap-2 mb-3">
                  <input
                    type="number"
                    value={attackAmount}
                    onChange={(e) => setAttackAmount(e.target.value)}
                    placeholder="Attack amount"
                    className="bg-gray-700 text-white px-3 py-2 rounded flex-1"
                    disabled={isAttacking}
                    min="1"
                    step="0.1"
                  />
                  <span className="text-gray-400 self-center">ETH</span>
                  {address && (
                    <button
                      onClick={handleAttack}
                      disabled={isAttacking || parseFloat(attackAmount) < 1}
                      className="bg-red-600 hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed px-4 py-2 rounded"
                    >
                      {isAttacking
                        ? "Attacking..."
                        : attackSuccess
                        ? "Attack Complete"
                        : "Execute Attack"}
                    </button>
                  )}
                </div>
                {attackerBalance && attackerBalance > 0n && (
                  <button
                    onClick={handleWithdrawStolen}
                    disabled={isWithdrawingStolen}
                    className="bg-red-600 hover:bg-red-700 disabled:opacity-50 px-4 py-2 rounded"
                  >
                    {isWithdrawingStolen
                      ? "Withdrawing..."
                      : withdrawStolenSuccess
                      ? "Withdrawn"
                      : "Withdraw Stolen Funds"}
                  </button>
                )}
              </div>
            </div>
          </div>
        )}

        {selectedDAO === "secure" && (
          <div className="bg-green-900/30 border border-green-600 rounded-lg p-6 mb-6">
            <h2 className="text-2xl font-semibold mb-4">
              Secure DAO Protection
            </h2>
            <div className="space-y-3 text-gray-200">
              <p>The Secure DAO uses a reentrancy guard to prevent attacks:</p>
              <div className="bg-gray-900 p-4 rounded font-mono text-sm">
                <div className="text-green-400">
                  modifier noReentrancy() {"{"}
                </div>
                <div className="text-green-400 ml-4">
                  require(!locked, "reentrancy detected");
                </div>
                <div className="text-green-400 ml-4">locked = true;</div>
                <div className="text-green-400 ml-4">_;</div>
                <div className="text-green-400 ml-4">locked = false;</div>
                <div className="text-green-400">{"}"}</div>
              </div>
              <p className="text-yellow-300 font-semibold">
                The balance is also updated BEFORE sending ETH, so even if
                reentrancy is attempted, the attacker's balance is already zero.
              </p>
            </div>
          </div>
        )}

        <div className="bg-blue-900/30 border border-blue-600 rounded-lg p-6">
          <h2 className="text-2xl font-semibold mb-4">
            How The DAO Hack Worked
          </h2>
          <div className="space-y-3 text-gray-200">
            <p>
              In 2016, The DAO was a decentralized investment fund that raised
              $150M in ETH. A hacker exploited a reentrancy vulnerability to
              drain most of the funds.
            </p>
            <div className="bg-gray-900 p-4 rounded">
              <div className="font-semibold mb-2">The Vulnerability:</div>
              <div className="text-red-400 font-mono text-sm">
                withdraw() sent ETH before updating balance → attacker's
                receive() re-entered withdraw() → balance still non-zero →
                repeated until DAO drained
              </div>
            </div>
            <p>
              The Ethereum community faced a difficult decision: fork the
              blockchain to recover funds or maintain immutability. 85% voted
              for the fork, creating Ethereum (current chain) and Ethereum
              Classic (original chain).
            </p>
            <p className="text-yellow-300 font-semibold">
              This attack demonstrates why reentrancy guards and
              checks-effects-interactions pattern are critical security
              practices in smart contract development.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
