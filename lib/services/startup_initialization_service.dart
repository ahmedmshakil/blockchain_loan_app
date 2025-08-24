import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../services/demo_user_initialization_service.dart';
import '../services/blockchain_service.dart';
import '../utils/constants.dart';
import '../config/app_config.dart';

/// Service for handling application startup initialization
/// Manages automatic demo user setup and blockchain initialization
/// Requirements: 1.4, 2.2, 7.2
class StartupInitializationService {
  static StartupInitializationService? _instance;
  
  final DemoUserInitializationService _demoUserService = DemoUserInitializationService.instance;
  final BlockchainService _blockchainService = BlockchainService.instance;
  
  // Initialization state
  bool _isStartupComplete = false;
  bool _isInitializing = false;
  StartupPhase _currentPhase = StartupPhase.notStarted;
  String? _initializationError;
  DateTime? _startupStartTime;
  DateTime? _startupEndTime;
  
  // Configuration
  static const Duration startupTimeout = Duration(minutes: 3);
  static const bool enableAutoInitialization = true;
  static const bool enableFallbackMode = true;
  
  // Singleton pattern
  static StartupInitializationService get instance {
    _instance ??= StartupInitializationService._internal();
    return _instance!;
  }
  
  StartupInitializationService._internal();
  
  // Getters
  bool get isStartupComplete => _isStartupComplete;
  bool get isInitializing => _isInitializing;
  StartupPhase get currentPhase => _currentPhase;
  String? get initializationError => _initializationError;
  DateTime? get startupStartTime => _startupStartTime;
  DateTime? get startupEndTime => _startupEndTime;
  Duration? get startupDuration => _startupStartTime != null && _startupEndTime != null
      ? _startupEndTime!.difference(_startupStartTime!)
      : null;
  
  /// Perform complete application startup initialization
  /// Requirements: 1.4, 2.2, 7.2
  Future<StartupResult> performStartupInitialization({
    bool forceReinitialize = false,
    bool enableUserOnboarding = true,
  }) async {
    if (_isInitializing) {
      return StartupResult.inProgress(_currentPhase);
    }
    
    if (_isStartupComplete && !forceReinitialize) {
      return StartupResult.success('Startup already completed');
    }
    
    _isInitializing = true;
    _initializationError = null;
    _startupStartTime = DateTime.now();
    _startupEndTime = null;
    
    try {
      if (kDebugMode) {
        developer.log('Starting application initialization...', name: 'StartupInitializationService');
      }
      
      // Phase 1: Configuration Validation
      final configResult = await _validateConfiguration();
      if (!configResult.isSuccess) {
        return configResult;
      }
      
      // Phase 2: Blockchain Connection
      final blockchainResult = await _initializeBlockchainConnection();
      if (!blockchainResult.isSuccess) {
        if (enableFallbackMode) {
          return _handleFallbackMode('Blockchain connection failed');
        }
        return blockchainResult;
      }
      
      // Phase 3: Demo User Setup
      final demoUserResult = await _initializeDemoUser();
      if (!demoUserResult.isSuccess) {
        if (enableFallbackMode) {
          return _handleFallbackMode('Demo user initialization failed');
        }
        return demoUserResult;
      }
      
      // Phase 4: Final Verification
      final verificationResult = await _performFinalVerification();
      if (!verificationResult.isSuccess) {
        if (enableFallbackMode) {
          return _handleFallbackMode('Final verification failed');
        }
        return verificationResult;
      }
      
      // Startup completed successfully
      _isStartupComplete = true;
      _currentPhase = StartupPhase.completed;
      _startupEndTime = DateTime.now();
      
      if (kDebugMode) {
        final duration = startupDuration?.inMilliseconds ?? 0;
        developer.log('Startup initialization completed in ${duration}ms', name: 'StartupInitializationService');
      }
      
      return StartupResult.success('Startup initialization completed successfully');
      
    } catch (e) {
      _initializationError = e.toString();
      developer.log('Startup initialization failed: $e', name: 'StartupInitializationService');
      
      if (enableFallbackMode) {
        return _handleFallbackMode('Unexpected error: $e');
      }
      
      return StartupResult.failure('Startup initialization failed: $e');
    } finally {
      _isInitializing = false;
      _startupEndTime ??= DateTime.now();
    }
  }
  
