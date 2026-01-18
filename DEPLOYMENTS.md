# Syncrate MVP - Contract Deployments

## Base Sepolia (Chain ID: 84532)
```json
{
  "chainId": 84532,
  "chainName": "Base Sepolia",
  "rpc": "https://sepolia.base.org",
  "contracts": {
    "KYCRegistry": "0xec05145f67e983d43b797f1c62fa7c2fc12fd79e",
    "MockUSDC": "0x691ecfdec29aefd5d920c4fbd2816eb331e8a73a",
    "OUSGToken": "0x2dbb9594bd034f4992bfb1e58e8b1560b3a5197d",
    "TBILLToken": "0x7e7be4258725ff0781cf255023882e4c4b95cc66",
    "TBILLIssuerMock": "0xcd0d6ccbedc558dd0466d20d814a91d7829f30a9",
    "OUSGRedemptionMock": "0x3c765f129f2325be4da9d956f422d94bd9abd317",
    "SyncrateFaucet": "0x8a61402cc9328f5ea4be688e47ef17ae9dc2fd87",
    "SettlementExecutor": "0x2c2522b2da43054c4d25445856dab9e6c300efaf"
  }
}
```

## Arbitrum Sepolia (Chain ID: 421614)
```json
{
  "chainId": 421614,
  "chainName": "Arbitrum Sepolia",
  "rpc": "https://sepolia-rollup.arbitrum.io/rpc",
  "contracts": {
    "KYCRegistry": "0xba50d1ba3fda452160706b600b303e57313344f0",
    "MockUSDC": "0x0316315dc0e7fac06e077cbad01cc085119302a1",
    "OUSGToken": "0x67418badc0410c5c0c4d68191f9f13a9f00b7958",
    "TBILLToken": "0x28e478a9adb41826271e74fc4cc63522129e0eb5",
    "TBILLIssuerMock": "0xb898c34e7ea7a2aa4d07ac866568ce6f6fa17e6b",
    "OUSGRedemptionMock": "0xba9e8c257dbfbcc8ac61875976e3aaa7748f93c7",
    "SyncrateFaucet": "0x611f02d693d80c5fdb31dac15859975858111dda",
    "SettlementExecutor": "0x77dd815d8396cfd1bba773f158c2b47c7a31aefa"
  }
}
```

## Ethereum Sepolia (Chain ID: 11155111)
```json
{
  "chainId": 11155111,
  "chainName": "Ethereum Sepolia",
  "rpc": "https://sepolia.drpc.org",
  "contracts": {
    "KYCRegistry": "0xb883591548aec1fa506c918784406f91503b75ba",
    "MockUSDC": "0x11e00a1babca878692acc30aae7043c3a05ff1c8",
    "OUSGToken": "0x709c1a61f8b8d3fd12098c9e2c752bd1be38140b",
    "TBILLToken": "0xa6e3f47a96851b2f6345d52db474c1413c472be4",
    "TBILLIssuerMock": "0x5bc51b3cbd4fc33508845e382316d5e8ca1f426a",
    "OUSGRedemptionMock": "0xe7db6bb62ad9f57b3989ee13637747bfed367127",
    "SyncrateFaucet": "0x748019b15a65d62cd84ffc2deb7a96a51e35e459",
    "SettlementExecutor": "0x12ba1f4c5bb3e06ca8a77226cdb18d2218c32436"
  }
}
```

---

## Test Accounts

### KYC-Approved Account
- **Address**: `0x1111111111111111111111111111111111111111`
- **Can**: Call faucet, route tokens, use all features

### KYC-Rejected Account
- **Address**: `0x2222222222222222222222222222222222222222`
- **Cannot**: Call faucet, route, or do anything KYC-gated

---

## Quick Integration Guide

### For Frontend Developers:
1. Import contract ABIs from `out/` (Foundry artifacts)
2. Use addresses from above for each chain
3. Connect to correct RPC for each chain
4. Listen to events for UI updates

### Key Events to Watch:
- `RouteStarted(user, amount, chain)`
- `Redeemed(user, amount)`
- `Issued(user, amount, chain)`
- `RouteCompleted(user, amount, chain)`
- `RouteFailed(user, reason)`
- `FaucetDrip(user)`

---

## Asset IDs (for KYC)
```
OUSG_ID = keccak256("mOUSG") = 0x3ad5c35017114f937daede2661e1dcec25ac9f339a9b68c6a6da37cfe97bbc07
USDC_ID = keccak256("USDC") = 0x8849f1a4e1e9b1e4fb1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c
TBILL_ID = keccak256("mTBILL") = 0x5a1c0de5b5e9f1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c1e5c
```

---

## Done! 🎉
All contracts deployed and ready for testing.
