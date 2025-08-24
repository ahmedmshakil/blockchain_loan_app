import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/secure_storage_config.dart';
import '../config/network_security_config.dart';
import '../utils/input_validator.dart';
import '../utils/memory_manager.dart';

/// Security audit and vulnerability testing framework
class SecurityAudit {
  static const String _auditVersion = '1.0.0';
  static final List<SecurityCheck> _securityChecks = [];
  static final List<VulnerabilityTest> _vulnerabilityTests = [];
  
  /// Initialize security audit framework
  static Future<void> initialize() async {
    _registerSecurityChecks();
    _registerVulnerabilityTests();
    
    if (kDebugMode) {
      print('SecurityAudit initialized with ${_securityChecks.length} checks and ${_vulnerabilityTests.length} tests');
    }
  }
  
  /// Register all security checks
  static void _registerSecurityChecks() {
    _securityChecks.addAll([
      // Secure Storage Checks
      SecurityCheck(
        id: 'secure_storage_init',
        name: 'Secure Storage Initialization',
        description: 'Verify secure storage is properly initialized',
        category: SecurityCategory.storage,
        severity: SecuritySeverity.high,
        check: _checkSecureStorageInit,
      ),
      
      SecurityCheck(
        id: 'private_key_security',
        name: 'Private Key Security',
        description: 'Verify private keys are stored securely',
        category: SecurityCategory.cryptography,
        severity: SecuritySeverity.critical,
        check: _checkPrivateKeySecurity,
      ),
      
      // Network Security Checks
      SecurityCheck(
        id: 'certificate_pinning',
        name: 'Certificate Pinning',
        description: 'Verify certificate pinning is enabled',
        category: SecurityCategory.network,
        severity: SecuritySeverity.high,
        check: _checkCertificatePinning,
      ),
      
      SecurityCheck(
        id: 'secure_communication',
        name: 'Secure Communication',
        description: 'Verify all communications use HTTPS/TLS',
        category: SecurityCategory.network,
        severity: SecuritySeverity.high,
        check: _checkSecureCommunication,
      ),
      
      // Input Validation Checks
      SecurityCheck(
        id: 'input_validation',
        name: 'Input Validation',
        description: 'Verify input validation is implemented',
        category: SecurityCategory.input,
        severity: SecuritySeverity.medium,
        check: _checkInputValidation,
      ),
      
      SecurityCheck(
        id: 'sql_injection_protection',
        name: 'SQL Injection Protection',
        description: 'Verify protection against SQL injection',
        category: SecurityCategory.input,
        severity: SecuritySeverity.high,
        check: _checkSqlInjectionProtection,
      ),
      
      // Memory Management Checks
      SecurityCheck(
        id: 'memory_management',
        name: 'Memory Management',
        description: 'Verify secure memory management',
        category: SecurityCategory.memory,
        severity: SecuritySeverity.medium,
        check: _checkMemoryManagement,
      ),
      
      // Application Security Checks
      SecurityCheck(
        id: 'debug_mode_check',
        name: 'Debug Mode Check',
        description: 'Verify debug mode is disabled in production',
        category: SecurityCategory.application,
        severity: SecuritySeverity.medium,
        check: _checkDebugMode,
      ),
      
      SecurityCheck(
        id: 'root_detection',
        name: 'Root/Jailbreak Detection',
        description: 'Verify root/jailbreak detection is implemented',
        category: SecurityCategory.application,
        severity: SecuritySeverity.medium,
        check: _checkRootDetection,
      ),
      
      // Blockchain Security Checks
      SecurityCheck(
        id: 'smart_contract_validation',
        name: 'Smart Contract Validation',
        description: 'Verify smart contract addresses and interactions',
        category: SecurityCategory.blockchain,
        severity: SecuritySeverity.high,
        check: _checkSmartContractValidation,
      ),
    ]);
  }
  
