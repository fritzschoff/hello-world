"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { ReentrancyVisualization } from "./components/ReentrancyVisualization";

export default function Home() {
  return (
    <div>
      <nav className="bg-gray-900 border-b border-gray-800 p-4">
        <div className="max-w-6xl mx-auto flex justify-between items-center">
          <h1 className="text-xl font-bold">
            The DAO Hack - Reentrancy Attack Demo
          </h1>
          <ConnectButton />
        </div>
      </nav>
      <ReentrancyVisualization />
    </div>
  );
}
