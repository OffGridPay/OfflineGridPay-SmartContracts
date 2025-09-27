#!/bin/bash

# Deploy LIN Protocol Simple to Flow Testnet
# This script creates a testnet account and deploys the contract

echo "🚀 Starting Flow Testnet Deployment for LIN Protocol Simple"

# Step 1: Generate a new key pair for testnet
echo "📝 Generating new testnet key pair..."
KEYS=$(flow keys generate --network testnet)
echo "$KEYS"

# Extract private and public keys from output
PRIVATE_KEY=$(echo "$KEYS" | grep "Private Key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Public Key" | awk '{print $3}')

echo "🔑 Generated Keys:"
echo "Private Key: $PRIVATE_KEY"
echo "Public Key: $PUBLIC_KEY"

# Step 2: Create testnet account using Flow faucet
echo "💰 Creating testnet account..."
echo "Please visit: https://faucet.flow.com/fund-account"
echo "Use the public key: $PUBLIC_KEY"
echo "This will create a testnet account and fund it with FLOW tokens"

echo "⏳ After creating the account, update flow.json with:"
echo "- The testnet account address from the faucet"
echo "- Private key: $PRIVATE_KEY"

echo "Then run: flow project deploy --network testnet"

echo "✅ Testnet deployment script completed!"
echo "📋 Next steps:"
echo "1. Visit Flow faucet and create account with the public key above"
echo "2. Update flow.json with the new account address and private key"
echo "3. Run deployment command"