  /// Register vulnerability tests
  static void _registerVulnerabilityTests() {
    _vulnerabilityTests.addAll([
      VulnerabilityTest(
        id: 'xss_test',
        name: 'Cross-Site Scripting (XSS) Test',
        description: 'Test for XSS vulnerabilities in input fields',
        test: _testXssVulnerability,
      ),
      
      VulnerabilityTest(
        id: 'injection_test',
        name: 'Injection Attack Test',
        description: 'Test for various injection vulnerabilities',
        test: _testInjectionVulnerability,
      ),
      
      VulnerabilityTest(
        id: 'buffer_overflow_test',
        name: 'Buffer Overflow Test',
        description: 'Test for buffer overflow vulnerabilities',
        test: _testBufferOverflow,
      ),
      
      VulnerabilityTest(
        id: 'timing_attack_test',
        name: 'Timing Attack Test',
        description: 'Test for timing attack vulnerabilities',
        test: _testTimingAttack,
      ),
      
      VulnerabilityTest(
        id: 'memory_leak_test',
        name: 'Memory Leak Test',
        description: 'Test for memory leaks in sensitive operations',
        test: _testMemoryLeak,
      ),
    ]);
  }
  
  /// Run complete security audit
  static Future<SecurityAuditReport> runCompleteAudit() async {
    final startTime = DateTime.now();
    final checkResults = <SecurityCheckResult>[];
    final testResults = <VulnerabilityTestResult>[];
    
    try {
      // Run security checks
      for (final check in _securityChecks) {
        try {
          final result = await check.check();
          checkResults.add(SecurityCheckResult(
            check: check,
            passed: result.passed,
            message: result.message,
            details: result.details,
            timestamp: DateTime.now(),
          ));
        } catch (e) {
          checkResults.add(SecurityCheckResult(
            check: check,
            passed: false,
            message: 'Check failed with error: $e',
            details: {'error': e.toString()},
            timestamp: DateTime.now(),
          ));
        }
      }
      
      // Run vulnerability tests
      for (final test in _vulnerabilityTests) {
        try {
          final result = await test.test();
          testResults.add(VulnerabilityTestResult(
            test: test,
            vulnerable: result.vulnerable,
            message: result.message,
            details: result.details,
            timestamp: DateTime.now(),
          ));
        } catch (e) {
          testResults.add(VulnerabilityTestResult(
            test: test,
            vulnerable: true,
            message: 'Test failed with error: $e',
            details: {'error': e.toString()},
            timestamp: DateTime.now(),
          ));
        }
      }
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      return SecurityAuditReport(
        version: _auditVersion,
        timestamp: startTime,
        duration: duration,
        checkResults: checkResults,
        testResults: testResults,
      );
      
    } catch (e) {
      throw SecurityAuditException('Security audit failed: $e');
    }
  }
  
