import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../services/blockchain_service.dart';
import '../config/blockchain_config.dart';
import '../utils/constants.dart';

/// Specialized provider for blockchain connection state and real-time synchronization
/// Manages blockchain connectivity, transaction monitoring, and network status
/// Requirements: 2.3, 7.4
class BlockchainProvider extends ChangeNotifier {
  static BlockchainProvider? _instance;
  
  // Services
  final BlockchainService _blockchainService = BlockchainService.instance;
  
  // Connection state
  bool _isConnected = false;
  bool _isInitialized = false;
  bool _isConnecting = false;
  String? _connectionError;
  DateTime? _lastConnectionCheck;
  
  // Network information
  String? _networkName;
  int? _chainId;
  String? _walletBalance;
  String? _gasPrice;
  String? _contractAddress;
  
  // Transaction monitoring
  final Map<String, TransactionStatus> _pendingTransactions = {};
  final List<String> _confirmedTransactions = [];
  
  // Auto-sync configuration
  Timer? _connectionCheckTimer;
  Timer? _transactionMonitorTimer;
  static const Duration _connectionCheckInterval = Duration(seconds: 30);
  static const Duration _transactionCheckInterval = Duration(seconds: 10);
  
  // Singleton pattern
  static BlockchainProvider get instance {
    _instance ??= BlockchainProvider._internal();
    return _instance!;
  }
  
  BlockchainProvider._internal() {
    _startConnectionMonitoring();
    _startTransactionMonitoring();
  }
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  bool get isConnecting => _isConnecting;
  String? get connectionError => _connectionError;
  DateTime? get lastConnectionCheck => _lastConnectionCheck;
  
  String? get networkName => _networkName;
  int? get chainId => _chainId;
  String? get walletBalance => _walletBalance;
  String? get gasPrice => _gasPrice;
  String? get contractAddress => _contractAddress;
  
  Map<String, TransactionStatus> get pendingTransactions => Map.unmodifiable(_pendingTransactions);
  List<String> get confirmedTransactions => List.unmodifiable(_confirmedTransactions);
  
  bool get hasConnectionError => _connectionError != null;
  bool get isHealthy => _isConnected && !hasConnectionError;
  
