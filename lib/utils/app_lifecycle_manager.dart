import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:developer' as developer;
import 'performance_utils.dart';

/// Manages application lifecycle and memory optimization
class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  static AppLifecycleManager get instance => _instance;

  bool _isInitialized = false;
  
  /// Check if the lifecycle manager is initialized
  bool get isInitialized => _isInitialized;
  AppLifecycleState? _lastLifecycleState;

  /// Initialize the lifecycle manager
  void initialize() {
    if (_isInitialized) return;
    
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    
    if (kDebugMode) {
      developer.log('AppLifecycleManager initialized', name: 'AppLifecycleManager');
    }
  }

  /// Dispose the lifecycle manager
  void dispose() {
    if (!_isInitialized) return;
    
    WidgetsBinding.instance.removeObserver(this);
    PerformanceUtils.dispose();
    _isInitialized = false;
    
    if (kDebugMode) {
      developer.log('AppLifecycleManager disposed', name: 'AppLifecycleManager');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (kDebugMode) {
      developer.log('App lifecycle changed to: $state', name: 'AppLifecycleManager');
    }
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
    
    _lastLifecycleState = state;
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    
    if (kDebugMode) {
      developer.log('Memory pressure detected - performing cleanup', name: 'AppLifecycleManager');
    }
    
    // Perform aggressive memory cleanup
    PerformanceUtils.performMemoryCleanup();
    
    // Clear image cache
    PerformanceUtils.optimizeImageCache();
    
    // Force garbage collection in debug mode
    if (kDebugMode) {
      developer.log('Memory cleanup completed', name: 'AppLifecycleManager');
    }
  }

  void _onAppResumed() {
    // App is now visible and responding to user input
    if (kDebugMode) {
      developer.log('App resumed - refreshing data if needed', name: 'AppLifecycleManager');
    }
    
    // Refresh critical data if app was paused for a long time
    if (_lastLifecycleState == AppLifecycleState.paused) {
      _refreshCriticalData();
    }
  }

  void _onAppPaused() {
    // App is not currently visible to the user
    if (kDebugMode) {
      developer.log('App paused - performing light cleanup', name: 'AppLifecycleManager');
    }
    
    // Perform light memory cleanup
    PerformanceUtils.clearAllCache();
  }

  void _onAppInactive() {
    // App is in an inactive state and not receiving user input
    if (kDebugMode) {
      developer.log('App inactive', name: 'AppLifecycleManager');
    }
  }

  void _onAppDetached() {
    // App is still hosted on a flutter engine but is detached from any host views
    if (kDebugMode) {
      developer.log('App detached - performing full cleanup', name: 'AppLifecycleManager');
    }
    
    // Perform full cleanup
    PerformanceUtils.performMemoryCleanup();
  }

  void _onAppHidden() {
    // App is hidden from the user
    if (kDebugMode) {
      developer.log('App hidden', name: 'AppLifecycleManager');
    }
  }

  Future<void> _refreshCriticalData() async {
    try {
      // This would typically refresh blockchain connection, user data, etc.
      await PerformanceUtils.preloadCriticalData();
      
      if (kDebugMode) {
        developer.log('Critical data refreshed', name: 'AppLifecycleManager');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to refresh critical data: $e', name: 'AppLifecycleManager');
      }
    }
  }

  /// Get current lifecycle state
  AppLifecycleState? get currentState => _lastLifecycleState;

  /// Check if app is in foreground
  bool get isInForeground => 
      _lastLifecycleState == AppLifecycleState.resumed;

  /// Check if app is in background
  bool get isInBackground => 
      _lastLifecycleState == AppLifecycleState.paused ||
      _lastLifecycleState == AppLifecycleState.hidden;
}