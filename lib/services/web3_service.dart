import 'dart:convert';
import 'dart:developer' as developer;
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/blockchain_config.dart';

/// Low-level Web3 service for blockchain interactions
/// Handles Web3 client initialization, contract loading, and transaction management
class Web3Service {
  static Web3Service? _instance;
  Web3Client? _web3Client;
  DeployedContract? _contract;
  EthPrivateKey? _credentials;
  EthereumAddress? _walletAddress;
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Singleton pattern for Web3Service
  static Web3Service get instance {
    _instance ??= Web3Service._internal();
    return _instance!;
  }
  
  Web3Service._internal();
  
  /// Initialize Web3 client and validate configuration
  Future<Web3Client> getWeb3Client() async {
    if (_web3Client != null) {
      return _web3Client!;
    }
    
    try {
      // Validate configuration before creating client
      BlockchainConfig.validateConfiguration();
      
      // Create HTTP client with timeout
      final httpClient = http.Client();
      
      // Initialize Web3 client with Sepolia RPC
      _web3Client = Web3Client(BlockchainConfig.rpcUrl, httpClient);
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Web3 client initialized successfully', name: 'Web3Service');
      }
      
      return _web3Client!;
    } catch (e) {
      developer.log('Failed to initialize Web3 client: $e', name: 'Web3Service');
      rethrow;
    }
  }
  
  /// Get contract address as EthereumAddress
  Future<EthereumAddress> getContractAddress() async {
    try {
      return BlockchainConfig.getContractAddress();
    } catch (e) {
      developer.log('Failed to get contract address: $e', name: 'Web3Service');
      rethrow;
    }
  }
  
  /// Load and return the deployed smart contract
  Future<DeployedContract> getContract() async {
    if (_contract != null) {
      return _contract!;
    }
    
    try {
      final contractAddress = await getContractAddress();
      
      // Smart contract ABI for CreditScoring contract
      final contractAbi = ContractAbi.fromJson(
        jsonEncode(_getCreditScoringAbi()),
        'CreditScoring'
      );
      
      _contract = DeployedContract(contractAbi, contractAddress);
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Contract loaded successfully at ${contractAddress.hex}', name: 'Web3Service');
      }
      
      return _contract!;
    } catch (e) {
      developer.log('Failed to load contract: $e', name: 'Web3Service');
      rethrow;
    }
  }
  
  /// Initialize wallet credentials from secure storage or demo wallet
  Future<EthPrivateKey> _getCredentials() async {
    if (_credentials != null) {
      return _credentials!;
    }
    
    try {
      // Try to get private key from secure storage
      String? storedPrivateKey = await _secureStorage.read(
        key: BlockchainConfig.privateKeyStorageKey
      );
      
      if (storedPrivateKey != null) {
        _credentials = EthPrivateKey.fromHex(storedPrivateKey);
      } else {
        // For demo purposes, we'll use a placeholder
        // In production, this should prompt user for private key or generate one
        throw Exception('Private key not found in secure storage. Please configure wallet.');
      }
      
      _walletAddress = _credentials!.address;
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Wallet credentials loaded: ${_walletAddress!.hex}', name: 'Web3Service');
      }
      
      return _credentials!;
    } catch (e) {
      developer.log('Failed to load wallet credentials: $e', name: 'Web3Service');
      rethrow;
    }
  }
  
  /// Store private key securely
  Future<void> storePrivateKey(String privateKey) async {
    try {
      await _secureStorage.write(
        key: BlockchainConfig.privateKeyStorageKey,
        value: privateKey
      );
      
      // Clear cached credentials to force reload
      _credentials = null;
      _walletAddress = null;
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Private key stored securely', name: 'Web3Service');
      }
    } catch (e) {
      developer.log('Failed to store private key: $e', name: 'Web3Service');
      rethrow;
    }
  }
  
  /// Get current wallet address
  Future<EthereumAddress> getWalletAddress() async {
    if (_walletAddress != null) {
      return _walletAddress!;
    }
    
    final credentials = await _getCredentials();
    _walletAddress = credentials.address;
    return _walletAddress!;
  }
  
  /// Send a transaction to the blockchain
  Future<String> sendTransaction(Transaction transaction) async {
    try {
      final web3Client = await getWeb3Client();
      final credentials = await _getCredentials();
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Sending transaction...', name: 'Web3Service');
      }
      
      // Send transaction with retry mechanism
      String txHash = await _sendTransactionWithRetry(
        web3Client, 
        credentials, 
        transaction
      );
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Transaction sent successfully: $txHash', name: 'Web3Service');
      }
      
      return txHash;
    } catch (e) {
      developer.log('Failed to send transaction: $e', name: 'Web3Service');
      rethrow;
    }
  }
  
  /// Send transaction with retry mechanism
  Future<String> _sendTransactionWithRetry(
    Web3Client client,
    EthPrivateKey credentials,
    Transaction transaction,
  ) async {
    int attempts = 0;
    
    while (attempts < BlockchainConfig.maxRetryAttempts) {
      try {
        return await client.sendTransaction(
          credentials,
          transaction,
          chainId: BlockchainConfig.chainId,
        );
      } catch (e) {
        attempts++;
        if (attempts >= BlockchainConfig.maxRetryAttempts) {
          rethrow;
        }
        
        if (BlockchainConfig.enableLogging) {
          developer.log('Transaction attempt $attempts failed, retrying...', name: 'Web3Service');
        }
        
        await Future.delayed(BlockchainConfig.retryDelay);
      }
    }
    
    throw Exception('Transaction failed after ${BlockchainConfig.maxRetryAttempts} attempts');
  }
  
  /// Call a contract function (read-only)
  Future<List<dynamic>> callContractFunction(
    String functionName, 
    List<dynamic> params
  ) async {
    try {
      final web3Client = await getWeb3Client();
      final contract = await getContract();
      
      final function = contract.function(functionName);
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Calling contract function: $functionName', name: 'Web3Service');
      }
      
      final result = await web3Client.call(
        contract: contract,
        function: function,
        params: params,
      );
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Contract function call successful: $functionName', name: 'Web3Service');
      }
      
      return result;
    } catch (e) {
      developer.log('Failed to call contract function $functionName: $e', name: 'Web3Service');
      rethrow;
    }
  }
  
  /// Send a transaction to call a contract function (write operation)
  Future<String> sendContractTransaction(
    String functionName,
    List<dynamic> params, {
    EtherAmount? value,
    int? gasLimit,
  }) async {
    try {
      final contract = await getContract();
      
      final function = contract.function(functionName);
      
      final transaction = Transaction.callContract(
        contract: contract,
        function: function,
        parameters: params,
        value: value,
        maxGas: gasLimit ?? BlockchainConfig.defaultGasLimit,
      );
      
      return await sendTransaction(transaction);
    } catch (e) {
      developer.log('Failed to send contract transaction $functionName: $e', name: 'Web3Service');
      rethrow;
    }
  }
  
  /// Get current gas price from network
  Future<EtherAmount> getGasPrice() async {
    try {
      final web3Client = await getWeb3Client();
      return await web3Client.getGasPrice();
    } catch (e) {
      developer.log('Failed to get gas price: $e', name: 'Web3Service');
      // Return default gas price if network call fails
      return EtherAmount.fromBigInt(EtherUnit.wei, BigInt.from(BlockchainConfig.defaultGasPrice));
    }
  }
  
  /// Get wallet balance
  Future<EtherAmount> getBalance([EthereumAddress? address]) async {
    try {
      final web3Client = await getWeb3Client();
      final walletAddress = address ?? await getWalletAddress();
      
      return await web3Client.getBalance(walletAddress);
    } catch (e) {
      developer.log('Failed to get balance: $e', name: 'Web3Service');
      rethrow;
    }
  }
  
  /// Check if connected to the correct network
  Future<bool> isConnectedToSepoliaNetwork() async {
    try {
      final web3Client = await getWeb3Client();
      final networkId = await web3Client.getNetworkId();
      
      return networkId == BlockchainConfig.chainId;
    } catch (e) {
      developer.log('Failed to check network: $e', name: 'Web3Service');
      return false;
    }
  }
  
  /// Wait for transaction confirmation
  Future<TransactionReceipt?> waitForTransactionConfirmation(
    String transactionHash, {
    Duration? timeout,
  }) async {
    try {
      final web3Client = await getWeb3Client();
      // Note: In a production app, you would use timeout for polling logic
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Waiting for transaction confirmation: $transactionHash', name: 'Web3Service');
      }
      
      final receipt = await web3Client.getTransactionReceipt(transactionHash);
      
      if (receipt != null) {
        if (BlockchainConfig.enableLogging) {
          developer.log('Transaction confirmed: $transactionHash', name: 'Web3Service');
        }
        return receipt;
      }
      
      // If receipt is null, transaction is still pending
      // In a real app, you might want to poll for the receipt
      return null;
    } catch (e) {
      developer.log('Failed to get transaction confirmation: $e', name: 'Web3Service');
      rethrow;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _web3Client?.dispose();
    _web3Client = null;
    _contract = null;
    _credentials = null;
    _walletAddress = null;
  }
  
  /// Get the CreditScoring contract ABI
  List<Map<String, dynamic>> _getCreditScoringAbi() {
    return [
      {
        "type": "function",
        "name": "addBorrower",
        "inputs": [
          {"name": "nid", "type": "string"},
          {"name": "name", "type": "string"},
          {"name": "profession", "type": "string"},
          {"name": "accountBalance", "type": "uint256"},
          {"name": "totalTransactions", "type": "uint256"},
          {"name": "onTimePayments", "type": "uint256"},
          {"name": "missedPayments", "type": "uint256"},
          {"name": "totalRemainingLoan", "type": "uint256"},
          {"name": "creditAgeMonths", "type": "uint256"},
          {"name": "professionRiskScore", "type": "uint256"}
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
      },
      {
        "type": "function",
        "name": "calculateCreditScore",
        "inputs": [
          {"name": "nid", "type": "string"}
        ],
        "outputs": [
          {"name": "", "type": "uint256"}
        ],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "getCreditRating",
        "inputs": [
          {"name": "nid", "type": "string"}
        ],
        "outputs": [
          {"name": "", "type": "string"}
        ],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "getMaxLoanAmount",
        "inputs": [
          {"name": "nid", "type": "string"},
          {"name": "monthlyIncome", "type": "uint256"}
        ],
        "outputs": [
          {"name": "", "type": "uint256"}
        ],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "requestLoan",
        "inputs": [
          {"name": "nid", "type": "string"},
          {"name": "amount", "type": "uint256"}
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
      },
      {
        "type": "function",
        "name": "getBorrower",
        "inputs": [
          {"name": "nid", "type": "string"}
        ],
        "outputs": [
          {"name": "name", "type": "string"},
          {"name": "profession", "type": "string"},
          {"name": "accountBalance", "type": "uint256"},
          {"name": "totalTransactions", "type": "uint256"},
          {"name": "onTimePayments", "type": "uint256"},
          {"name": "missedPayments", "type": "uint256"},
          {"name": "totalRemainingLoan", "type": "uint256"},
          {"name": "creditAgeMonths", "type": "uint256"},
          {"name": "professionRiskScore", "type": "uint256"},
          {"name": "exists", "type": "bool"}
        ],
        "stateMutability": "view"
      },
      {
        "type": "function",
        "name": "getScoreBreakdown",
        "inputs": [
          {"name": "nid", "type": "string"}
        ],
        "outputs": [
          {"name": "accountScore", "type": "uint256"},
          {"name": "txnScore", "type": "uint256"},
          {"name": "paymentScore", "type": "uint256"},
          {"name": "remainingScore", "type": "uint256"},
          {"name": "ageScore", "type": "uint256"},
          {"name": "professionScore", "type": "uint256"}
        ],
        "stateMutability": "view"
      },
      {
        "type": "event",
        "name": "BorrowerAdded",
        "inputs": [
          {"name": "nid", "type": "bytes32", "indexed": true},
          {"name": "name", "type": "string", "indexed": false}
        ]
      },
      {
        "type": "event",
        "name": "LoanRequested",
        "inputs": [
          {"name": "nid", "type": "bytes32", "indexed": true},
          {"name": "amount", "type": "uint256", "indexed": false}
        ]
      }
    ];
  }
}