  /// Initialize blockchain connection
  /// Requirements: 2.3
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isConnecting = true;
    _connectionError = null;
    notifyListeners();
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Initializing blockchain connection...', name: 'BlockchainProvider');
      }
      
      // Initialize blockchain service
      await _blockchainService.initialize();
      
      // Load network status
      await _loadNetworkStatus();
      
      _isConnected = true;
      _isInitialized = true;
      _connectionError = null;
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Blockchain connection initialized successfully', name: 'BlockchainProvider');
      }
    } catch (e) {
      _connectionError = 'Failed to initialize blockchain: $e';
      _isConnected = false;
      developer.log('Failed to initialize blockchain: $e', name: 'BlockchainProvider');
    } finally {
      _isConnecting = false;
      _lastConnectionCheck = DateTime.now();
      notifyListeners();
    }
  }
  
  /// Check blockchain connection health
  /// Requirements: 2.3, 7.4
  Future<void> checkConnection() async {
    if (_isConnecting) return; // Avoid concurrent checks
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Checking blockchain connection...', name: 'BlockchainProvider');
      }
      
      // Test connection by getting network status
      final status = await _blockchainService.getNetworkStatus();
      
      final wasConnected = _isConnected;
      _isConnected = status['isConnected'] == true;
      _connectionError = status['error'];
      
      // Update network information
      if (_isConnected) {
        _networkName = status['network'];
        _chainId = status['chainId'];
        _walletBalance = status['walletBalance'];
        _gasPrice = status['gasPrice'];
        _contractAddress = status['contractAddress'];
      }
      
      // Notify if connection state changed
      if (wasConnected != _isConnected) {
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Connection state changed: $_isConnected', name: 'BlockchainProvider');
        }
        notifyListeners();
      }
    } catch (e) {
      final wasConnected = _isConnected;
      _isConnected = false;
      _connectionError = 'Connection check failed: $e';
      
      if (wasConnected) {
        developer.log('Lost blockchain connection: $e', name: 'BlockchainProvider');
        notifyListeners();
      }
    } finally {
      _lastConnectionCheck = DateTime.now();
    }
  }
  
  /// Reconnect to blockchain
  /// Requirements: 2.3
  Future<void> reconnect() async {
    if (EnvironmentConfig.enableDetailedLogging) {
      developer.log('Attempting to reconnect to blockchain...', name: 'BlockchainProvider');
    }
    
    _isInitialized = false; // Force re-initialization
    await initialize();
  }
  
  /// Add transaction to monitoring queue
  /// Requirements: 7.4
  void addTransactionToMonitor(String transactionHash, {String? description}) {
    _pendingTransactions[transactionHash] = TransactionStatus(
      hash: transactionHash,
      description: description,
      submittedAt: DateTime.now(),
      status: TransactionState.pending,
    );
    
    if (EnvironmentConfig.enableDetailedLogging) {
      developer.log('Added transaction to monitor: $transactionHash', name: 'BlockchainProvider');
    }
    
    notifyListeners();
  }
  
  /// Get transaction status
  /// Requirements: 7.4
  TransactionStatus? getTransactionStatus(String transactionHash) {
    return _pendingTransactions[transactionHash];
  }
  
  /// Remove transaction from monitoring
  void removeTransactionFromMonitor(String transactionHash) {
    _pendingTransactions.remove(transactionHash);
    notifyListeners();
  }
  
  /// Clear all confirmed transactions
  void clearConfirmedTransactions() {
    _confirmedTransactions.clear();
    notifyListeners();
  }
  
  /// Get network status summary
  Map<String, dynamic> getNetworkStatusSummary() {
    return {
      'isConnected': _isConnected,
      'isInitialized': _isInitialized,
      'isConnecting': _isConnecting,
      'connectionError': _connectionError,
      'lastConnectionCheck': _lastConnectionCheck?.toIso8601String(),
      'networkName': _networkName,
      'chainId': _chainId,
      'walletBalance': _walletBalance,
      'gasPrice': _gasPrice,
      'contractAddress': _contractAddress,
      'pendingTransactions': _pendingTransactions.length,
      'confirmedTransactions': _confirmedTransactions.length,
    };
  }
  
  // Private helper methods
  
  /// Load network status information
  Future<void> _loadNetworkStatus() async {
    try {
      final status = await _blockchainService.getNetworkStatus();
      
      _networkName = status['network'] ?? BlockchainConfig.networkName;
      _chainId = status['chainId'] ?? BlockchainConfig.chainId;
      _walletBalance = status['walletBalance'];
      _gasPrice = status['gasPrice'];
      _contractAddress = status['contractAddress'] ?? BlockchainConfig.contractAddress;
    } catch (e) {
      developer.log('Failed to load network status: $e', name: 'BlockchainProvider');
    }
  }
  
  /// Start automatic connection monitoring
  void _startConnectionMonitoring() {
    _connectionCheckTimer = Timer.periodic(_connectionCheckInterval, (_) async {
      if (_isInitialized && !_isConnecting) {
        await checkConnection();
      }
    });
  }
  
  /// Start transaction monitoring
  void _startTransactionMonitoring() {
    _transactionMonitorTimer = Timer.periodic(_transactionCheckInterval, (_) async {
      if (_isConnected && _pendingTransactions.isNotEmpty) {
        await _checkPendingTransactions();
      }
    });
  }
  
  /// Check status of pending transactions
  Future<void> _checkPendingTransactions() async {
    final pendingHashes = _pendingTransactions.keys.toList();
    
    for (final hash in pendingHashes) {
      try {
        final isConfirmed = await _blockchainService.verifyTransaction(hash);
        final transaction = _pendingTransactions[hash]!;
        
        if (isConfirmed) {
          // Transaction confirmed
          final updatedTransaction = transaction.copyWith(
            status: TransactionState.confirmed,
            confirmedAt: DateTime.now(),
          );
          
          _pendingTransactions[hash] = updatedTransaction;
          _confirmedTransactions.add(hash);
          
          if (EnvironmentConfig.enableDetailedLogging) {
            developer.log('Transaction confirmed: $hash', name: 'BlockchainProvider');
          }
          
          // Remove from pending after a delay to show confirmation
          Timer(const Duration(seconds: 5), () {
            _pendingTransactions.remove(hash);
            notifyListeners();
          });
          
          notifyListeners();
        } else {
          // Check if transaction has been pending too long
          final age = DateTime.now().difference(transaction.submittedAt);
          if (age > const Duration(minutes: 10)) {
            // Mark as failed if pending too long
            _pendingTransactions[hash] = transaction.copyWith(
              status: TransactionState.failed,
              error: 'Transaction timeout - not confirmed within 10 minutes',
            );
            
            if (EnvironmentConfig.enableDetailedLogging) {
              developer.log('Transaction timeout: $hash', name: 'BlockchainProvider');
            }
            
            notifyListeners();
          }
        }
      } catch (e) {
        // Mark transaction as failed
        final transaction = _pendingTransactions[hash]!;
        _pendingTransactions[hash] = transaction.copyWith(
          status: TransactionState.failed,
          error: 'Verification failed: $e',
        );
        
        developer.log('Transaction verification failed: $hash - $e', name: 'BlockchainProvider');
        notifyListeners();
      }
    }
  }
  
  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    _transactionMonitorTimer?.cancel();
    _instance = null;
    super.dispose();
  }
}

/// Transaction status tracking
class TransactionStatus {
  final String hash;
  final String? description;
  final DateTime submittedAt;
  final TransactionState status;
  final DateTime? confirmedAt;
  final String? error;
  
  const TransactionStatus({
    required this.hash,
    this.description,
    required this.submittedAt,
    required this.status,
    this.confirmedAt,
    this.error,
  });
  
  TransactionStatus copyWith({
    String? hash,
    String? description,
    DateTime? submittedAt,
    TransactionState? status,
    DateTime? confirmedAt,
    String? error,
  }) {
    return TransactionStatus(
      hash: hash ?? this.hash,
      description: description ?? this.description,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      error: error ?? this.error,
    );
  }
  
  Duration get age => DateTime.now().difference(submittedAt);
  
  bool get isPending => status == TransactionState.pending;
  bool get isConfirmed => status == TransactionState.confirmed;
  bool get isFailed => status == TransactionState.failed;
  
  @override
  String toString() {
    return 'TransactionStatus(hash: $hash, status: $status, age: ${age.inSeconds}s)';
  }
}

/// Transaction state enumeration
enum TransactionState {
  pending,
  confirmed,
  failed,
}