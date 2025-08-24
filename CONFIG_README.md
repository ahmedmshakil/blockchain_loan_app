# Blockchain Configuration Setup

This document explains how to configure the blockchain settings for the loan application.

## Configuration Files Created

### 1. `lib/config/blockchain_config.dart`
Contains Sepolia testnet settings and blockchain connection parameters.

**Important**: Before running the app, you need to update these values:
- `infuraProjectId`: Replace `'YOUR_INFURA_PROJECT_ID'` with your actual Infura project ID
- `contractAddress`: Replace `'0xYOUR_CONTRACT_ADDRESS'` with your deployed smart contract address

### 2. `lib/utils/constants.dart`
Contains application constants and demo user data including:
- UI constants (colors, padding, border radius)
- Banking information
- Demo user data for testing
- Credit score configuration
- Error and success messages

### 3. `lib/config/secure_storage_config.dart`
Handles secure storage for sensitive data like private keys with:
- Cross-platform secure storage configuration
- Methods for storing/retrieving private keys, wallet addresses, and user credentials
- Biometric authentication preferences
- Security exception handling

### 4. `lib/config/environment_config.dart`
Manages environment-specific configurations for:
- Development (Sepolia testnet)
- Staging (Goerli testnet) 
- Production (Ethereum mainnet)
- API endpoints
- Logging and security settings

### 5. `lib/config/app_config.dart`
Main configuration manager that:
- Initializes all configurations on app startup
- Validates blockchain settings
- Provides configuration summary
- Handles initialization errors

## Setup Instructions

### 1. Get Infura Project ID
1. Go to [Infura.io](https://infura.io)
2. Create an account and new project
3. Copy your project ID
4. Replace `YOUR_INFURA_PROJECT_ID` in `blockchain_config.dart`

### 2. Deploy Smart Contract
1. Deploy your CreditScoring smart contract to Sepolia testnet
2. Copy the contract address
3. Replace `0xYOUR_CONTRACT_ADDRESS` in `blockchain_config.dart`

### 3. Set Up Wallet
1. The demo wallet address is already configured: `0x9EBA0526580292dF4e1C50e19AEB3ec69e12E270`
2. Make sure this wallet has Sepolia ETH for gas fees
3. You can get Sepolia ETH from faucets like:
   - [Sepolia Faucet](https://sepoliafaucet.com/)
   - [Alchemy Sepolia Faucet](https://sepoliafaucet.com/)

### 4. Environment Variables (Optional)
You can set environment variables when building:

```bash
# For development (default)
flutter run

# For staging
flutter run --dart-define=ENVIRONMENT=staging

# For production
flutter run --dart-define=ENVIRONMENT=production
```

## Configuration Validation

The app automatically validates configuration on startup:
- Checks if Infura project ID is set
- Validates contract address format
- Tests secure storage functionality
- Verifies blockchain connectivity

If validation fails, the app will show an error screen with details.

## Demo User Data

The app includes demo data for testing:
- **Name**: Shakil AHmed
- **NID**: 1234567890
- **Profession**: Blockchain Developer
- **Account Balance**: ৳600,000
- **Expected Credit Score**: 800 (Rating: A)

## Security Features

- Private keys stored in secure storage (encrypted)
- Cross-platform security options configured
- Biometric authentication support
- Certificate pinning for production
- Session timeout management

## Testing Configuration

Run the app to see the configuration test page that displays:
- Current environment settings
- Blockchain network information
- API configuration
- Security settings
- Demo user data

## Troubleshooting

### Common Issues:

1. **"Infura Project ID not configured"**
   - Update `infuraProjectId` in `blockchain_config.dart`

2. **"Smart contract address not configured"**
   - Update `contractAddress` in `blockchain_config.dart`

3. **"Secure storage initialization failed"**
   - Check device permissions
   - Ensure app has storage access

4. **Network connection errors**
   - Verify internet connection
   - Check Infura project ID and limits
   - Ensure Sepolia testnet is accessible

### Debug Mode

In debug mode, the app logs detailed configuration information to help with troubleshooting.

## Next Steps

After configuration is complete, you can proceed to implement:
1. Web3 service layer (Task 4)
2. Blockchain service for smart contract interactions (Task 5)
3. Core data models (Task 3)
4. UI components (Task 7)

The configuration system is now ready to support all blockchain operations and secure data management.