import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { http } from "wagmi";
import { localhost } from "wagmi/chains";

export const config = getDefaultConfig({
  appName: "ERC4626 Inflation Attack Demo",
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || "demo",
  chains: [localhost],
  transports: {
    [localhost.id]: http("http://localhost:8545"),
  },
  ssr: true,
});
