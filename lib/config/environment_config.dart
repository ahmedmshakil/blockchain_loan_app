import 'package:flutter/foundation.dart';
import 'blockchain_config.dart';

/// Environment-specific configuration handler
class EnvironmentConfig {
  // Environment types
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';
  
  // Current environment
  static const String currentEnvironment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: development,
  );
  
  // Environment checks
  static bool get isDevelopment => currentEnvironment == development;
  static bool get isStaging => currentEnvironment == staging;
  static bool get isProduction => currentEnvironment == production;
  
  /// Get blockchain configuration based on environment
  static BlockchainEnvironmentConfig get blockchainConfig {
    switch (currentEnvironment) {
      case production:
        return ProductionBlockchainConfig();
      case staging:
        return StagingBlockchainConfig();
      default:
        return DevelopmentBlockchainConfig();
    }
  }
  
  /// Get API configuration based on environment
  static ApiEnvironmentConfig get apiConfig {
    switch (currentEnvironment) {
      case production:
        return ProductionApiConfig();
      case staging:
        return StagingApiConfig();
      default:
        return DevelopmentApiConfig();
    }
  }
  
  /// Get logging configuration
  static LoggingConfig get loggingConfig {
    return LoggingConfig(
      enableDebugLogs: isDevelopment,
      enableInfoLogs: true,
      enableErrorLogs: true,
      enableCrashReporting: isProduction || isStaging,
      logLevel: isDevelopment ? LogLevel.debug : LogLevel.info,
    );
  }
  
  /// Get security configuration
  static SecurityConfig get securityConfig {
    return SecurityConfig(
      enableBiometrics: true,
      requirePinOnStartup: isProduction,
      sessionTimeoutMinutes: isDevelopment ? 60 : 30,
      maxLoginAttempts: 3,
      enableCertificatePinning: isProduction,
    );
  }
  
  /// Initialize environment-specific settings
  static Future<void> initialize() async {
    if (kDebugMode) {
      print('Initializing environment: $currentEnvironment');
      print('Blockchain network: ${blockchainConfig.networkName}');
      print('API base URL: ${apiConfig.baseUrl}');
    }
    
    // Validate blockchain configuration
    try {
      blockchainConfig.validate();
    } catch (e) {
      if (kDebugMode) {
        print('Blockchain configuration validation failed: $e');
      }
      rethrow;
    }
  }
}

/// Abstract base class for blockchain environment configuration
abstract class BlockchainEnvironmentConfig {
  String get networkName;
  int get chainId;
  String get rpcUrl;
  String get contractAddress;
  int get gasLimit;
  int get gasPrice;
  bool get enableLogging;
  
  void validate() {
    if (contractAddress.isEmpty || contractAddress == '0xYOUR_CONTRACT_ADDRESS') {
      throw EnvironmentConfigException('Contract address not configured for $networkName');
    }
    if (rpcUrl.isEmpty || rpcUrl.contains('YOUR_INFURA_PROJECT_ID')) {
      throw EnvironmentConfigException('RPC URL not configured for $networkName');
    }
  }
}

/// Development blockchain configuration (Sepolia testnet)
class DevelopmentBlockchainConfig extends BlockchainEnvironmentConfig {
  @override
  String get networkName => 'Sepolia Testnet';
  
  @override
  int get chainId => 11155111;
  
  @override
  String get rpcUrl => BlockchainConfig.rpcUrl;
  
  @override
  String get contractAddress => BlockchainConfig.contractAddress;
  
  @override
  int get gasLimit => 500000; // Higher for testing
  
  @override
  int get gasPrice => 20000000000; // 20 Gwei
  
  @override
  bool get enableLogging => true;
}

/// Staging blockchain configuration (Goerli testnet)
class StagingBlockchainConfig extends BlockchainEnvironmentConfig {
  @override
  String get networkName => 'Goerli Testnet';
  
  @override
  int get chainId => 5;
  
  @override
  String get rpcUrl => 'https://goerli.infura.io/v3/${BlockchainConfig.infuraProjectId}';
  
  @override
  String get contractAddress => const String.fromEnvironment(
    'STAGING_CONTRACT_ADDRESS',
    defaultValue: '0xSTAGING_CONTRACT_ADDRESS',
  );
  
  @override
  int get gasLimit => 400000;
  
  @override
  int get gasPrice => 15000000000; // 15 Gwei
  
  @override
  bool get enableLogging => true;
}

/// Production blockchain configuration (Ethereum mainnet)
class ProductionBlockchainConfig extends BlockchainEnvironmentConfig {
  @override
  String get networkName => 'Ethereum Mainnet';
  
  @override
  int get chainId => 1;
  
  @override
  String get rpcUrl => 'https://mainnet.infura.io/v3/${BlockchainConfig.infuraProjectId}';
  
  @override
  String get contractAddress => const String.fromEnvironment(
    'PRODUCTION_CONTRACT_ADDRESS',
    defaultValue: '0xPRODUCTION_CONTRACT_ADDRESS',
  );
  
  @override
  int get gasLimit => 300000;
  
  @override
  int get gasPrice => 30000000000; // 30 Gwei
  
  @override
  bool get enableLogging => false;
}

/// Abstract base class for API environment configuration
abstract class ApiEnvironmentConfig {
  String get baseUrl;
  Duration get timeout;
  bool get enableRetry;
  int get maxRetryAttempts;
}

/// Development API configuration
class DevelopmentApiConfig extends ApiEnvironmentConfig {
  @override
  String get baseUrl => 'https://dev-api.bankofiub.com';
  
  @override
  Duration get timeout => const Duration(seconds: 30);
  
  @override
  bool get enableRetry => true;
  
  @override
  int get maxRetryAttempts => 3;
}

/// Staging API configuration
class StagingApiConfig extends ApiEnvironmentConfig {
  @override
  String get baseUrl => 'https://staging-api.bankofiub.com';
  
  @override
  Duration get timeout => const Duration(seconds: 20);
  
  @override
  bool get enableRetry => true;
  
  @override
  int get maxRetryAttempts => 2;
}

/// Production API configuration
class ProductionApiConfig extends ApiEnvironmentConfig {
  @override
  String get baseUrl => 'https://api.bankofiub.com';
  
  @override
  Duration get timeout => const Duration(seconds: 15);
  
  @override
  bool get enableRetry => true;
  
  @override
  int get maxRetryAttempts => 2;
}

/// Logging configuration
class LoggingConfig {
  final bool enableDebugLogs;
  final bool enableInfoLogs;
  final bool enableErrorLogs;
  final bool enableCrashReporting;
  final LogLevel logLevel;
  
  const LoggingConfig({
    required this.enableDebugLogs,
    required this.enableInfoLogs,
    required this.enableErrorLogs,
    required this.enableCrashReporting,
    required this.logLevel,
  });
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Security configuration
class SecurityConfig {
  final bool enableBiometrics;
  final bool requirePinOnStartup;
  final int sessionTimeoutMinutes;
  final int maxLoginAttempts;
  final bool enableCertificatePinning;
  
  const SecurityConfig({
    required this.enableBiometrics,
    required this.requirePinOnStartup,
    required this.sessionTimeoutMinutes,
    required this.maxLoginAttempts,
    required this.enableCertificatePinning,
  });
}

/// Custom exception for environment configuration errors
class EnvironmentConfigException implements Exception {
  final String message;
  
  const EnvironmentConfigException(this.message);
  
  @override
  String toString() => 'EnvironmentConfigException: $message';
}