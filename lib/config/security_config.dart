import 'package:flutter/foundation.dart';
import 'secure_storage_config.dart';
import 'network_security_config.dart';
import '../utils/memory_manager.dart';
import '../security/security_audit.dart';

/// Centralized security configuration manager
class SecurityConfig {
  static SecurityConfig? _instance;
  static SecurityConfig get instance => _instance ??= SecurityConfig._internal();
  SecurityConfig._internal();
  
  bool _isInitialized = false;
  SecurityAuditReport? _lastAuditReport;
  
  /// Security configuration settings
  static const SecuritySettings _settings = SecuritySettings(
    enableSecureStorage: true,
    enableCertificatePinning: true,
    enableInputValidation: true,
    enableMemoryManagement: true,
    enableSecurityAudit: true,
    enableTransactionLogging: true,
    enableBiometricAuth: false, // Disabled by default
    enableRootDetection: true,
    maxLoginAttempts: 3,
    sessionTimeoutMinutes: 30,
    auditIntervalHours: 24,
  );
  
  /// Initialize all security components
  Future<SecurityInitializationResult> initialize() async {
    if (_isInitialized) {
      return SecurityInitializationResult(
        success: true,
        message: 'Security already initialized',
        details: {},
      );
    }
    
    final results = <String, bool>{};
    final errors = <String>[];
    
    try {
      if (kDebugMode) {
        print('SecurityConfig: Initializing security components...');
      }
      
      // Initialize secure storage
      if (_settings.enableSecureStorage) {
        try {
          final storageResult = await SecureStorageConfig.initialize();
          results['secure_storage'] = storageResult;
          if (!storageResult) {
            errors.add('Secure storage initialization failed');
          }
        } catch (e) {
          results['secure_storage'] = false;
          errors.add('Secure storage error: $e');
        }
      }
      
      // Initialize network security
      if (_settings.enableCertificatePinning) {
        try {
          await NetworkSecurityConfig.initialize();
          results['network_security'] = true;
        } catch (e) {
          results['network_security'] = false;
          errors.add('Network security error: $e');
        }
      }
      
      // Initialize memory management
      if (_settings.enableMemoryManagement) {
        try {
          MemoryManager().monitorMemoryPressure();
          results['memory_management'] = true;
        } catch (e) {
          results['memory_management'] = false;
          errors.add('Memory management error: $e');
        }
      }
      
      // Initialize security audit
      if (_settings.enableSecurityAudit) {
        try {
          await SecurityAudit.initialize();
          results['security_audit'] = true;
        } catch (e) {
          results['security_audit'] = false;
          errors.add('Security audit error: $e');
        }
      }
      
      _isInitialized = errors.isEmpty;
      
      if (kDebugMode) {
        print('SecurityConfig: Initialization ${_isInitialized ? 'completed' : 'failed'}');
        if (errors.isNotEmpty) {
          print('SecurityConfig: Errors: ${errors.join(', ')}');
        }
      }
      
      return SecurityInitializationResult(
        success: _isInitialized,
        message: _isInitialized 
            ? 'Security initialization completed successfully'
            : 'Security initialization completed with errors: ${errors.join(', ')}',
        details: results,
      );
      
    } catch (e) {
      _isInitialized = false;
      return SecurityInitializationResult(
        success: false,
        message: 'Security initialization failed: $e',
        details: results,
      );
    }
  }
  
  /// Run comprehensive security audit
  Future<SecurityAuditReport> runSecurityAudit() async {
    if (!_settings.enableSecurityAudit) {
      throw StateError('Security audit is disabled');
    }
    
    try {
      _lastAuditReport = await SecurityAudit.runCompleteAudit();
      
      if (kDebugMode) {
        print('SecurityConfig: Security audit completed');
        print('SecurityConfig: Security score: ${_lastAuditReport!.securityScore}/100');
        
        if (_lastAuditReport!.failedChecks.isNotEmpty) {
          print('SecurityConfig: Failed checks: ${_lastAuditReport!.failedChecks.length}');
        }
        
        if (_lastAuditReport!.detectedVulnerabilities.isNotEmpty) {
          print('SecurityConfig: Vulnerabilities detected: ${_lastAuditReport!.detectedVulnerabilities.length}');
        }
      }
      
      return _lastAuditReport!;
    } catch (e) {
      if (kDebugMode) {
        print('SecurityConfig: Security audit failed: $e');
      }
      rethrow;
    }
  }
  
