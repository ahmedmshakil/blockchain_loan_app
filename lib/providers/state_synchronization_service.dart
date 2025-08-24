import 'dart:async';
import 'dart:developer' as developer;
import '../services/blockchain_service.dart';
import '../utils/constants.dart';
import 'app_state_provider.dart';
import 'blockchain_provider.dart';
import 'loan_provider.dart';
import 'cache_manager.dart';

/// Service for coordinating real-time data synchronization across providers
/// Manages automatic refresh, blockchain event handling, and cache invalidation
/// Requirements: 2.3, 5.4, 7.4
class StateSynchronizationService {
  static StateSynchronizationService? _instance;
  
  // Services and providers
  final BlockchainService _blockchainService = BlockchainService.instance;
  AppStateProvider? _appStateProvider;
  BlockchainProvider? _blockchainProvider;
  LoanProvider? _loanProvider;
  CacheManager? _cacheManager;
  
  // Synchronization state
  bool _isInitialized = false;
  bool _isSyncEnabled = true;
  
  // Timers and subscriptions
  Timer? _periodicSyncTimer;
  StreamSubscription<Map<String, dynamic>>? _blockchainEventSubscription;
  
  // Sync configuration
  static const Duration _syncInterval = Duration(minutes: 3);
  
  // Event tracking
  final List<Map<String, dynamic>> _recentEvents = [];
  static const int _maxRecentEvents = 50;
  
  // Singleton pattern
  static StateSynchronizationService get instance {
    _instance ??= StateSynchronizationService._internal();
    return _instance!;
  }
  
  StateSynchronizationService._internal();
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSyncEnabled => _isSyncEnabled;
  List<Map<String, dynamic>> get recentEvents => List.unmodifiable(_recentEvents);
  
  /// Initialize the synchronization service with provider references
  /// Requirements: 2.3, 7.4
  Future<void> initialize({
    required AppStateProvider appStateProvider,
    required BlockchainProvider blockchainProvider,
    required LoanProvider loanProvider,
    required CacheManager cacheManager,
  }) async {
    if (_isInitialized) return;
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Initializing StateSynchronizationService...', name: 'StateSynchronizationService');
      }
      
      // Store provider references
      _appStateProvider = appStateProvider;
      _blockchainProvider = blockchainProvider;
      _loanProvider = loanProvider;
      _cacheManager = cacheManager;
      
      // Start synchronization services
      await _startPeriodicSync();
      await _startBlockchainEventListener();
      
