import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/borrower_model.dart';
import '../services/blockchain_service.dart';
import '../utils/constants.dart';
import '../config/blockchain_config.dart';

/// Service for initializing demo user data and blockchain setup
/// Handles automatic borrower addition to blockchain on app startup
/// Requirements: 1.4, 2.2, 7.2
class DemoUserInitializationService {
  static DemoUserInitializationService? _instance;
  
  final BlockchainService _blockchainService = BlockchainService.instance;
  
  // Initialization state
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initializationError;
  DateTime? _lastInitializationAttempt;
  
  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 5);
  static const Duration initializationTimeout = Duration(minutes: 2);
  
  // Singleton pattern
  static DemoUserInitializationService get instance {
    _instance ??= DemoUserInitializationService._internal();
    return _instance!;
  }
  
  DemoUserInitializationService._internal();
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String? get initializationError => _initializationError;
  DateTime? get lastInitializationAttempt => _lastInitializationAttempt;
  
  /// Initialize demo user data and blockchain setup
  /// Requirements: 1.4, 2.2, 7.2
  Future<InitializationResult> initializeDemoUser({
    String? customNid,
    bool forceReinitialize = false,
  }) async {
    // Prevent concurrent initialization
    if (_isInitializing) {
      if (kDebugMode) {
        developer.log('Demo user initialization already in progress', name: 'DemoUserInitializationService');
      }
      return InitializationResult.inProgress();
    }
    
    // Return early if already initialized and not forcing
    if (_isInitialized && !forceReinitialize) {
      if (kDebugMode) {
        developer.log('Demo user already initialized', name: 'DemoUserInitializationService');
      }
      return InitializationResult.success('Demo user already initialized');
    }
    
    _isInitializing = true;
    _initializationError = null;
    _lastInitializationAttempt = DateTime.now();
    
    try {
      if (kDebugMode) {
        developer.log('Starting demo user initialization...', name: 'DemoUserInitializationService');
      }
      
      // Step 1: Validate blockchain configuration
      final configValidation = await _validateBlockchainConfiguration();
      if (!configValidation.isSuccess) {
        return configValidation;
      }
      
      // Step 2: Initialize blockchain service
      final blockchainInit = await _initializeBlockchainService();
      if (!blockchainInit.isSuccess) {
        return blockchainInit;
      }
      
      // Step 3: Check if demo user already exists
      final nid = customNid ?? DemoUserData.nid;
      final existingUser = await _checkExistingUser(nid);
      if (existingUser.isSuccess && existingUser.data == true) {
        _isInitialized = true;
        if (kDebugMode) {
          developer.log('Demo user already exists on blockchain: $nid', name: 'DemoUserInitializationService');
        }
        return InitializationResult.success('Demo user already exists on blockchain');
      }
      
      // Step 4: Create and add demo user to blockchain
      final userCreation = await _createDemoUserOnBlockchain(nid);
      if (!userCreation.isSuccess) {
        return userCreation;
      }
      
      // Step 5: Verify user creation
      final verification = await _verifyUserCreation(nid);
      if (!verification.isSuccess) {
        return verification;
      }
      
      _isInitialized = true;
      _initializationError = null;
      
      if (kDebugMode) {
        developer.log('Demo user initialization completed successfully', name: 'DemoUserInitializationService');
      }
      
      return InitializationResult.success('Demo user initialized successfully');
      
    } catch (e) {
      _initializationError = e.toString();
      developer.log('Demo user initialization failed: $e', name: 'DemoUserInitializationService');
      return InitializationResult.failure('Initialization failed: $e');
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Initialize demo user with retry mechanism
  /// Requirements: 2.2, 7.2
  Future<InitializationResult> initializeDemoUserWithRetry({
    String? customNid,
    bool forceReinitialize = false,
  }) async {
    InitializationResult? lastResult;
    
    for (int attempt = 1; attempt <= maxRetryAttempts; attempt++) {
      try {
        if (kDebugMode) {
          developer.log('Demo user initialization attempt $attempt/$maxRetryAttempts', name: 'DemoUserInitializationService');
        }
        
        // Add timeout to prevent hanging
        final result = await initializeDemoUser(
          customNid: customNid,
          forceReinitialize: forceReinitialize,
        ).timeout(initializationTimeout);
        
        if (result.isSuccess) {
          return result;
        }
        
        lastResult = result;
        
        // Don't retry if it's a configuration error
        if (result.errorType == InitializationErrorType.configuration) {
          break;
        }
        
        // Wait before retry (except on last attempt)
        if (attempt < maxRetryAttempts) {
          if (kDebugMode) {
            developer.log('Retrying in ${retryDelay.inSeconds} seconds...', name: 'DemoUserInitializationService');
          }
          await Future.delayed(retryDelay);
        }
        
      } on TimeoutException {
        lastResult = InitializationResult.failure('Initialization timeout after ${initializationTimeout.inMinutes} minutes');
        if (kDebugMode) {
          developer.log('Initialization attempt $attempt timed out', name: 'DemoUserInitializationService');
        }
      } catch (e) {
        lastResult = InitializationResult.failure('Unexpected error: $e');
        if (kDebugMode) {
          developer.log('Initialization attempt $attempt failed: $e', name: 'DemoUserInitializationService');
        }
      }
    }
    
    _initializationError = lastResult?.message ?? 'All initialization attempts failed';
    return lastResult ?? InitializationResult.failure('All initialization attempts failed');
  }
  
  /// Create demo borrower model from constants
  /// Requirements: 1.4
  BorrowerModel createDemoBorrowerModel({String? customNid}) {
    final nid = customNid ?? DemoUserData.nid;
    
    return BorrowerModel(
      name: DemoUserData.name,
      nid: nid,
      profession: DemoUserData.profession,
      accountBalance: BigInt.parse(DemoUserData.accountBalance),
      totalTransactions: BigInt.parse(DemoUserData.totalTransactions),
      onTimePayments: BigInt.from(DemoUserData.onTimePayments),
      missedPayments: BigInt.from(DemoUserData.missedPayments),
      totalRemainingLoan: BigInt.parse(DemoUserData.totalRemainingLoan),
      creditAgeMonths: BigInt.from(DemoUserData.creditAgeMonths),
      professionRiskScore: BigInt.from(DemoUserData.professionRiskScore),
      exists: false, // Will be set to true after blockchain creation
    );
  }
  
  /// Get initialization status and guidance
  /// Requirements: 7.2
  Map<String, dynamic> getInitializationStatus() {
    return {
      'isInitialized': _isInitialized,
      'isInitializing': _isInitializing,
      'error': _initializationError,
      'lastAttempt': _lastInitializationAttempt?.toIso8601String(),
      'demoUserNid': DemoUserData.nid,
      'demoUserName': DemoUserData.name,
      'blockchainNetwork': BlockchainConfig.networkName,
      'contractAddress': BlockchainConfig.contractAddress,
      'guidance': _getInitializationGuidance(),
    };
  }
  
  /// Reset initialization state (for testing)
  void resetInitializationState() {
    _isInitialized = false;
    _isInitializing = false;
    _initializationError = null;
    _lastInitializationAttempt = null;
    
    if (kDebugMode) {
      developer.log('Initialization state reset', name: 'DemoUserInitializationService');
    }
  }
  
  // Private helper methods
  
  /// Validate blockchain configuration
  Future<InitializationResult> _validateBlockchainConfiguration() async {
    try {
      if (kDebugMode) {
        developer.log('Validating blockchain configuration...', name: 'DemoUserInitializationService');
      }
      
      // Check if configuration is properly set
      if (!BlockchainConfig.validateConfiguration()) {
        return InitializationResult.configurationError('Invalid blockchain configuration');
      }
      
      return InitializationResult.success('Configuration validated');
    } catch (e) {
      return InitializationResult.configurationError('Configuration validation failed: $e');
    }
  }
  
  /// Initialize blockchain service
  Future<InitializationResult> _initializeBlockchainService() async {
    try {
      if (kDebugMode) {
        developer.log('Initializing blockchain service...', name: 'DemoUserInitializationService');
      }
      
      await _blockchainService.initialize();
      
      // Verify network connection
      final networkStatus = await _blockchainService.getNetworkStatus();
      if (networkStatus['isConnected'] != true) {
        return InitializationResult.networkError('Not connected to blockchain network');
      }
      
      return InitializationResult.success('Blockchain service initialized');
    } catch (e) {
      return InitializationResult.networkError('Blockchain initialization failed: $e');
    }
  }
  
  /// Check if user already exists on blockchain
  Future<InitializationResult> _checkExistingUser(String nid) async {
    try {
      if (kDebugMode) {
        developer.log('Checking if user exists: $nid', name: 'DemoUserInitializationService');
      }
      
      final borrower = await _blockchainService.getBorrowerData(nid);
      return InitializationResult.success('User check completed', data: borrower.exists);
    } catch (e) {
      return InitializationResult.blockchainError('Failed to check existing user: $e');
    }
  }
  
  /// Create demo user on blockchain
  Future<InitializationResult> _createDemoUserOnBlockchain(String nid) async {
    try {
      if (kDebugMode) {
        developer.log('Creating demo user on blockchain: $nid', name: 'DemoUserInitializationService');
      }
      
      final demoBorrower = createDemoBorrowerModel(customNid: nid);
      final transactionHash = await _blockchainService.addBorrowerToBlockchain(demoBorrower);
      
      if (kDebugMode) {
        developer.log('Demo user creation transaction: $transactionHash', name: 'DemoUserInitializationService');
      }
      
      // Wait for transaction confirmation
      final isConfirmed = await _blockchainService.verifyTransaction(transactionHash);
      if (!isConfirmed) {
        return InitializationResult.blockchainError('Transaction not confirmed: $transactionHash');
      }
      
      return InitializationResult.success('Demo user created on blockchain', data: transactionHash);
    } catch (e) {
      return InitializationResult.blockchainError('Failed to create demo user: $e');
    }
  }
  
  /// Verify user creation on blockchain
  Future<InitializationResult> _verifyUserCreation(String nid) async {
    try {
      if (kDebugMode) {
        developer.log('Verifying user creation: $nid', name: 'DemoUserInitializationService');
      }
      
      // Wait a moment for blockchain to update
      await Future.delayed(const Duration(seconds: 2));
      
      final borrower = await _blockchainService.getBorrowerData(nid);
      if (!borrower.exists) {
        return InitializationResult.blockchainError('User not found after creation');
      }
      
      // Verify data integrity
      if (borrower.name != DemoUserData.name || borrower.nid != nid) {
        return InitializationResult.blockchainError('User data mismatch after creation');
      }
      
      return InitializationResult.success('User creation verified');
    } catch (e) {
      return InitializationResult.blockchainError('Failed to verify user creation: $e');
    }
  }
  
  /// Get initialization guidance based on current state
  List<String> _getInitializationGuidance() {
    final guidance = <String>[];
    
    if (!_isInitialized) {
      guidance.add('Demo user needs to be initialized on blockchain');
      guidance.add('Ensure you have Sepolia ETH in your wallet for gas fees');
      guidance.add('Check your internet connection and blockchain network status');
      
      if (_initializationError != null) {
        if (_initializationError!.contains('insufficient funds')) {
          guidance.add('Add Sepolia ETH to your wallet: ${BlockchainConfig.demoWalletAddress}');
          guidance.add('Get free Sepolia ETH from: https://sepoliafaucet.com/');
        } else if (_initializationError!.contains('network')) {
          guidance.add('Check your internet connection');
          guidance.add('Verify Infura RPC endpoint is accessible');
        } else if (_initializationError!.contains('contract')) {
          guidance.add('Verify smart contract is deployed and accessible');
          guidance.add('Check contract address: ${BlockchainConfig.contractAddress}');
        }
      }
    } else {
      guidance.add('Demo user is successfully initialized');
      guidance.add('You can now use all blockchain features');
    }
    
    return guidance;
  }
}

/// Result class for initialization operations
class InitializationResult {
  final bool isSuccess;
  final String message;
  final InitializationErrorType? errorType;
  final dynamic data;
  
  const InitializationResult._({
    required this.isSuccess,
    required this.message,
    this.errorType,
    this.data,
  });
  
  factory InitializationResult.success(String message, {dynamic data}) {
    return InitializationResult._(
      isSuccess: true,
      message: message,
      data: data,
    );
  }
  
  factory InitializationResult.failure(String message, {InitializationErrorType? errorType}) {
    return InitializationResult._(
      isSuccess: false,
      message: message,
      errorType: errorType ?? InitializationErrorType.unknown,
    );
  }
  
  factory InitializationResult.configurationError(String message) {
    return InitializationResult._(
      isSuccess: false,
      message: message,
      errorType: InitializationErrorType.configuration,
    );
  }
  
  factory InitializationResult.networkError(String message) {
    return InitializationResult._(
      isSuccess: false,
      message: message,
      errorType: InitializationErrorType.network,
    );
  }
  
  factory InitializationResult.blockchainError(String message) {
    return InitializationResult._(
      isSuccess: false,
      message: message,
      errorType: InitializationErrorType.blockchain,
    );
  }
  
  factory InitializationResult.inProgress() {
    return const InitializationResult._(
      isSuccess: false,
      message: 'Initialization in progress',
      errorType: InitializationErrorType.inProgress,
    );
  }
  
  @override
  String toString() {
    return 'InitializationResult(success: $isSuccess, message: $message, errorType: $errorType)';
  }
}

/// Types of initialization errors
enum InitializationErrorType {
  configuration,
  network,
  blockchain,
  timeout,
  unknown,
  inProgress,
}