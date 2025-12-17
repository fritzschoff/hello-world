import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { mainnet, sepolia, localhost } from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'Stablecoin App',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'YOUR_PROJECT_ID',
  chains: [localhost, mainnet, sepolia],
  ssr: true,
});
