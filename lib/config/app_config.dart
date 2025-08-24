import 'package:flutter/foundation.dart';
import 'blockchain_config.dart';
import 'environment_config.dart';
import 'secure_storage_config.dart';

/// Main application configuration manager
class AppConfig {
  static bool _initialized = false;
  
  /// Initialize all application configurations
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      if (kDebugMode) {
        print('Initializing AppConfig...');
      }
      
      // Initialize environment configuration
      await EnvironmentConfig.initialize();
      
      // Initialize secure storage
      final storageInitialized = await SecureStorageConfig.initialize();
      if (!storageInitialized) {
        throw ConfigurationException('Failed to initialize secure storage');
      }
      
      // Validate blockchain configuration
      if (!BlockchainConfig.validateConfiguration()) {
        throw ConfigurationException('Invalid blockchain configuration');
      }
      
      _initialized = true;
      
      if (kDebugMode) {
        print('AppConfig initialized successfully');
        await _logConfigurationSummary();
      }
    } catch (e) {
      if (kDebugMode) {
        print('AppConfig initialization failed: $e');
      }
      rethrow;
    }
  }
  
  /// Check if configuration is initialized
  static bool get isInitialized => _initialized;
  
  /// Get current configuration summary
  static Map<String, dynamic> getConfigurationSummary() {
    final blockchainConfig = EnvironmentConfig.blockchainConfig;
    final apiConfig = EnvironmentConfig.apiConfig;
    final loggingConfig = EnvironmentConfig.loggingConfig;
    final securityConfig = EnvironmentConfig.securityConfig;
    
    return {
      'environment': EnvironmentConfig.currentEnvironment,
      'blockchain': {
        'network': blockchainConfig.networkName,
        'chainId': blockchainConfig.chainId,
        'gasLimit': blockchainConfig.gasLimit,
        'gasPrice': blockchainConfig.gasPrice,
        'loggingEnabled': blockchainConfig.enableLogging,
      },
      'api': {
        'baseUrl': apiConfig.baseUrl,
        'timeout': apiConfig.timeout.inSeconds,
        'retryEnabled': apiConfig.enableRetry,
        'maxRetries': apiConfig.maxRetryAttempts,
      },
      'logging': {
        'debugLogs': loggingConfig.enableDebugLogs,
        'infoLogs': loggingConfig.enableInfoLogs,
        'errorLogs': loggingConfig.enableErrorLogs,
        'crashReporting': loggingConfig.enableCrashReporting,
        'logLevel': loggingConfig.logLevel.name,
      },
      'security': {
        'biometrics': securityConfig.enableBiometrics,
        'requirePin': securityConfig.requirePinOnStartup,
        'sessionTimeout': securityConfig.sessionTimeoutMinutes,
        'maxLoginAttempts': securityConfig.maxLoginAttempts,
        'certificatePinning': securityConfig.enableCertificatePinning,
      },
    };
  }
  
  /// Reset configuration (for testing purposes)
  static void reset() {
    _initialized = false;
  }
  
  /// Log configuration summary (debug mode only)
  static Future<void> _logConfigurationSummary() async {
    if (!kDebugMode) return;
    
    final summary = getConfigurationSummary();
    print('=== Configuration Summary ===');
    print('Environment: ${summary['environment']}');
    print('Blockchain Network: ${summary['blockchain']['network']}');
    print('Chain ID: ${summary['blockchain']['chainId']}');
    print('API Base URL: ${summary['api']['baseUrl']}');
    print('Logging Level: ${summary['logging']['logLevel']}');
    print('Security - Biometrics: ${summary['security']['biometrics']}');
    print('Security - Session Timeout: ${summary['security']['sessionTimeout']} minutes');
    print('============================');
  }
  
  /// Validate all configurations
  static Future<bool> validateConfigurations() async {
    try {
      // Validate blockchain configuration
      BlockchainConfig.validateConfiguration();
      
      // Validate environment configuration
      EnvironmentConfig.blockchainConfig.validate();
      
      // Test secure storage
      final storageWorking = await SecureStorageConfig.initialize();
      if (!storageWorking) {
        throw ConfigurationException('Secure storage validation failed');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Configuration validation failed: $e');
      }
      return false;
    }
  }
  
  /// Get blockchain configuration for current environment
  static BlockchainEnvironmentConfig get blockchainConfig => 
      EnvironmentConfig.blockchainConfig;
  
  /// Get API configuration for current environment
  static ApiEnvironmentConfig get apiConfig => 
      EnvironmentConfig.apiConfig;
  
  /// Get logging configuration
  static LoggingConfig get loggingConfig => 
      EnvironmentConfig.loggingConfig;
  
  /// Get security configuration
  static SecurityConfig get securityConfig => 
      EnvironmentConfig.securityConfig;
}

/// Custom exception for configuration errors
class ConfigurationException implements Exception {
  final String message;
  
  const ConfigurationException(this.message);
  
  @override
  String toString() => 'ConfigurationException: $message';
}