  /// Get current security status
  SecurityStatus getSecurityStatus() {
    return SecurityStatus(
      isInitialized: _isInitialized,
      settings: _settings,
      lastAuditReport: _lastAuditReport,
      lastAuditTime: _lastAuditReport?.timestamp,
    );
  }
  
  /// Validate security requirements for production
  Future<ProductionReadinessResult> validateProductionReadiness() async {
    final issues = <String>[];
    final warnings = <String>[];
    
    try {
      // Check if security is initialized
      if (!_isInitialized) {
        issues.add('Security components not initialized');
      }
      
      // Run security audit
      final auditReport = await runSecurityAudit();
      
      // Check security score
      if (auditReport.securityScore < 80) {
        issues.add('Security score too low: ${auditReport.securityScore}/100');
      } else if (auditReport.securityScore < 90) {
        warnings.add('Security score could be improved: ${auditReport.securityScore}/100');
      }
      
      // Check for critical failures
      final criticalFailures = auditReport.failedChecks
          .where((check) => check.check.severity == SecuritySeverity.critical)
          .toList();
      
      if (criticalFailures.isNotEmpty) {
        issues.add('Critical security checks failed: ${criticalFailures.length}');
      }
      
      // Check for vulnerabilities
      if (auditReport.detectedVulnerabilities.isNotEmpty) {
        issues.add('Security vulnerabilities detected: ${auditReport.detectedVulnerabilities.length}');
      }
      
      // Check debug mode
      if (kDebugMode) {
        warnings.add('Debug mode is enabled (should be disabled in production)');
      }
      
      // Check secure storage
      final storageInitialized = await SecureStorageConfig.initialize();
      if (!storageInitialized) {
        issues.add('Secure storage not properly initialized');
      }
      
      // Check network security
      final networkValidation = await NetworkSecurityConfig.validateSecurityConfiguration();
      if (!networkValidation.isSecure) {
        issues.add('Network security configuration issues: ${networkValidation.errors.join(', ')}');
      }
      
      final isReady = issues.isEmpty;
      
      return ProductionReadinessResult(
        isReady: isReady,
        securityScore: auditReport.securityScore,
        issues: issues,
        warnings: warnings,
        auditReport: auditReport,
      );
      
    } catch (e) {
      return ProductionReadinessResult(
        isReady: false,
        securityScore: 0,
        issues: ['Production readiness check failed: $e'],
        warnings: [],
        auditReport: null,
      );
    }
  }
  
  /// Enable or disable specific security features
  Future<void> updateSecuritySettings(SecuritySettingsUpdate update) async {
    // Note: This would require a mutable settings class in a real implementation
    // For now, we'll just validate the request
    
    if (update.enableBiometricAuth != null) {
      await SecureStorageConfig.setBiometricEnabled(update.enableBiometricAuth!);
    }
    
    if (kDebugMode) {
      print('SecurityConfig: Security settings updated');
    }
  }
  