  /// Check if user onboarding is required
  /// Requirements: 7.2
  bool isUserOnboardingRequired() {
    // Check if demo user is already initialized
    if (_demoUserService.isInitialized) {
      return false;
    }
    
    // Check if there were initialization errors that require user intervention
    if (_initializationError != null) {
      return true;
    }
    
    // Check if startup is not complete
    return !_isStartupComplete;
  }
  
  /// Get startup status for UI display
  /// Requirements: 7.2
  Map<String, dynamic> getStartupStatus() {
    return {
      'isComplete': _isStartupComplete,
      'isInitializing': _isInitializing,
      'currentPhase': _currentPhase.name,
      'error': _initializationError,
      'startTime': _startupStartTime?.toIso8601String(),
      'endTime': _startupEndTime?.toIso8601String(),
      'duration': startupDuration?.inMilliseconds,
      'demoUserInitialized': _demoUserService.isInitialized,
      'onboardingRequired': isUserOnboardingRequired(),
      'fallbackModeActive': _currentPhase == StartupPhase.fallbackMode,
    };
  }
  
  /// Reset startup state (for testing)
  void resetStartupState() {
    _isStartupComplete = false;
    _isInitializing = false;
    _currentPhase = StartupPhase.notStarted;
    _initializationError = null;
    _startupStartTime = null;
    _startupEndTime = null;
    
    // Reset demo user service state
    _demoUserService.resetInitializationState();
    
    if (kDebugMode) {
      developer.log('Startup state reset', name: 'StartupInitializationService');
    }
  }
  
  /// Get initialization guidance for users
  /// Requirements: 7.2
  List<String> getInitializationGuidance() {
    final guidance = <String>[];
    
    switch (_currentPhase) {
      case StartupPhase.notStarted:
        guidance.add('Application initialization has not started');
        guidance.add('Tap "Start Setup" to begin blockchain initialization');
        break;
        
      case StartupPhase.configurationValidation:
        guidance.add('Validating application configuration...');
        guidance.add('This should complete quickly');
        break;
        
      case StartupPhase.blockchainConnection:
        guidance.add('Connecting to Sepolia blockchain...');
        guidance.add('Ensure you have internet connection');
        guidance.add('This may take 30-60 seconds');
        break;
        
      case StartupPhase.demoUserInitialization:
        guidance.add('Setting up demo user on blockchain...');
        guidance.add('Creating borrower profile with credit history');
        guidance.add('This requires a blockchain transaction');
        break;
        
      case StartupPhase.finalVerification:
        guidance.add('Verifying initialization...');
        guidance.add('Confirming all systems are ready');
        break;
        
      case StartupPhase.completed:
        guidance.add('Initialization completed successfully!');
        guidance.add('All blockchain features are available');
        break;
        
      case StartupPhase.fallbackMode:
        guidance.add('Running in fallback mode');
        guidance.add('Some blockchain features may be limited');
        guidance.add('You can retry full initialization later');
        break;
        
      case StartupPhase.failed:
        guidance.add('Initialization failed');
        if (_initializationError != null) {
          guidance.add('Error: $_initializationError');
        }
        guidance.add('You can retry or continue in demo mode');
        break;
    }
    
    return guidance;
  }
  
  // Private helper methods
  
  /// Validate application configuration
  Future<StartupResult> _validateConfiguration() async {
    _currentPhase = StartupPhase.configurationValidation;
    
    try {
      if (kDebugMode) {
        developer.log('Validating configuration...', name: 'StartupInitializationService');
      }
      
      // Validate app configuration
      if (!AppConfig.isInitialized) {
        await AppConfig.initialize();
      }
      
      // Validate all configurations
      final isValid = await AppConfig.validateConfigurations();
      if (!isValid) {
        return StartupResult.failure('Configuration validation failed');
      }
      
      return StartupResult.success('Configuration validated');
    } catch (e) {
      return StartupResult.failure('Configuration validation error: $e');
    }
  }
  
