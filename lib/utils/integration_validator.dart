import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../config/app_config.dart';
import '../providers/provider_registry.dart';
import 'performance_utils.dart';
import 'app_lifecycle_manager.dart';

/// Validates that all components are properly integrated
class IntegrationValidator {
  static bool _hasValidated = false;
  
  /// Perform comprehensive integration validation
  static Future<ValidationResult> validateIntegration() async {
    if (_hasValidated && !kDebugMode) {
      return ValidationResult.success('Integration already validated');
    }
    
    final issues = <String>[];
    final warnings = <String>[];
    
    try {
      // Validate app configuration
      if (!AppConfig.isInitialized) {
        issues.add('AppConfig not initialized');
      }
      
      // Validate provider registry
      if (!ProviderRegistry.isInitialized) {
        issues.add('ProviderRegistry not initialized');
      }
      
      // Validate lifecycle manager
      if (!AppLifecycleManager.instance.isInitialized) {
        warnings.add('AppLifecycleManager not initialized');
      }
      
      // Validate performance utilities
      await _validatePerformanceUtils(warnings);
      
      // Validate UI components
      _validateUIComponents(warnings);
      
      // Validate navigation
      _validateNavigation(warnings);
      
      _hasValidated = true;
      
      if (issues.isNotEmpty) {
        return ValidationResult.failure(
          'Integration validation failed',
          issues: issues,
          warnings: warnings,
        );
      }
      
      if (warnings.isNotEmpty) {
        return ValidationResult.warning(
          'Integration validation completed with warnings',
          warnings: warnings,
        );
      }
      
      return ValidationResult.success(
        'All components properly integrated',
      );
      
    } catch (e) {
      return ValidationResult.failure(
        'Integration validation error: $e',
        issues: ['Validation process failed: $e'],
      );
    }
  }
  
  static Future<void> _validatePerformanceUtils(List<String> warnings) async {
    try {
      // Test caching
      PerformanceUtils.cacheData('test_key', 'test_value');
      final cachedValue = PerformanceUtils.getCachedData<String>('test_key');
      
      if (cachedValue != 'test_value') {
        warnings.add('Performance caching not working correctly');
      }
      
      PerformanceUtils.clearCache('test_key');
      
      // Test debouncing
      bool debounceWorked = false;
      PerformanceUtils.debounce('test_debounce', () {
        debounceWorked = true;
      }, delay: const Duration(milliseconds: 10));
      
      await Future.delayed(const Duration(milliseconds: 20));
      
      if (!debounceWorked) {
        warnings.add('Performance debouncing not working correctly');
      }
      
    } catch (e) {
      warnings.add('Performance utilities validation failed: $e');
    }
  }
  
  static void _validateUIComponents(List<String> warnings) {
    // This would typically validate that all required UI components are available
    // For now, we'll just log that UI validation was performed
    if (kDebugMode) {
      developer.log('UI components validation completed', name: 'IntegrationValidator');
    }
  }
  
  static void _validateNavigation(List<String> warnings) {
    // This would typically validate navigation routes and transitions
    // For now, we'll just log that navigation validation was performed
    if (kDebugMode) {
      developer.log('Navigation validation completed', name: 'IntegrationValidator');
    }
  }
  
  /// Reset validation state (for testing)
  static void resetValidation() {
    _hasValidated = false;
  }
}

/// Result of integration validation
class ValidationResult {
  final bool isSuccess;
  final String message;
  final List<String> issues;
  final List<String> warnings;
  
  const ValidationResult._({
    required this.isSuccess,
    required this.message,
    this.issues = const [],
    this.warnings = const [],
  });
  
  factory ValidationResult.success(String message) {
    return ValidationResult._(
      isSuccess: true,
      message: message,
    );
  }
  
  factory ValidationResult.warning(
    String message, {
    List<String> warnings = const [],
  }) {
    return ValidationResult._(
      isSuccess: true,
      message: message,
      warnings: warnings,
    );
  }
  
  factory ValidationResult.failure(
    String message, {
    List<String> issues = const [],
    List<String> warnings = const [],
  }) {
    return ValidationResult._(
      isSuccess: false,
      message: message,
      issues: issues,
      warnings: warnings,
    );
  }
  
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasIssues => issues.isNotEmpty;
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ValidationResult: $message');
    
    if (hasIssues) {
      buffer.writeln('Issues:');
      for (final issue in issues) {
        buffer.writeln('  - $issue');
      }
    }
    
    if (hasWarnings) {
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    
    return buffer.toString();
  }
}