  /// Get security recommendations based on current status
  List<SecurityRecommendation> getSecurityRecommendations() {
    final recommendations = <SecurityRecommendation>[];
    
    if (!_isInitialized) {
      recommendations.add(SecurityRecommendation(
        priority: RecommendationPriority.critical,
        title: 'Initialize Security Components',
        description: 'Security components are not initialized. Call SecurityConfig.initialize().',
        action: 'Initialize security',
      ));
    }
    
    if (_lastAuditReport == null) {
      recommendations.add(SecurityRecommendation(
        priority: RecommendationPriority.high,
        title: 'Run Security Audit',
        description: 'No security audit has been performed. Run a security audit to identify potential issues.',
        action: 'Run security audit',
      ));
    } else {
      if (_lastAuditReport!.securityScore < 80) {
        recommendations.add(SecurityRecommendation(
          priority: RecommendationPriority.high,
          title: 'Improve Security Score',
          description: 'Security score is ${_lastAuditReport!.securityScore}/100. Address failed security checks.',
          action: 'Fix security issues',
        ));
      }
      
      if (_lastAuditReport!.detectedVulnerabilities.isNotEmpty) {
        recommendations.add(SecurityRecommendation(
          priority: RecommendationPriority.critical,
          title: 'Fix Security Vulnerabilities',
          description: '${_lastAuditReport!.detectedVulnerabilities.length} vulnerabilities detected.',
          action: 'Patch vulnerabilities',
        ));
      }
    }
    
    if (kDebugMode) {
      recommendations.add(SecurityRecommendation(
        priority: RecommendationPriority.medium,
        title: 'Disable Debug Mode',
        description: 'Debug mode is enabled. Disable for production deployment.',
        action: 'Build in release mode',
      ));
    }
    
    return recommendations;
  }
  
  /// Clean up security resources
  Future<void> dispose() async {
    try {
      if (_settings.enableMemoryManagement) {
        MemoryManager().dispose();
      }
      
      _isInitialized = false;
      _lastAuditReport = null;
      
      if (kDebugMode) {
        print('SecurityConfig: Security resources cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SecurityConfig: Error during cleanup: $e');
      }
    }
  }
}

/// Security configuration settings
class SecuritySettings {
  final bool enableSecureStorage;
  final bool enableCertificatePinning;
  final bool enableInputValidation;
  final bool enableMemoryManagement;
  final bool enableSecurityAudit;
  final bool enableTransactionLogging;
  final bool enableBiometricAuth;
  final bool enableRootDetection;
  final int maxLoginAttempts;
  final int sessionTimeoutMinutes;
  final int auditIntervalHours;
  
  const SecuritySettings({
    required this.enableSecureStorage,
    required this.enableCertificatePinning,
    required this.enableInputValidation,
    required this.enableMemoryManagement,
    required this.enableSecurityAudit,
    required this.enableTransactionLogging,
    required this.enableBiometricAuth,
    required this.enableRootDetection,
    required this.maxLoginAttempts,
    required this.sessionTimeoutMinutes,
    required this.auditIntervalHours,
  });
}

/// Security initialization result
class SecurityInitializationResult {
  final bool success;
  final String message;
  final Map<String, bool> details;
  
  const SecurityInitializationResult({
    required this.success,
    required this.message,
    required this.details,
  });
}

/// Security status information
class SecurityStatus {
  final bool isInitialized;
  final SecuritySettings settings;
  final SecurityAuditReport? lastAuditReport;
  final DateTime? lastAuditTime;
  
  const SecurityStatus({
    required this.isInitialized,
    required this.settings,
    this.lastAuditReport,
    this.lastAuditTime,
  });
}

/// Production readiness validation result
class ProductionReadinessResult {
  final bool isReady;
  final int securityScore;
  final List<String> issues;
  final List<String> warnings;
  final SecurityAuditReport? auditReport;
  
  const ProductionReadinessResult({
    required this.isReady,
    required this.securityScore,
    required this.issues,
    required this.warnings,
    this.auditReport,
  });
}

/// Security settings update request
class SecuritySettingsUpdate {
  final bool? enableBiometricAuth;
  final int? maxLoginAttempts;
  final int? sessionTimeoutMinutes;
  
  const SecuritySettingsUpdate({
    this.enableBiometricAuth,
    this.maxLoginAttempts,
    this.sessionTimeoutMinutes,
  });
}

/// Security recommendation
class SecurityRecommendation {
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String action;
  
  const SecurityRecommendation({
    required this.priority,
    required this.title,
    required this.description,
    required this.action,
  });
}

/// Recommendation priority levels
enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}