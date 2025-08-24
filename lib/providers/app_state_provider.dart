import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/borrower_model.dart';
import '../models/credit_score_model.dart';
import '../models/loan_model.dart';
import '../services/blockchain_service.dart';
import '../services/credit_scoring_service.dart';
import '../services/demo_user_initialization_service.dart';
import '../utils/constants.dart';
import 'cache_manager.dart';

/// Main application state provider that manages user data, credit scores, and loan applications
/// Provides centralized state management with automatic data refresh and blockchain synchronization
/// Requirements: 2.3, 5.4, 7.4
class AppStateProvider extends ChangeNotifier {
  static AppStateProvider? _instance;
  
  // Services
  final BlockchainService _blockchainService = BlockchainService.instance;
  final CreditScoringService _creditScoringService = CreditScoringService.instance;
  final CacheManager _cacheManager = CacheManager.instance;
  final DemoUserInitializationService _demoUserService = DemoUserInitializationService.instance;
  
  // State variables
  BorrowerModel? _currentBorrower;
  CreditScoreModel? _currentCreditScore;
  final List<LoanModel> _loanApplications = [];
  Map<String, dynamic>? _networkStatus;
  
  // Loading states
  bool _isLoadingBorrower = false;
  bool _isLoadingCreditScore = false;
  final bool _isLoadingLoans = false;
  bool _isLoadingNetworkStatus = false;
  bool _isProcessingLoan = false;
  
  // Error states
  String? _lastError;
  DateTime? _lastErrorTime;
  
  // Cache management
  DateTime? _lastBorrowerUpdate;
  DateTime? _lastCreditScoreUpdate;
  DateTime? _lastNetworkStatusUpdate;
  
  // Auto-refresh configuration
  static const Duration _autoRefreshInterval = Duration(minutes: 2);
  static const Duration _cacheExpiration = Duration(minutes: 5);
  
  // Real-time synchronization
  StreamSubscription<Map<String, dynamic>>? _blockchainSyncSubscription;
  Timer? _autoRefreshTimer;
  
  // Singleton pattern
  static AppStateProvider get instance {
    _instance ??= AppStateProvider._internal();
    return _instance!;
  }
  
  AppStateProvider._internal() {
    _startAutoRefresh();
  }
  
  // Getters
  BorrowerModel? get currentBorrower => _currentBorrower;
  CreditScoreModel? get currentCreditScore => _currentCreditScore;
  List<LoanModel> get loanApplications => List.unmodifiable(_loanApplications);
  Map<String, dynamic>? get networkStatus => _networkStatus;
  
  bool get isLoadingBorrower => _isLoadingBorrower;
  bool get isLoadingCreditScore => _isLoadingCreditScore;
  bool get isLoadingLoans => _isLoadingLoans;
  bool get isLoadingNetworkStatus => _isLoadingNetworkStatus;
  bool get isProcessingLoan => _isProcessingLoan;
  
  String? get lastError => _lastError;
  DateTime? get lastErrorTime => _lastErrorTime;
  
  bool get hasError => _lastError != null;
  bool get isInitialized => _currentBorrower != null;
  bool get isBlockchainConnected => _networkStatus?['isConnected'] == true;
  
  // Data freshness checks
  bool get isBorrowerDataFresh => _lastBorrowerUpdate != null && 
      DateTime.now().difference(_lastBorrowerUpdate!) < _cacheExpiration;
  
  bool get isCreditScoreDataFresh => _lastCreditScoreUpdate != null && 
      DateTime.now().difference(_lastCreditScoreUpdate!) < _cacheExpiration;
  
  bool get isNetworkStatusFresh => _lastNetworkStatusUpdate != null && 
      DateTime.now().difference(_lastNetworkStatusUpdate!) < _cacheExpiration;
  
  /// Initialize the application state with demo user data
  /// Requirements: 2.3, 7.4
  Future<void> initialize({String? nid}) async {
    try {
      _clearError();
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Initializing AppStateProvider...', name: 'AppStateProvider');
      }
      
      // Use demo NID if none provided
      final targetNid = nid ?? DemoUserData.nid;
      
      // Initialize blockchain service first
      await _blockchainService.initialize();
      
      // Check if demo user initialization is required
      if (!_demoUserService.isInitialized) {
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Demo user not initialized, attempting automatic setup...', name: 'AppStateProvider');
        }
        
        // Try to initialize demo user automatically
        final initResult = await _demoUserService.initializeDemoUser();
        if (!initResult.isSuccess) {
          if (EnvironmentConfig.enableDetailedLogging) {
            developer.log('Automatic demo user setup failed: ${initResult.message}', name: 'AppStateProvider');
          }
          // Continue without demo user - will be handled by onboarding flow
        }
      }
      