  /// Initialize blockchain connection
  Future<StartupResult> _initializeBlockchainConnection() async {
    _currentPhase = StartupPhase.blockchainConnection;
    
    try {
      if (kDebugMode) {
        developer.log('Initializing blockchain connection...', name: 'StartupInitializationService');
      }
      
      await _blockchainService.initialize();
      
      // Verify network connection
      final networkStatus = await _blockchainService.getNetworkStatus();
      if (networkStatus['isConnected'] != true) {
        return StartupResult.failure('Blockchain network not accessible');
      }
      
      return StartupResult.success('Blockchain connection established');
    } catch (e) {
      return StartupResult.failure('Blockchain connection failed: $e');
    }
  }
  
  /// Initialize demo user
  Future<StartupResult> _initializeDemoUser() async {
    _currentPhase = StartupPhase.demoUserInitialization;
    
    try {
      if (kDebugMode) {
        developer.log('Initializing demo user...', name: 'StartupInitializationService');
      }
      
      final result = await _demoUserService.initializeDemoUserWithRetry();
      
      if (result.isSuccess) {
        return StartupResult.success('Demo user initialized');
      } else {
        return StartupResult.failure(result.message);
      }
    } catch (e) {
      return StartupResult.failure('Demo user initialization failed: $e');
    }
  }
  
  /// Perform final verification
  Future<StartupResult> _performFinalVerification() async {
    _currentPhase = StartupPhase.finalVerification;
    
    try {
      if (kDebugMode) {
        developer.log('Performing final verification...', name: 'StartupInitializationService');
      }
      
      // Verify demo user exists on blockchain
      final borrower = await _blockchainService.getBorrowerData(DemoUserData.nid);
      if (!borrower.exists) {
        return StartupResult.failure('Demo user not found on blockchain');
      }
      
      // Verify data integrity
      if (borrower.name != DemoUserData.name) {
        return StartupResult.failure('Demo user data mismatch');
      }
      
      return StartupResult.success('Final verification completed');
    } catch (e) {
      return StartupResult.failure('Final verification failed: $e');
    }
  }
  
  /// Handle fallback mode when initialization fails
  StartupResult _handleFallbackMode(String reason) {
    _currentPhase = StartupPhase.fallbackMode;
    _isStartupComplete = true; // Mark as complete but in fallback mode
    
    if (kDebugMode) {
      developer.log('Entering fallback mode: $reason', name: 'StartupInitializationService');
    }
    
    return StartupResult.fallback('Running in fallback mode: $reason');
  }
}

/// Startup phases for tracking initialization progress
enum StartupPhase {
  notStarted,
  configurationValidation,
  blockchainConnection,
  demoUserInitialization,
  finalVerification,
  completed,
  fallbackMode,
  failed,
}

/// Result class for startup operations
class StartupResult {
  final bool isSuccess;
  final String message;
  final StartupPhase? phase;
  final bool isFallbackMode;
  final dynamic data;
  
  const StartupResult._({
    required this.isSuccess,
    required this.message,
    this.phase,
    this.isFallbackMode = false,
    this.data,
  });
  
  factory StartupResult.success(String message, {dynamic data}) {
    return StartupResult._(
      isSuccess: true,
      message: message,
      data: data,
    );
  }
  
  factory StartupResult.failure(String message, {StartupPhase? phase}) {
    return StartupResult._(
      isSuccess: false,
      message: message,
      phase: phase,
    );
  }
  
  factory StartupResult.fallback(String message) {
    return StartupResult._(
      isSuccess: true,
      message: message,
      isFallbackMode: true,
    );
  }
  
  factory StartupResult.inProgress(StartupPhase phase) {
    return StartupResult._(
      isSuccess: false,
      message: 'Initialization in progress',
      phase: phase,
    );
  }
  
  @override
  String toString() {
    return 'StartupResult(success: $isSuccess, message: $message, phase: $phase, fallback: $isFallbackMode)';
  }
}