## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
# Syncrate Testnet MVP

## Overview

This repository contains the Syncrate **testnet MVP**, implementing a canonical, compliance-first routing flow for real-world assets (RWAs) across multiple EVM chains.

The system demonstrates how institutional-style assets (e.g. OUSG, T-Bills) can be redeemed, settled, and re-issued across chains **without wrappers or synthetic representations**, while enforcing strict per-asset KYC at every step.

The MVP is deployed and live on:
- Ethereum Sepolia
- Base Sepolia
- Arbitrum Sepolia

The focus of this implementation is correctness, clarity, and auditability.

---

## Design Principles

- Canonical assets only  
  - No wrapped tokens  
  - No synthetic assets  
  - No rebasing or yield logic  

- Compliance-first  
  - KYC enforced on mint, burn, and transfer  
  - KYC is per asset and per chain  

- Chain isolation  
  - Independent deployments per chain  
  - No shared global state  
  - Failures are isolated  

- Explicit routing  
  - All asset flows are intentional and observable  
  - No implicit or hidden bridging behavior  

---

## Architecture

### Core Contracts

**KYCRegistry**
- Per-asset allowlist
- Queried by all tokens and settlement logic
- Determines whether an address is permitted to interact with a given asset

**OUSGToken (Ethereum Sepolia)**
- Canonical source asset
- Minting and burning controlled via roles
- All balance updates are KYC-gated

**MockUSDC**
- Canonical settlement asset (testnet)
- Deployed independently on each chain
- Used to simulate issuer settlement

**OUSGRedemptionMock (Ethereum Sepolia)**
- Burns OUSG
- Mints USDC after KYC verification
- Represents issuer-side redemption logic

**TBILLToken (Base / Arbitrum Sepolia)**
- Canonical destination asset
- Minted only after settlement
- Fully KYC-gated

**SettlementExecutor**
- Finalizes settlement on destination chains
- Mints TBILL after USDC arrival and KYC validation

**SyncrateFaucet**
- Testnet-only faucet
- Dispenses demo OUSG and USDC
- Rate-limited per address

---

## Canonical Routing Flow

Ethereum Sepolia:
1. User holds OUSG
2. User passes KYC for OUSG
3. OUSG is burned via redemption
4. USDC is minted as canonical settlement

Base / Arbitrum Sepolia:
5. USDC arrives (simulated settlement layer)
6. User passes KYC for destination asset
7. TBILL is minted
8. OUSG never exists on destination chains

At no point are assets wrapped or synthetically mirrored.

---

## KYC Enforcement

- KYC is enforced on:
  - Mint
  - Burn
  - Transfer

- Reverts such as:
OUSG: KYC failindicate **correct behavior**, not an error.

Each chain maintains its own KYC registry.  
Approval must be explicitly set per asset and per chain.

---

## Deployment Status

All contracts are deployed and operational on testnet.

- Ethereum Sepolia: source assets, redemption, faucet
- Base Sepolia: settlement and TBILL issuance
- Arbitrum Sepolia: settlement and TBILL issuance

Deployments were executed using Foundry with on-chain broadcasting.

---

## Testing Notes

Verified flows include:
- Faucet minting
- Per-asset KYC allowlisting
- OUSG mint and burn
- USDC settlement
- TBILL issuance on destination chains

KYC-related reverts confirm enforcement integrity.

---

## Scope & Limitations

- Testnet-only implementation
- Assets are mocked
- No production issuers or real bridges
- No off-chain attestations or zk-KYC integrations

The MVP validates:
- Contract architecture
- Compliance logic
- Multi-chain deployment model
- Canonical asset discipline

---

## Final Notes

This repository provides a minimal, auditable foundation for Syncrate’s routing model.

The implementation is intentionally conservative and explicit, reflecting how institutional RWA systems are expected to behave in production environments.
