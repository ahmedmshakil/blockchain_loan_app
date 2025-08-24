import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

/// Configuration class for blockchain settings and Sepolia testnet connection
class BlockchainConfig {
  // Sepolia Testnet Configuration
  static const String networkName = 'Sepolia Testnet';
  static const int chainId = 11155111;
  
  // Infura RPC Configuration
  static const String infuraProjectId = 'YOUR_INFURA_PROJECT_ID';
  static const String rpcUrl = 'https://sepolia.infura.io/v3/$infuraProjectId';
  
  // Smart Contract Configuration
  static const String contractAddress = '0xYOUR_CONTRACT_ADDRESS';
  
  // Demo Wallet Configuration (for testing purposes)
  static const String demoWalletAddress = '0x9EBA0526580292dF4e1C50e19AEB3ec69e12E270';
  
  // Gas Configuration
  static const int defaultGasLimit = 300000;
  static const int defaultGasPrice = 20000000000; // 20 Gwei
  
  // Transaction Configuration
  static const Duration transactionTimeout = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Security Configuration
  static const String secureStorageKeyPrefix = 'blockchain_loan_app_';
  static const String privateKeyStorageKey = '${secureStorageKeyPrefix}private_key';
  static const String walletAddressStorageKey = '${secureStorageKeyPrefix}wallet_address';
  
  // Environment-specific settings
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get enableLogging => !isProduction;
  
  /// Get the Web3 client configuration
  static Web3Client getWeb3Client() {
    return Web3Client(rpcUrl, http.Client());
  }
  
  /// Get contract address as EthereumAddress
  static EthereumAddress getContractAddress() {
    return EthereumAddress.fromHex(contractAddress);
  }
  
  /// Get demo wallet address as EthereumAddress
  static EthereumAddress getDemoWalletAddress() {
    return EthereumAddress.fromHex(demoWalletAddress);
  }
  
  /// Validate configuration before use
  static bool validateConfiguration() {
    if (infuraProjectId == 'YOUR_INFURA_PROJECT_ID') {
      throw Exception('Infura Project ID not configured');
    }
    if (contractAddress == '0xYOUR_CONTRACT_ADDRESS') {
      throw Exception('Smart contract address not configured');
    }
    return true;
  }
}