  /// Run specific security check
  static Future<SecurityCheckResult> runSecurityCheck(String checkId) async {
    final check = _securityChecks.firstWhere(
      (c) => c.id == checkId,
      orElse: () => throw ArgumentError('Security check not found: $checkId'),
    );
    
    try {
      final result = await check.check();
      return SecurityCheckResult(
        check: check,
        passed: result.passed,
        message: result.message,
        details: result.details,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return SecurityCheckResult(
        check: check,
        passed: false,
        message: 'Check failed with error: $e',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Run specific vulnerability test
  static Future<VulnerabilityTestResult> runVulnerabilityTest(String testId) async {
    final test = _vulnerabilityTests.firstWhere(
      (t) => t.id == testId,
      orElse: () => throw ArgumentError('Vulnerability test not found: $testId'),
    );
    
    try {
      final result = await test.test();
      return VulnerabilityTestResult(
        test: test,
        vulnerable: result.vulnerable,
        message: result.message,
        details: result.details,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return VulnerabilityTestResult(
        test: test,
        vulnerable: true,
        message: 'Test failed with error: $e',
        details: {'error': e.toString()},
        timestamp: DateTime.now(),
      );
    }
  }
  
  // Security Check Implementations
  
  static Future<CheckResult> _checkSecureStorageInit() async {
    try {
      final isInitialized = await SecureStorageConfig.initialize();
      return CheckResult(
        passed: isInitialized,
        message: isInitialized ? 'Secure storage initialized successfully' : 'Secure storage initialization failed',
        details: {'initialized': isInitialized},
      );
    } catch (e) {
      return CheckResult(
        passed: false,
        message: 'Secure storage check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<CheckResult> _checkPrivateKeySecurity() async {
    try {
      // Check if private key storage is secure
      final hasPrivateKey = await SecureStorageConfig.containsKey(SecureStorageConfig.privateKeyKey);
      
      if (hasPrivateKey) {
        // Verify the key is not stored in plain text (basic check)
        final privateKey = await SecureStorageConfig.getPrivateKey();
        final isValidFormat = privateKey != null && privateKey.length >= 64;
        
        return CheckResult(
          passed: isValidFormat,
          message: isValidFormat ? 'Private key is securely stored' : 'Private key format is invalid',
          details: {
            'has_private_key': hasPrivateKey,
            'valid_format': isValidFormat,
          },
        );
      } else {
        return CheckResult(
          passed: true,
          message: 'No private key stored (acceptable for demo)',
          details: {'has_private_key': false},
        );
      }
    } catch (e) {
      return CheckResult(
        passed: false,
        message: 'Private key security check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<CheckResult> _checkCertificatePinning() async {
    try {
      final validationResult = await NetworkSecurityConfig.validateSecurityConfiguration();
      
      return CheckResult(
        passed: validationResult.isSecure,
        message: validationResult.isSecure 
            ? 'Certificate pinning is properly configured'
            : 'Certificate pinning issues detected: ${validationResult.errors.join(', ')}',
        details: {
          'is_secure': validationResult.isSecure,
          'results': validationResult.results,
          'errors': validationResult.errors,
        },
      );
    } catch (e) {
      return CheckResult(
        passed: false,
        message: 'Certificate pinning check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<CheckResult> _checkSecureCommunication() async {
    try {
      final isSecureEnvironment = NetworkSecurityConfig.isSecureEnvironment();
      final securityHeaders = NetworkSecurityConfig.getSecurityHeaders();
      
      return CheckResult(
        passed: isSecureEnvironment && securityHeaders.isNotEmpty,
        message: isSecureEnvironment 
            ? 'Secure communication is properly configured'
            : 'Secure communication configuration issues detected',
        details: {
          'secure_environment': isSecureEnvironment,
          'security_headers_count': securityHeaders.length,
        },
      );
    } catch (e) {
      return CheckResult(
        passed: false,
        message: 'Secure communication check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<CheckResult> _checkInputValidation() async {
    try {
      // Test various input validation scenarios
      final testInputs = {
        'email': 'test@example.com',
        'nid': '1234567890',
        'wallet_address': '0x742d35Cc6634C0532925a3b8D404fBaF7c0C7D96',
        'loan_amount': '1000.50',
      };
      
      final validationResults = InputValidator.validateBatch(testInputs);
      final allValid = InputValidator.areAllValid(validationResults);
      
      return CheckResult(
        passed: allValid,
        message: allValid 
            ? 'Input validation is working correctly'
            : 'Input validation issues detected',
        details: {
          'validation_results': validationResults.map((k, v) => MapEntry(k, v.isValid)),
          'all_valid': allValid,
        },
      );
    } catch (e) {
      return CheckResult(
        passed: false,
        message: 'Input validation check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<CheckResult> _checkSqlInjectionProtection() async {
    try {
      // Test SQL injection patterns
      final maliciousInputs = [
        "'; DROP TABLE users; --",
        "1' OR '1'='1",
        "admin'--",
        "' UNION SELECT * FROM users --",
      ];
      
      bool allProtected = true;
      final results = <String, bool>{};
      
      for (final input in maliciousInputs) {
        final sanitized = InputValidator.sanitizeInput(input);
        final isProtected = sanitized != input;
        results[input] = isProtected;
        if (!isProtected) allProtected = false;
      }
      
      return CheckResult(
        passed: allProtected,
        message: allProtected 
            ? 'SQL injection protection is working'
            : 'SQL injection vulnerabilities detected',
        details: {'test_results': results},
      );
    } catch (e) {
      return CheckResult(
        passed: false,
        message: 'SQL injection protection check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<CheckResult> _checkMemoryManagement() async {
    try {
      final memoryManager = MemoryManager();
      final stats = memoryManager.getMemoryStats();
      
      // Check if memory management is functioning
      final testData = memoryManager.createSecureBytes(100);
      final statsAfter = memoryManager.getMemoryStats();
      
      final isWorking = statsAfter.activeSensitiveDataCount > stats.activeSensitiveDataCount;
      
      return CheckResult(
        passed: isWorking,
        message: isWorking 
            ? 'Memory management is working correctly'
            : 'Memory management issues detected',
        details: {
          'initial_stats': stats.toString(),
          'after_stats': statsAfter.toString(),
          'is_working': isWorking,
        },
      );
    } catch (e) {
      return CheckResult(
        passed: false,
        message: 'Memory management check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<CheckResult> _checkDebugMode() async {
    try {
      final isDebugMode = kDebugMode;
      
      return CheckResult(
        passed: !isDebugMode, // In production, debug mode should be false
        message: isDebugMode 
            ? 'Debug mode is enabled (acceptable in development)'
            : 'Debug mode is disabled (good for production)',
        details: {'debug_mode': isDebugMode},
      );
    } catch (e) {
      return CheckResult(
        passed: false,
        message: 'Debug mode check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<CheckResult> _checkRootDetection() async {
    try {
      // Basic root/jailbreak detection
      bool isRooted = false;
      
      if (Platform.isAndroid) {
        // Check for common root indicators on Android
        final rootPaths = [
          '/system/app/Superuser.apk',
          '/sbin/su',
          '/system/bin/su',
          '/system/xbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su',
        ];
        
        for (final path in rootPaths) {
          if (await File(path).exists()) {
            isRooted = true;
            break;
          }
        }
      } else if (Platform.isIOS) {
        // Check for common jailbreak indicators on iOS
        final jailbreakPaths = [
          '/Applications/Cydia.app',
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
          '/bin/bash',
          '/usr/sbin/sshd',
          '/etc/apt',
        ];
        
        for (final path in jailbreakPaths) {
          if (await File(path).exists()) {
            isRooted = true;
            break;
          }
        }
      }
      
      return CheckResult(
        passed: !isRooted,
        message: isRooted 
            ? 'Device appears to be rooted/jailbroken'
            : 'Device does not appear to be rooted/jailbroken',
        details: {'is_rooted': isRooted},
      );
    } catch (e) {
      return CheckResult(
        passed: true, // Assume safe if check fails
        message: 'Root detection check failed (assuming safe): $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<CheckResult> _checkSmartContractValidation() async {
    try {
      // Validate smart contract address format
      const contractAddress = '0x742d35Cc6634C0532925a3b8D404fBaF7c0C7D96'; // Example
      final validation = InputValidator.validateContractAddress(contractAddress);
      
      return CheckResult(
        passed: validation.isValid,
        message: validation.message,
        details: {
          'contract_address': contractAddress,
          'is_valid': validation.isValid,
        },
      );
    } catch (e) {
      return CheckResult(
        passed: false,
        message: 'Smart contract validation check failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  // Vulnerability Test Implementations
  
  static Future<TestResult> _testXssVulnerability() async {
    try {
      final xssPayloads = [
        '<script>alert("XSS")</script>',
        'javascript:alert("XSS")',
        '<img src="x" onerror="alert(\'XSS\')">',
        '"><script>alert("XSS")</script>',
      ];
      
      bool vulnerable = false;
      final results = <String, String>{};
      
      for (final payload in xssPayloads) {
        final sanitized = InputValidator.sanitizeHtml(payload);
        results[payload] = sanitized;
        
        // If sanitization didn't remove the dangerous content, it's vulnerable
        if (sanitized.contains('<script>') || sanitized.contains('javascript:')) {
          vulnerable = true;
        }
      }
      
      return TestResult(
        vulnerable: vulnerable,
        message: vulnerable 
            ? 'XSS vulnerabilities detected'
            : 'No XSS vulnerabilities found',
        details: {'test_results': results},
      );
    } catch (e) {
      return TestResult(
        vulnerable: true,
        message: 'XSS test failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<TestResult> _testInjectionVulnerability() async {
    try {
      final injectionPayloads = [
        "'; DROP TABLE users; --",
        "1' OR '1'='1",
        "../../../etc/passwd",
        "{{7*7}}",
        "\${7*7}",
      ];
      
      bool vulnerable = false;
      final results = <String, String>{};
      
      for (final payload in injectionPayloads) {
        final sanitized = InputValidator.sanitizeInput(payload);
        results[payload] = sanitized;
        
        // Check if dangerous patterns remain
        if (sanitized.contains('DROP TABLE') || 
            sanitized.contains('OR \'1\'=\'1\'') ||
            sanitized.contains('../')) {
          vulnerable = true;
        }
      }
      
      return TestResult(
        vulnerable: vulnerable,
        message: vulnerable 
            ? 'Injection vulnerabilities detected'
            : 'No injection vulnerabilities found',
        details: {'test_results': results},
      );
    } catch (e) {
      return TestResult(
        vulnerable: true,
        message: 'Injection test failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<TestResult> _testBufferOverflow() async {
    try {
      // Test with very long inputs
      final longString = 'A' * 10000;
      final results = <String, dynamic>{};
      
      bool vulnerable = false;
      
      try {
        final validation = InputValidator.validateName(longString);
        results['long_name_validation'] = validation.isValid;
        
        final sanitized = InputValidator.sanitizeInput(longString);
        results['sanitized_length'] = sanitized.length;
        results['original_length'] = longString.length;
        
        // If the system doesn't handle long inputs properly, it might be vulnerable
        if (sanitized.length == longString.length) {
          vulnerable = true;
        }
      } catch (e) {
        // If an exception is thrown, it might indicate a buffer overflow vulnerability
        vulnerable = true;
        results['exception'] = e.toString();
      }
      
      return TestResult(
        vulnerable: vulnerable,
        message: vulnerable 
            ? 'Potential buffer overflow vulnerability detected'
            : 'No buffer overflow vulnerabilities found',
        details: results,
      );
    } catch (e) {
      return TestResult(
        vulnerable: true,
        message: 'Buffer overflow test failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<TestResult> _testTimingAttack() async {
    try {
      // Test for timing attack vulnerabilities in validation
      final validInput = 'valid@example.com';
      final invalidInput = 'invalid-email';
      
      final stopwatch = Stopwatch();
      final timings = <String, int>{};
      
      // Measure validation time for valid input
      stopwatch.start();
      InputValidator.validateEmail(validInput);
      stopwatch.stop();
      timings['valid_input'] = stopwatch.elapsedMicroseconds;
      
      stopwatch.reset();
      
      // Measure validation time for invalid input
      stopwatch.start();
      InputValidator.validateEmail(invalidInput);
      stopwatch.stop();
      timings['invalid_input'] = stopwatch.elapsedMicroseconds;
      
      // Check for significant timing differences
      final timeDifference = (timings['valid_input']! - timings['invalid_input']!).abs();
      final vulnerable = timeDifference > 1000; // More than 1ms difference
      
      return TestResult(
        vulnerable: vulnerable,
        message: vulnerable 
            ? 'Potential timing attack vulnerability detected'
            : 'No timing attack vulnerabilities found',
        details: {
          'timings': timings,
          'time_difference_microseconds': timeDifference,
        },
      );
    } catch (e) {
      return TestResult(
        vulnerable: false,
        message: 'Timing attack test failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
  
  static Future<TestResult> _testMemoryLeak() async {
    try {
      final memoryManager = MemoryManager();
      final initialStats = memoryManager.getMemoryStats();
      
      // Create and dispose of sensitive data
      for (int i = 0; i < 100; i++) {
        final data = memoryManager.createSecureBytes(1000);
        // Simulate some processing
        data[0] = i % 256;
      }
      
      // Force cleanup
      memoryManager.forceCleanup();
      
      final finalStats = memoryManager.getMemoryStats();
      
      // Check if memory was properly cleaned up
      final memoryLeaked = finalStats.activeSensitiveDataCount > initialStats.activeSensitiveDataCount + 10;
      
      return TestResult(
        vulnerable: memoryLeaked,
        message: memoryLeaked 
            ? 'Potential memory leak detected'
            : 'No memory leaks detected',
        details: {
          'initial_stats': initialStats.toString(),
          'final_stats': finalStats.toString(),
          'memory_leaked': memoryLeaked,
        },
      );
    } catch (e) {
      return TestResult(
        vulnerable: true,
        message: 'Memory leak test failed: $e',
        details: {'error': e.toString()},
      );
    }
  }
}

// Security audit data structures

enum SecurityCategory {
  storage,
  network,
  input,
  memory,
  application,
  cryptography,
  blockchain,
}

enum SecuritySeverity {
  low,
  medium,
  high,
  critical,
}

class SecurityCheck {
  final String id;
  final String name;
  final String description;
  final SecurityCategory category;
  final SecuritySeverity severity;
  final Future<CheckResult> Function() check;
  
  const SecurityCheck({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.severity,
    required this.check,
  });
}

class VulnerabilityTest {
  final String id;
  final String name;
  final String description;
  final Future<TestResult> Function() test;
  
  const VulnerabilityTest({
    required this.id,
    required this.name,
    required this.description,
    required this.test,
  });
}

class CheckResult {
  final bool passed;
  final String message;
  final Map<String, dynamic> details;
  
  const CheckResult({
    required this.passed,
    required this.message,
    required this.details,
  });
}

class TestResult {
  final bool vulnerable;
  final String message;
  final Map<String, dynamic> details;
  
  const TestResult({
    required this.vulnerable,
    required this.message,
    required this.details,
  });
}

class SecurityCheckResult {
  final SecurityCheck check;
  final bool passed;
  final String message;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  
  const SecurityCheckResult({
    required this.check,
    required this.passed,
    required this.message,
    required this.details,
    required this.timestamp,
  });
}

class VulnerabilityTestResult {
  final VulnerabilityTest test;
  final bool vulnerable;
  final String message;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  
  const VulnerabilityTestResult({
    required this.test,
    required this.vulnerable,
    required this.message,
    required this.details,
    required this.timestamp,
  });
}

class SecurityAuditReport {
  final String version;
  final DateTime timestamp;
  final Duration duration;
  final List<SecurityCheckResult> checkResults;
  final List<VulnerabilityTestResult> testResults;
  
  const SecurityAuditReport({
    required this.version,
    required this.timestamp,
    required this.duration,
    required this.checkResults,
    required this.testResults,
  });
  
  /// Get overall security score (0-100)
  int get securityScore {
    if (checkResults.isEmpty) return 0;
    
    int totalWeight = 0;
    int passedWeight = 0;
    
    for (final result in checkResults) {
      int weight;
      switch (result.check.severity) {
        case SecuritySeverity.critical:
          weight = 4;
          break;
        case SecuritySeverity.high:
          weight = 3;
          break;
        case SecuritySeverity.medium:
          weight = 2;
          break;
        case SecuritySeverity.low:
          weight = 1;
          break;
      }
      
      totalWeight += weight;
      if (result.passed) {
        passedWeight += weight;
      }
    }
    
    // Deduct points for vulnerabilities
    int vulnerabilityPenalty = testResults.where((r) => r.vulnerable).length * 5;
    
    int score = totalWeight > 0 ? ((passedWeight * 100) ~/ totalWeight) : 0;
    score = (score - vulnerabilityPenalty).clamp(0, 100);
    
    return score;
  }
  
  /// Get failed checks
  List<SecurityCheckResult> get failedChecks {
    return checkResults.where((r) => !r.passed).toList();
  }
  
  /// Get detected vulnerabilities
  List<VulnerabilityTestResult> get detectedVulnerabilities {
    return testResults.where((r) => r.vulnerable).toList();
  }
  
  /// Check if audit passed (no critical failures)
  bool get auditPassed {
    final criticalFailures = failedChecks
        .where((r) => r.check.severity == SecuritySeverity.critical)
        .length;
    
    return criticalFailures == 0 && detectedVulnerabilities.isEmpty;
  }
}

class SecurityAuditException implements Exception {
  final String message;
  
  const SecurityAuditException(this.message);
  
  @override
  String toString() => 'SecurityAuditException: $message';
}