      _isInitialized = true;
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('StateSynchronizationService initialized successfully', name: 'StateSynchronizationService');
      }
    } catch (e) {
      developer.log('Failed to initialize StateSynchronizationService: $e', name: 'StateSynchronizationService');
      rethrow;
    }
  }
  
  /// Enable or disable synchronization
  /// Requirements: 7.4
  void setSyncEnabled(bool enabled) {
    _isSyncEnabled = enabled;
    
    if (enabled) {
      _startPeriodicSync();
      _startBlockchainEventListener();
    } else {
      _stopPeriodicSync();
      _stopBlockchainEventListener();
    }
    
    if (EnvironmentConfig.enableDetailedLogging) {
      developer.log('Synchronization ${enabled ? 'enabled' : 'disabled'}', name: 'StateSynchronizationService');
    }
  }
  
  /// Trigger immediate synchronization of all data
  /// Requirements: 2.3, 5.4, 7.4
  Future<void> syncAllData({bool forceRefresh = false}) async {
    if (!_isInitialized || !_isSyncEnabled) return;
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Starting full data synchronization...', name: 'StateSynchronizationService');
      }
      
      // Sync blockchain connection status first
      await _blockchainProvider?.checkConnection();
      
      // Only proceed if blockchain is connected
      if (_blockchainProvider?.isConnected == true) {
        // Sync app state data
        await _appStateProvider?.refreshAllData();
        
        // Sync loan data if needed
        if (_loanProvider?.hasActiveLoans == true) {
          final currentNid = _appStateProvider?.currentBorrower?.nid;
          if (currentNid != null) {
            await _loanProvider?.loadLoanHistory(currentNid);
          }
        }
      }
      
      _addEvent({
        'type': 'full_sync_completed',
        'timestamp': DateTime.now().toIso8601String(),
        'forceRefresh': forceRefresh,
        'success': true,
      });
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Full data synchronization completed', name: 'StateSynchronizationService');
      }
    } catch (e) {
      _addEvent({
        'type': 'full_sync_failed',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      });
      
      developer.log('Failed to sync all data: $e', name: 'StateSynchronizationService');
    }
  }
  
  /// Handle specific data invalidation and refresh
  /// Requirements: 5.4
  Future<void> invalidateAndRefresh({
    String? nid,
    bool refreshBorrower = false,
    bool refreshCreditScore = false,
    bool refreshLoans = false,
    bool refreshNetworkStatus = false,
  }) async {
    if (!_isInitialized || !_isSyncEnabled) return;
    
    try {
      final targetNid = nid ?? _appStateProvider?.currentBorrower?.nid;
      if (targetNid == null) return;
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Invalidating and refreshing data for NID: $targetNid', name: 'StateSynchronizationService');
      }
      
      // Clear relevant cache entries
      await _cacheManager?.clearCacheForNid(targetNid);
      
      // Refresh specific data types
      final futures = <Future>[];
      
      if (refreshBorrower) {
        futures.add(_appStateProvider?.loadBorrowerData(targetNid, forceRefresh: true) ?? Future.value());
      }
      
      if (refreshCreditScore) {
        futures.add(_appStateProvider?.loadCreditScore(targetNid, forceRefresh: true) ?? Future.value());
      }
      
      if (refreshLoans) {
        futures.add(_loanProvider?.loadLoanHistory(targetNid) ?? Future.value());
      }
      
      if (refreshNetworkStatus) {
        futures.add(_appStateProvider?.loadNetworkStatus(forceRefresh: true) ?? Future.value());
      }
      
      // Wait for all refresh operations to complete
      await Future.wait(futures);
      
      _addEvent({
        'type': 'selective_refresh_completed',
        'timestamp': DateTime.now().toIso8601String(),
        'nid': targetNid,
        'refreshTypes': {
          'borrower': refreshBorrower,
          'creditScore': refreshCreditScore,
          'loans': refreshLoans,
          'networkStatus': refreshNetworkStatus,
        },
      });
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Selective data refresh completed for NID: $targetNid', name: 'StateSynchronizationService');
      }
    } catch (e) {
      developer.log('Failed to invalidate and refresh data: $e', name: 'StateSynchronizationService');
    }
  }
  
  /// Get synchronization statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'isInitialized': _isInitialized,
      'isSyncEnabled': _isSyncEnabled,
      'recentEventsCount': _recentEvents.length,
      'lastSyncEvent': _recentEvents.isNotEmpty ? _recentEvents.last : null,
      'cacheStatistics': _cacheManager?.getCacheStatistics(),
      'dataFreshness': _appStateProvider?.getDataFreshnessStatus(),
    };
  }
  
  // Private helper methods
  
  /// Start periodic synchronization timer
  Future<void> _startPeriodicSync() async {
    _stopPeriodicSync(); // Stop existing timer if any
    
    if (!_isSyncEnabled) return;
    
    _periodicSyncTimer = Timer.periodic(_syncInterval, (timer) async {
      if (_isSyncEnabled && _blockchainProvider?.isConnected == true) {
        await syncAllData();
      }
    });
    
    if (EnvironmentConfig.enableDetailedLogging) {
      developer.log('Periodic sync started (interval: ${_syncInterval.inMinutes} minutes)', name: 'StateSynchronizationService');
    }
  }
  
  /// Stop periodic synchronization timer
  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }
  
  /// Start listening to blockchain events
  Future<void> _startBlockchainEventListener() async {
    _stopBlockchainEventListener(); // Stop existing listener if any
    
    if (!_isSyncEnabled) return;
    
    try {
      final eventStream = _blockchainService.getBlockchainEventStream();
      if (eventStream != null) {
        _blockchainEventSubscription = eventStream.listen(
          (event) => _handleBlockchainEvent(event),
          onError: (error) {
            developer.log('Blockchain event listener error: $error', name: 'StateSynchronizationService');
          },
        );
        
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Blockchain event listener started', name: 'StateSynchronizationService');
        }
      }
    } catch (e) {
      developer.log('Failed to start blockchain event listener: $e', name: 'StateSynchronizationService');
    }
  }
  
  /// Stop blockchain event listener
  void _stopBlockchainEventListener() {
    _blockchainEventSubscription?.cancel();
    _blockchainEventSubscription = null;
  }
  
  /// Handle incoming blockchain events
  Future<void> _handleBlockchainEvent(Map<String, dynamic> event) async {
    try {
      _addEvent(event);
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Handling blockchain event: ${event['type']}', name: 'StateSynchronizationService');
      }
      
      switch (event['type']) {
        case 'borrower_updated':
          await invalidateAndRefresh(
            nid: event['nid'],
            refreshBorrower: true,
            refreshCreditScore: true,
          );
          break;
          
        case 'credit_score_changed':
          await invalidateAndRefresh(
            nid: event['nid'],
            refreshCreditScore: true,
          );
          break;
          
        case 'loan_processed':
          await invalidateAndRefresh(
            nid: event['nid'],
            refreshBorrower: true,
            refreshCreditScore: true,
            refreshLoans: true,
          );
          break;
          
        case 'network_status_changed':
          await invalidateAndRefresh(
            refreshNetworkStatus: true,
          );
          break;
          
        default:
          if (EnvironmentConfig.enableDetailedLogging) {
            developer.log('Unknown blockchain event type: ${event['type']}', name: 'StateSynchronizationService');
          }
      }
    } catch (e) {
      developer.log('Failed to handle blockchain event: $e', name: 'StateSynchronizationService');
    }
  }
  
  /// Add event to recent events list
  void _addEvent(Map<String, dynamic> event) {
    _recentEvents.add(event);
    
    // Keep only the most recent events
    if (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeAt(0);
    }
  }
  
  /// Dispose resources and cleanup
  void dispose() {
    _stopPeriodicSync();
    _stopBlockchainEventListener();
    
    _appStateProvider = null;
    _blockchainProvider = null;
    _loanProvider = null;
    _cacheManager = null;
    
    _isInitialized = false;
    _instance = null;
  }
}