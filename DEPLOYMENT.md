# KipuBankV2 Deployment Configuration

## Environment Setup

1. Copy `.env.example` to `.env`
2. Fill in your actual values:
   - `PRIVATE_KEY`: Your wallet private key (without 0x prefix)
   - `INFURA_API_KEY`: Your Infura API key
   - `ETHERSCAN_API_KEY`: Your Etherscan API key

## Deployment Commands

### Deploy to Sepolia Testnet
```bash
forge script script/DeployKipuBank.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Deploy to Mainnet
```bash
forge script script/DeployKipuBank.s.sol \
  --rpc-url https://mainnet.infura.io/v3/$INFURA_API_KEY \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## Contract Verification

After deployment, verify the contract on Etherscan:
```bash
forge verify-contract <CONTRACT_ADDRESS> \
  src/KipuBankV2.sol:KipuBankV2 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --chain-id <CHAIN_ID>
```

## Initial Configuration

The contract will be deployed with:
- Bank Cap: 1000 ETH
- All roles granted to deployer
- Interest Rate: 0.5% (50 basis points)
- Daily Withdrawal Limit: 10 ETH
- Minimum Deposit: 0.001 ETH

## Post-Deployment Setup

1. Transfer ownership of roles to multisig wallets
2. Set up oracle price feeds
3. Configure monitoring and alerts
4. Test all functions thoroughly


