// Frontend Configuration - Copy this to your frontend project
export const SYNCRATE_CONFIG = {
  // Base Sepolia
  base: {
    chainId: 84532,
    name: "Base Sepolia",
    rpc: "https://sepolia.base.org",
    contracts: {
      kyc: "0xec05145f67e983d43b797f1c62fa7c2fc12fd79e",
      usdc: "0x691ecfdec29aefd5d920c4fbd2816eb331e8a73a",
      ousg: "0x2dbb9594bd034f4992bfb1e58e8b1560b3a5197d",
      tbill: "0x7e7be4258725ff0781cf255023882e4c4b95cc66",
      tbillIssuer: "0xcd0d6ccbedc558dd0466d20d814a91d7829f30a9",
      ousgRedemption: "0x3c765f129f2325be4da9d956f422d94bd9abd317",
      faucet: "0x8a61402cc9328f5ea4be688e47ef17ae9dc2fd87",
      settlement: "0x2c2522b2da43054c4d25445856dab9e6c300efaf"
    }
  },

  // Arbitrum Sepolia
  arbitrum: {
    chainId: 421614,
    name: "Arbitrum Sepolia",
    rpc: "https://sepolia-rollup.arbitrum.io/rpc",
    contracts: {
      kyc: "0xba50d1ba3fda452160706b600b303e57313344f0",
      usdc: "0x0316315dc0e7fac06e077cbad01cc085119302a1",
      ousg: "0x67418badc0410c5c0c4d68191f9f13a9f00b7958",
      tbill: "0x28e478a9adb41826271e74fc4cc63522129e0eb5",
      tbillIssuer: "0xb898c34e7ea7a2aa4d07ac866568ce6f6fa17e6b",
      ousgRedemption: "0xba9e8c257dbfbcc8ac61875976e3aaa7748f93c7",
      faucet: "0x611f02d693d80c5fdb31dac15859975858111dda",
      settlement: "0x77dd815d8396cfd1bba773f158c2b47c7a31aefa"
    }
  },

  // Ethereum Sepolia
  sepolia: {
    chainId: 11155111,
    name: "Ethereum Sepolia",
    rpc: "https://sepolia.drpc.org",
    contracts: {
      kyc: "0xb883591548aec1fa506c918784406f91503b75ba",
      usdc: "0x11e00a1babca878692acc30aae7043c3a05ff1c8",
      ousg: "0x709c1a61f8b8d3fd12098c9e2c752bd1be38140b",
      tbill: "0xa6e3f47a96851b2f6345d52db474c1413c472be4",
      tbillIssuer: "0x5bc51b3cbd4fc33508845e382316d5e8ca1f426a",
      ousgRedemption: "0xe7db6bb62ad9f57b3989ee13637747bfed367127",
      faucet: "0x748019b15a65d62cd84ffc2deb7a96a51e35e459",
      settlement: "0x12ba1f4c5bb3e06ca8a77226cdb18d2218c32436"
    }
  },

  // Asset IDs for KYC checks
  assetIds: {
    ousg: "0x3ad5c35017114f937daede2661e1dcec25ac9f339a9b68c6a6da37cfe97bbc07",
    usdc: "0x4f15a7f3a651bf5e8d11ce1a1f8e22d8f2e3b4c5c8c9d0e1f2a3b4c5d6e7f8a",
    tbill: "0x5a1c0de5b5e9f1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c"
  },

  // Test accounts
  testAccounts: {
    kyc_approved: "0x1111111111111111111111111111111111111111",
    kyc_rejected: "0x2222222222222222222222222222222222222222"
  },

  // Chain enum for routing
  chainEnum: {
    Base: 0,
    Arbitrum: 1
  }
};

// Helper to get config by chain ID
export function getConfigByChainId(chainId) {
  const configs = {
    84532: SYNCRATE_CONFIG.base,
    421614: SYNCRATE_CONFIG.arbitrum,
    11155111: SYNCRATE_CONFIG.sepolia
  };
  return configs[chainId];
}

// Helper to get contract address
export function getContractAddress(chainId, contractName) {
  const config = getConfigByChainId(chainId);
  return config?.contracts[contractName];
}

// Event signatures for decoding
export const EVENT_SIGNATURES = {
  RouteStarted: "RouteStarted(address,uint256,uint8)",
  Redeemed: "Redeemed(address,uint256)",
  Issued: "Issued(address,uint256,uint8)",
  RouteCompleted: "RouteCompleted(address,uint256,uint8)",
  RouteFailed: "RouteFailed(address,string)",
  FaucetDrip: "FaucetDrip(address)"
};

// ABI snippet for Settlement.settle()
export const SETTLEMENT_ABI = [
  {
    name: "settle",
    type: "function",
    inputs: [
      { name: "user", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "chain", type: "uint8" }
    ],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    name: "RouteStarted",
    type: "event",
    inputs: [
      { name: "user", type: "address", indexed: true },
      { name: "amount", type: "uint256", indexed: false },
      { name: "chain", type: "uint8", indexed: true }
    ]
  },
  {
    name: "Redeemed",
    type: "event",
    inputs: [
      { name: "user", type: "address", indexed: true },
      { name: "amount", type: "uint256", indexed: false }
    ]
  },
  {
    name: "Issued",
    type: "event",
    inputs: [
      { name: "user", type: "address", indexed: true },
      { name: "amount", type: "uint256", indexed: false },
      { name: "chain", type: "uint8", indexed: true }
    ]
  },
  {
    name: "RouteCompleted",
    type: "event",
    inputs: [
      { name: "user", type: "address", indexed: true },
      { name: "amount", type: "uint256", indexed: false },
      { name: "chain", type: "uint8", indexed: true }
    ]
  },
  {
    name: "RouteFailed",
    type: "event",
    inputs: [
      { name: "user", type: "address", indexed: true },
      { name: "reason", type: "string", indexed: false }
    ]
  }
];

export const FAUCET_ABI = [
  {
    name: "drip",
    type: "function",
    inputs: [],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    name: "FaucetDrip",
    type: "event",
    inputs: [{ name: "user", type: "address", indexed: true }]
  }
];

export const ERC20_ABI = [
  {
    name: "balanceOf",
    type: "function",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view"
  },
  {
    name: "approve",
    type: "function",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable"
  }
];

export const KYC_ABI = [
  {
    name: "isAllowed",
    type: "function",
    inputs: [
      { name: "user", type: "address" },
      { name: "assetId", type: "bytes32" }
    ],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "view"
  }
];

// Usage Example:
/*
import { SYNCRATE_CONFIG, getContractAddress } from './config';

// Get settlement executor on Base
const settlementAddr = getContractAddress(84532, 'settlement');
// Returns: "0x2c2522b2da43054c4d25445856dab9e6c300efaf"

// Check if user is KYC'd
const isKYCd = await kycContract.isAllowed(userAddress, SYNCRATE_CONFIG.assetIds.ousg);

// Call faucet
await faucetContract.drip();

// Call settlement
await settlementContract.settle(userAddress, amount, 0); // 0 = Base chain

// Listen to events
settlement.on("RouteCompleted", (user, amount, chain) => {
  console.log(`Route completed for ${user}: ${amount} tokens on chain ${chain}`);
});
*/