      // Load initial data in parallel
      await Future.wait([
        loadBorrowerData(targetNid, forceRefresh: true),
        loadNetworkStatus(forceRefresh: true),
      ]);
      
      // Load credit score after borrower data is available
      if (_currentBorrower != null && _currentBorrower!.exists) {
        await loadCreditScore(targetNid, forceRefresh: true);
      }
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('AppStateProvider initialized successfully', name: 'AppStateProvider');
      }
    } catch (e) {
      _setError('Failed to initialize application: $e');
      developer.log('Failed to initialize AppStateProvider: $e', name: 'AppStateProvider');
      rethrow;
    }
  }
  
  /// Load borrower data from blockchain with caching
  /// Requirements: 2.3, 5.4
  Future<void> loadBorrowerData(String nid, {bool forceRefresh = false}) async {
    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      if (isBorrowerDataFresh && _currentBorrower?.nid == nid) {
        return; // Use in-memory cached data
      }
      
      // Try to load from persistent cache
      final cachedBorrower = await _cacheManager.getCachedBorrowerData(nid);
      if (cachedBorrower != null) {
        _currentBorrower = cachedBorrower;
        _lastBorrowerUpdate = DateTime.now();
        notifyListeners();
        
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Loaded borrower data from cache: ${cachedBorrower.name}', name: 'AppStateProvider');
        }
        return;
      }
    }
    
    _isLoadingBorrower = true;
    _clearError();
    notifyListeners();
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Loading borrower data for NID: $nid', name: 'AppStateProvider');
      }
      
      final borrower = await _blockchainService.getBorrowerData(nid);
      
      _currentBorrower = borrower;
      _lastBorrowerUpdate = DateTime.now();
      
      // Cache the data for future use
      await _cacheManager.cacheBorrowerData(nid, borrower);
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Borrower data loaded: ${borrower.name} (${borrower.nid})', name: 'AppStateProvider');
      }
    } catch (e) {
      _setError('Failed to load borrower data: $e');
      developer.log('Failed to load borrower data: $e', name: 'AppStateProvider');
    } finally {
      _isLoadingBorrower = false;
      notifyListeners();
    }
  }
  
  /// Load credit score data with caching and automatic refresh
  /// Requirements: 2.3, 5.4, 7.4
  Future<void> loadCreditScore(String nid, {bool forceRefresh = false, BigInt? monthlyIncome}) async {
    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      if (isCreditScoreDataFresh && _currentCreditScore != null) {
        return; // Use in-memory cached data
      }
      
      // Try to load from persistent cache
      final cachedCreditScore = await _cacheManager.getCachedCreditScoreData(nid);
      if (cachedCreditScore != null) {
        _currentCreditScore = cachedCreditScore;
        _lastCreditScoreUpdate = DateTime.now();
        notifyListeners();
        
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Loaded credit score from cache: ${cachedCreditScore.score}', name: 'AppStateProvider');
        }
        return;
      }
    }
    
    _isLoadingCreditScore = true;
    _clearError();
    notifyListeners();
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Loading credit score for NID: $nid', name: 'AppStateProvider');
      }
      
      // Use default monthly income if not provided
      monthlyIncome ??= BigInt.from(DemoUserData.monthlyIncomeInt);
      
      final creditScore = await _creditScoringService.calculateCreditScore(nid, monthlyIncome: monthlyIncome);
      
      _currentCreditScore = creditScore;
      _lastCreditScoreUpdate = DateTime.now();
      
      // Cache the data for future use
      await _cacheManager.cacheCreditScoreData(nid, creditScore);
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Credit score loaded: ${creditScore.score} (${creditScore.rating})', name: 'AppStateProvider');
      }
    } catch (e) {
      _setError('Failed to load credit score: $e');
      developer.log('Failed to load credit score: $e', name: 'AppStateProvider');
    } finally {
      _isLoadingCreditScore = false;
      notifyListeners();
    }
  }
  
  /// Load network status and blockchain connection health
  /// Requirements: 2.3, 7.4
  Future<void> loadNetworkStatus({bool forceRefresh = false}) async {
    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      if (isNetworkStatusFresh) {
        return; // Use in-memory cached data
      }
      
      // Try to load from persistent cache
      final cachedStatus = await _cacheManager.getCachedNetworkStatus();
      if (cachedStatus != null) {
        _networkStatus = cachedStatus;
        _lastNetworkStatusUpdate = DateTime.now();
        notifyListeners();
        
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Loaded network status from cache', name: 'AppStateProvider');
        }
        return;
      }
    }
    
    _isLoadingNetworkStatus = true;
    notifyListeners();
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Loading network status...', name: 'AppStateProvider');
      }
      
      final status = await _blockchainService.getNetworkStatus();
      
      _networkStatus = status;
      _lastNetworkStatusUpdate = DateTime.now();
      
      // Cache the network status
      await _cacheManager.cacheNetworkStatus(status);
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Network status loaded: Connected=${status['isConnected']}', name: 'AppStateProvider');
      }
    } catch (e) {
      _setError('Failed to load network status: $e');
      developer.log('Failed to load network status: $e', name: 'AppStateProvider');
    } finally {
      _isLoadingNetworkStatus = false;
      notifyListeners();
    }
  }
  
  /// Process a new loan application
  /// Requirements: 4.1, 4.2, 4.3, 7.1
  Future<LoanModel?> processLoanApplication({
    required String nid,
    required BigInt requestedAmount,
    BigInt? monthlyIncome,
    LoanType loanType = LoanType.personal,
  }) async {
    _isProcessingLoan = true;
    _clearError();
    notifyListeners();
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Processing loan application: NID=$nid, Amount=$requestedAmount', name: 'AppStateProvider');
      }
      
      // Use default monthly income if not provided
      monthlyIncome ??= BigInt.from(DemoUserData.monthlyIncomeInt);
      
      // Process loan through blockchain service
      final loanModel = await _blockchainService.processLoanApplication(
        nid: nid,
        requestedAmount: requestedAmount,
        monthlyIncome: monthlyIncome,
        loanType: loanType,
      );
      
      // Add to local loan applications list
      _loanApplications.add(loanModel);
      
      // Refresh borrower and credit score data after loan processing
      await Future.wait([
        loadBorrowerData(nid, forceRefresh: true),
        loadCreditScore(nid, forceRefresh: true, monthlyIncome: monthlyIncome),
      ]);
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Loan application processed successfully: ${loanModel.id}', name: 'AppStateProvider');
      }
      
      return loanModel;
    } catch (e) {
      _setError('Failed to process loan application: $e');
      developer.log('Failed to process loan application: $e', name: 'AppStateProvider');
      return null;
    } finally {
      _isProcessingLoan = false;
      notifyListeners();
    }
  }
  
  /// Add a new borrower to the blockchain
  /// Requirements: 2.2, 7.2
  Future<bool> addBorrowerToBlockchain(BorrowerModel borrower) async {
    _isLoadingBorrower = true;
    _clearError();
    notifyListeners();
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Adding borrower to blockchain: ${borrower.nid}', name: 'AppStateProvider');
      }
      
      final transactionHash = await _blockchainService.addBorrowerToBlockchain(borrower);
      
      // Wait for transaction confirmation
      final isConfirmed = await _blockchainService.verifyTransaction(transactionHash);
      
      if (isConfirmed) {
        // Refresh borrower data after successful addition
        await loadBorrowerData(borrower.nid, forceRefresh: true);
        
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Borrower added successfully: ${borrower.nid}', name: 'AppStateProvider');
        }
        
        return true;
      } else {
        throw Exception('Transaction not confirmed');
      }
    } catch (e) {
      _setError('Failed to add borrower: $e');
      developer.log('Failed to add borrower: $e', name: 'AppStateProvider');
      return false;
    } finally {
      _isLoadingBorrower = false;
      notifyListeners();
    }
  }
  
  /// Initialize demo user through the demo user service
  /// Requirements: 1.4, 2.2, 7.2
  Future<bool> initializeDemoUser({String? customNid}) async {
    _isLoadingBorrower = true;
    _clearError();
    notifyListeners();
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Initializing demo user through service...', name: 'AppStateProvider');
      }
      
      final result = await _demoUserService.initializeDemoUserWithRetry(
        customNid: customNid,
      );
      
      if (result.isSuccess) {
        // Refresh all data after successful initialization
        final targetNid = customNid ?? DemoUserData.nid;
        await Future.wait([
          loadBorrowerData(targetNid, forceRefresh: true),
          loadNetworkStatus(forceRefresh: true),
        ]);
        
        // Load credit score if borrower exists
        if (_currentBorrower != null && _currentBorrower!.exists) {
          await loadCreditScore(targetNid, forceRefresh: true);
        }
        
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Demo user initialized successfully', name: 'AppStateProvider');
        }
        
        return true;
      } else {
        _setError('Demo user initialization failed: ${result.message}');
        return false;
      }
    } catch (e) {
      _setError('Failed to initialize demo user: $e');
      developer.log('Failed to initialize demo user: $e', name: 'AppStateProvider');
      return false;
    } finally {
      _isLoadingBorrower = false;
      notifyListeners();
    }
  }
  
  /// Get demo user initialization status
  /// Requirements: 7.2
  Map<String, dynamic> getDemoUserInitializationStatus() {
    return _demoUserService.getInitializationStatus();
  }
  
  /// Refresh all data from blockchain
  /// Requirements: 5.4, 7.4
  Future<void> refreshAllData({String? nid}) async {
    try {
      _clearError();
      
      final targetNid = nid ?? _currentBorrower?.nid ?? DemoUserData.nid;
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Refreshing all data for NID: $targetNid', name: 'AppStateProvider');
      }
      
      // Refresh all data in parallel
      await Future.wait([
        loadBorrowerData(targetNid, forceRefresh: true),
        loadNetworkStatus(forceRefresh: true),
      ]);
      
      // Refresh credit score if borrower exists
      if (_currentBorrower != null && _currentBorrower!.exists) {
        await loadCreditScore(targetNid, forceRefresh: true);
      }
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('All data refreshed successfully', name: 'AppStateProvider');
      }
    } catch (e) {
      _setError('Failed to refresh data: $e');
      developer.log('Failed to refresh all data: $e', name: 'AppStateProvider');
    }
  }
  
  /// Get loan eligibility assessment
  /// Requirements: 3.3, 4.2
  Future<Map<String, dynamic>?> getLoanEligibilityAssessment({
    required String nid,
    required BigInt requestedAmount,
    BigInt? monthlyIncome,
  }) async {
    try {
      _clearError();
      
      monthlyIncome ??= BigInt.from(DemoUserData.monthlyIncomeInt);
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Getting loan eligibility assessment: NID=$nid, Amount=$requestedAmount', name: 'AppStateProvider');
      }
      
      final assessment = await _creditScoringService.getLoanEligibilityAssessment(
        nid,
        monthlyIncome,
        requestedAmount,
      );
      
      return assessment;
    } catch (e) {
      _setError('Failed to get loan eligibility: $e');
      developer.log('Failed to get loan eligibility assessment: $e', name: 'AppStateProvider');
      return null;
    }
  }
  
  /// Clear all cached data and force refresh
  Future<void> clearCache() async {
    _currentBorrower = null;
    _currentCreditScore = null;
    _loanApplications.clear();
    _networkStatus = null;
    
    _lastBorrowerUpdate = null;
    _lastCreditScoreUpdate = null;
    _lastNetworkStatusUpdate = null;
    
    // Clear service caches
    _creditScoringService.clearCache();
    
    // Clear persistent cache
    await _cacheManager.clearAllCache();
    
    if (EnvironmentConfig.enableDetailedLogging) {
      developer.log('All cache cleared', name: 'AppStateProvider');
    }
    
    notifyListeners();
  }
  
  /// Synchronize data with blockchain and update cache
  /// Requirements: 2.3, 5.4, 7.4
  Future<void> synchronizeWithBlockchain({String? nid}) async {
    try {
      _clearError();
      
      final targetNid = nid ?? _currentBorrower?.nid ?? DemoUserData.nid;
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Synchronizing with blockchain for NID: $targetNid', name: 'AppStateProvider');
      }
      
      // Force refresh all data from blockchain
      await Future.wait([
        loadBorrowerData(targetNid, forceRefresh: true),
        loadNetworkStatus(forceRefresh: true),
      ]);
      
      // Refresh credit score if borrower exists
      if (_currentBorrower != null && _currentBorrower!.exists) {
        await loadCreditScore(targetNid, forceRefresh: true);
      }
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Blockchain synchronization completed', name: 'AppStateProvider');
      }
    } catch (e) {
      _setError('Failed to synchronize with blockchain: $e');
      developer.log('Failed to synchronize with blockchain: $e', name: 'AppStateProvider');
    }
  }
  
  /// Get data freshness status
  /// Requirements: 5.4
  Map<String, dynamic> getDataFreshnessStatus() {
    return {
      'borrowerDataFresh': isBorrowerDataFresh,
      'creditScoreDataFresh': isCreditScoreDataFresh,
      'networkStatusFresh': isNetworkStatusFresh,
      'lastBorrowerUpdate': _lastBorrowerUpdate?.toIso8601String(),
      'lastCreditScoreUpdate': _lastCreditScoreUpdate?.toIso8601String(),
      'lastNetworkStatusUpdate': _lastNetworkStatusUpdate?.toIso8601String(),
      'cacheStatistics': _cacheManager.getCacheStatistics(),
    };
  }
  
  /// Enable or disable real-time synchronization
  /// Requirements: 7.4
  void setRealTimeSyncEnabled(bool enabled) {
    if (enabled) {
      if (_blockchainSyncSubscription == null) {
        _startBlockchainSync();
      }
    } else {
      _stopBlockchainSync();
    }
    
    if (EnvironmentConfig.enableDetailedLogging) {
      developer.log('Real-time sync ${enabled ? 'enabled' : 'disabled'}', name: 'AppStateProvider');
    }
  }
  
  /// Clear error state
  void clearError() {
    _clearError();
    notifyListeners();
  }
  
  // Private helper methods
  
  void _setError(String error) {
    _lastError = error;
    _lastErrorTime = DateTime.now();
  }
  
  void _clearError() {
    _lastError = null;
    _lastErrorTime = null;
  }
  
  /// Start automatic data refresh timer and real-time synchronization
  void _startAutoRefresh() {
    // Auto-refresh every 2 minutes if data is stale
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) async {
      if (_currentBorrower != null && !hasError) {
        try {
          // Only refresh if data is getting stale
          if (!isBorrowerDataFresh || !isCreditScoreDataFresh || !isNetworkStatusFresh) {
            await refreshAllData();
          }
        } catch (e) {
          // Silent fail for auto-refresh to avoid disrupting user experience
          developer.log('Auto-refresh failed: $e', name: 'AppStateProvider');
        }
      }
    });
    
    // Start real-time blockchain synchronization
    _startBlockchainSync();
  }
  
  /// Start real-time blockchain synchronization
  /// Requirements: 7.4
  void _startBlockchainSync() {
    // Listen for blockchain events and updates
    _blockchainSyncSubscription = _blockchainService.getBlockchainEventStream()?.listen(
      (event) async {
        try {
          if (EnvironmentConfig.enableDetailedLogging) {
            developer.log('Blockchain event received: ${event['type']}', name: 'AppStateProvider');
          }
          
          // Handle different types of blockchain events
          switch (event['type']) {
            case 'borrower_updated':
              if (event['nid'] == _currentBorrower?.nid) {
                await loadBorrowerData(event['nid'], forceRefresh: true);
              }
              break;
            case 'credit_score_changed':
              if (event['nid'] == _currentBorrower?.nid) {
                await loadCreditScore(event['nid'], forceRefresh: true);
              }
              break;
            case 'loan_processed':
              if (event['nid'] == _currentBorrower?.nid) {
                await Future.wait([
                  loadBorrowerData(event['nid'], forceRefresh: true),
                  loadCreditScore(event['nid'], forceRefresh: true),
                ]);
              }
              break;
            case 'network_status_changed':
              await loadNetworkStatus(forceRefresh: true);
              break;
          }
        } catch (e) {
          developer.log('Failed to handle blockchain event: $e', name: 'AppStateProvider');
        }
      },
      onError: (error) {
        developer.log('Blockchain sync error: $error', name: 'AppStateProvider');
      },
    );
  }
  
  /// Stop real-time synchronization
  void _stopBlockchainSync() {
    _blockchainSyncSubscription?.cancel();
    _blockchainSyncSubscription = null;
  }
  
  @override
  void dispose() {
    // Cancel timers and subscriptions
    _autoRefreshTimer?.cancel();
    _stopBlockchainSync();
    
    _instance = null;
    super.dispose();
  }
}