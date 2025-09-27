# FlowEVM Deployment Guide

## 🚀 Ready to Deploy!

Your LIN Protocol contract has been successfully migrated to FlowEVM and all tests are passing (20/20). Follow these steps to deploy:

## Step 1: Set up Environment

1. Copy the environment template:
```bash
cp .env.example .env
```

2. Edit the `.env` file with your private key:
```bash
nano .env
```

3. Add your private key (without 0x prefix):
```
PRIVATE_KEY=your_private_key_here_without_0x
REPORT_GAS=true
```

## Step 2: Get FlowEVM Testnet FLOW

1. Visit the FlowEVM testnet faucet: https://testnet-faucet.onflow.org/fund-account
2. Enter your wallet address
3. Request testnet FLOW tokens
4. Wait for the transaction to confirm

## Step 3: Deploy to FlowEVM Testnet

```bash
npm run deploy:testnet
```

This will:
- Deploy your LINProtocolEVM contract
- Show you the contract address
- Verify the deployment
- Provide links to view on FlowScan

## Step 4: Verify Contract (Optional)

After deployment, verify your contract on FlowScan:
```bash
npx hardhat verify --network flowTestnet YOUR_CONTRACT_ADDRESS
```

## FlowEVM Network Details

### Testnet
- **Network Name**: Flow EVM Testnet  
- **RPC URL**: `https://testnet.evm.nodes.onflow.org`
- **Chain ID**: `545`
- **Currency Symbol**: FLOW
- **Block Explorer**: https://evm-testnet.flowscan.org
- **Faucet**: https://testnet-faucet.onflow.org/fund-account

### Mainnet (for production)
- **Network Name**: Flow EVM Mainnet
- **RPC URL**: `https://mainnet.evm.nodes.onflow.org`  
- **Chain ID**: `747`
- **Currency Symbol**: FLOW
- **Block Explorer**: https://evm.flowscan.org

## Add FlowEVM to MetaMask

**Testnet:**
1. Open MetaMask
2. Click "Add Network" 
3. Fill in the testnet details above

**Mainnet:**
1. Use the mainnet details above when ready for production

## Contract Features Migrated Successfully

✅ **Offline Transactions**: Create and transfer via Bluetooth  
✅ **Batch Synchronization**: Efficient blockchain sync  
✅ **FLOW Deposit Management**: Pre-funded gas system  
✅ **ECDSA Security**: Cryptographic signature validation  
✅ **Replay Protection**: Nonce-based security  
✅ **Account Management**: Activate/deactivate accounts  
✅ **Emergency Functions**: Owner-only emergency controls  

## Key Differences from Original Flow Version

- **Native ETH/FLOW**: Uses native tokens instead of FlowToken resource
- **ECDSA Signatures**: Standard Ethereum signature format
- **Gas Optimization**: Optimized for EVM gas costs
- **Solidity Patterns**: Uses OpenZeppelin security patterns

## Next Steps After Deployment

1. **Save Contract Address**: Update your frontend/mobile app config
2. **Test Functions**: Try initializing accounts and processing transactions
3. **Monitor Gas Costs**: Check transaction fees on testnet
4. **Update Documentation**: Document the new contract address
5. **Deploy to Mainnet**: When ready for production

## Troubleshooting

**Low Balance Error**: Make sure you have enough FLOW for gas fees  
**Network Error**: Check RPC URL and chain ID  
**Signature Error**: Ensure private key is correct (without 0x)  
**Contract Error**: Run tests locally first: `npm test`

## Support

- FlowEVM Documentation: https://developers.flow.com/evm/about
- FlowEVM Discord: https://discord.gg/flow
- Contract Tests: All 20 tests passing ✅
