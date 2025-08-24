import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_loan_app/config/secure_storage_config.dart';
import 'package:blockchain_loan_app/config/network_security_config.dart';
import 'package:blockchain_loan_app/utils/input_validator.dart';
import 'package:blockchain_loan_app/utils/memory_manager.dart';
import 'package:blockchain_loan_app/security/security_audit.dart';

void main() {
  group('Security Tests', () {
    
    group('Secure Storage Tests', () {
      test('should initialize secure storage successfully', () async {
        final result = await SecureStorageConfig.initialize();
        expect(result, isTrue);
      });
      
      test('should store and retrieve private key securely', () async {
        const testPrivateKey = 'a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890';
        
        await SecureStorageConfig.storePrivateKey(testPrivateKey);
        final retrievedKey = await SecureStorageConfig.getPrivateKey();
        
        expect(retrievedKey, equals(testPrivateKey));
        
        // Clean up
        await SecureStorageConfig.deleteKey(SecureStorageConfig.privateKeyKey);
      });
      
      test('should store and retrieve wallet address securely', () async {
        const testAddress = '0x742d35Cc6634C0532925a3b8D404fBaF7c0C7D96';
        
        await SecureStorageConfig.storeWalletAddress(testAddress);
        final retrievedAddress = await SecureStorageConfig.getWalletAddress();
        
        expect(retrievedAddress, equals(testAddress));
        
        // Clean up
        await SecureStorageConfig.deleteKey(SecureStorageConfig.walletAddressKey);
      });
      
      test('should handle secure storage exceptions', () async {
        expect(
          () => SecureStorageConfig.deleteKey('non_existent_key'),
          returnsNormally,
        );
      });
      
      test('should store and retrieve user credentials securely', () async {
        final testCredentials = {
          'username': 'testuser',
          'email': 'test@example.com',
        };
        
        await SecureStorageConfig.storeUserCredentials(testCredentials);
        final retrievedCredentials = await SecureStorageConfig.getUserCredentials();
        
        expect(retrievedCredentials, equals(testCredentials));
        
        // Clean up
        await SecureStorageConfig.deleteKey(SecureStorageConfig.userCredentialsKey);
      });
      
      test('should handle biometric preferences', () async {
        await SecureStorageConfig.setBiometricEnabled(true);
        final isEnabled = await SecureStorageConfig.isBiometricEnabled();
        expect(isEnabled, isTrue);
        
        await SecureStorageConfig.setBiometricEnabled(false);
        final isDisabled = await SecureStorageConfig.isBiometricEnabled();
        expect(isDisabled, isFalse);
        
        // Clean up
        await SecureStorageConfig.deleteKey(SecureStorageConfig.biometricEnabledKey);
      });
    });
    
    group('Network Security Tests', () {
      test('should validate security configuration', () async {
        final result = await NetworkSecurityConfig.validateSecurityConfiguration();
        expect(result, isNotNull);
        expect(result.results, isNotEmpty);
      });
      
      test('should provide security headers', () {
        final headers = NetworkSecurityConfig.getSecurityHeaders();
        expect(headers, isNotEmpty);
        expect(headers['User-Agent'], isNotNull);
        expect(headers['Cache-Control'], equals('no-cache, no-store, must-revalidate'));
      });
      
      test('should check secure environment', () {
        final isSecure = NetworkSecurityConfig.isSecureEnvironment();
        expect(isSecure, isA<bool>());
      });
      
      test('should provide security settings', () {
        final settings = NetworkSecurityConfig.getSecuritySettings();
        expect(settings.enableCertificatePinning, isTrue);
        expect(settings.enableRequestTimeout, isTrue);
        expect(settings.requestTimeoutSeconds, greaterThan(0));
      });
    });
    
    group('Input Validation Tests', () {
      test('should validate email addresses correctly', () {
        final validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
        ];
        
        final invalidEmails = [
          'invalid-email',
          '@example.com',
          'test@',
          'test..test@example.com',
        ];
        
        for (final email in validEmails) {
          final result = InputValidator.validateEmail(email);
          expect(result.isValid, isTrue, reason: 'Email $email should be valid');
        }
        
        for (final email in invalidEmails) {
          final result = InputValidator.validateEmail(email);
          expect(result.isValid, isFalse, reason: 'Email $email should be invalid');
        }
      });
      
      test('should validate NID correctly', () {
        final validNIDs = [
          '1234567890',
          '12345678901234567',
        ];
        
        final invalidNIDs = [
          '123456789', // Too short
          '123456789012345678', // Too long
          '12345abcde', // Contains letters
          '123-456-789', // Contains hyphens
        ];
        
        for (final nid in validNIDs) {
          final result = InputValidator.validateNID(nid);
          expect(result.isValid, isTrue, reason: 'NID $nid should be valid');
        }
        
        for (final nid in invalidNIDs) {
          final result = InputValidator.validateNID(nid);
          expect(result.isValid, isFalse, reason: 'NID $nid should be invalid');
        }
      });
      
      test('should validate wallet addresses correctly', () {
        final validAddresses = [
          '0x742d35Cc6634C0532925a3b8D404fBaF7c0C7D96',
          '0x0000000000000000000000000000000000000000',
          '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
        ];
        
        final invalidAddresses = [
          '742d35Cc6634C0532925a3b8D404fBaF7c0C7D96', // Missing 0x
          '0x742d35Cc6634C0532925a3b8D404fBaF7c0C7D9', // Too short
          '0x742d35Cc6634C0532925a3b8D404fBaF7c0C7D966', // Too long
          '0xGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG', // Invalid hex
        ];
        
        for (final address in validAddresses) {
          final result = InputValidator.validateWalletAddress(address);
          expect(result.isValid, isTrue, reason: 'Address $address should be valid');
        }
        
        for (final address in invalidAddresses) {
          final result = InputValidator.validateWalletAddress(address);
          expect(result.isValid, isFalse, reason: 'Address $address should be invalid');
        }
      });
      
      test('should validate loan amounts correctly', () {
        final validAmounts = [
          '1000',
          '1000.50',
          '0.01',
          '999999.99',
        ];
        
        final invalidAmounts = [
          '0',
          '-100',
          'abc',
          '1000.50.25',
          '',
        ];
        
        for (final amount in validAmounts) {
          final result = InputValidator.validateLoanAmount(amount);
          expect(result.isValid, isTrue, reason: 'Amount $amount should be valid');
        }
        
        for (final amount in invalidAmounts) {
          final result = InputValidator.validateLoanAmount(amount);
          expect(result.isValid, isFalse, reason: 'Amount $amount should be invalid');
        }
      });
      
      test('should validate names correctly', () {
        final validNames = [
          'John Doe',
          'Mary Jane Smith',
          "O'Connor",
          'Jean-Pierre',
          'Dr. Smith',
        ];
        
        final invalidNames = [
          'A', // Too short
          'John123', // Contains numbers
          'John@Doe', // Contains special characters
          '', // Empty
        ];
        
        for (final name in validNames) {
          final result = InputValidator.validateName(name);
          expect(result.isValid, isTrue, reason: 'Name $name should be valid');
        }
        
        for (final name in invalidNames) {
          final result = InputValidator.validateName(name);
          expect(result.isValid, isFalse, reason: 'Name $name should be invalid');
        }
      });
      
      test('should sanitize input correctly', () {
        final testCases = {
          '<script>alert("xss")</script>': 'scriptalert("xss")/script',
          'normal text': 'normal text',
          'text with "quotes"': 'text with quotes',
          'multiple   spaces': 'multiple spaces',
          '   leading and trailing   ': 'leading and trailing',
        };
        
        for (final entry in testCases.entries) {
          final sanitized = InputValidator.sanitizeInput(entry.key);
          expect(sanitized, equals(entry.value));
        }
      });
      
      test('should validate passwords correctly', () {
        final validPasswords = [
          'Password123!',
          'MySecure@Pass1',
          'Complex#Password9',
        ];
        
        final invalidPasswords = [
          'password', // No uppercase, numbers, or special chars
          'PASSWORD', // No lowercase, numbers, or special chars
          'Password', // No numbers or special chars
          'Pass1!', // Too short
          'password123', // No uppercase or special chars
        ];
        
        for (final password in validPasswords) {
          final result = InputValidator.validatePassword(password);
          expect(result.isValid, isTrue, reason: 'Password should be valid');
        }
        
        for (final password in invalidPasswords) {
          final result = InputValidator.validatePassword(password);
          expect(result.isValid, isFalse, reason: 'Password should be invalid');
        }
      });
      
      test('should validate batch inputs correctly', () {
        final inputs = {
          'email': 'test@example.com',
          'nid': '1234567890',
          'name': 'John Doe',
          'wallet_address': '0x742d35Cc6634C0532925a3b8D404fBaF7c0C7D96',
        };
        
        final results = InputValidator.validateBatch(inputs);
        expect(results, hasLength(4));
        expect(InputValidator.areAllValid(results), isTrue);
      });
    });
    
    group('Memory Management Tests', () {
      test('should create and manage secure bytes', () {
        final memoryManager = MemoryManager();
        final initialStats = memoryManager.getMemoryStats();
        
        final secureData = memoryManager.createSecureBytes(100);
        expect(secureData.length, equals(100));
        
        final afterStats = memoryManager.getMemoryStats();
        expect(afterStats.activeSensitiveDataCount, 
               greaterThan(initialStats.activeSensitiveDataCount));
      });
      
      test('should convert string to secure bytes', () {
        final memoryManager = MemoryManager();
        const testString = 'sensitive data';
        
        final secureBytes = memoryManager.stringToSecureBytes(testString);
        expect(secureBytes.length, equals(testString.length));
        
        final convertedBack = memoryManager.secureBytesToString(secureBytes);
        expect(convertedBack, equals(testString));
      });
      
      test('should force cleanup of sensitive data', () {
        final memoryManager = MemoryManager();
        
        // Create some sensitive data
        for (int i = 0; i < 10; i++) {
          memoryManager.createSecureBytes(100);
        }
        
        final beforeCleanup = memoryManager.getMemoryStats();
        expect(beforeCleanup.activeSensitiveDataCount, greaterThan(0));
        
        memoryManager.forceCleanup();
        
        final afterCleanup = memoryManager.getMemoryStats();
        expect(afterCleanup.activeSensitiveDataCount, equals(0));
      });
      
      test('should create secure disposable resources', () {
        final memoryManager = MemoryManager();
        bool disposed = false;
        
        final disposable = memoryManager.createSecureDisposable(
          'test resource',
          (resource) => disposed = true,
        );
        
        expect(disposable.resource, equals('test resource'));
        expect(disposed, isFalse);
        
        disposable.dispose();
        expect(disposed, isTrue);
        expect(disposable.isDisposed, isTrue);
      });
      
      test('should handle memory stats correctly', () {
        final memoryManager = MemoryManager();
        final stats = memoryManager.getMemoryStats();
        
        expect(stats.activeSensitiveDataCount, isA<int>());
        expect(stats.activeSensitiveStringCount, isA<int>());
        expect(stats.activeCleanupTimers, isA<int>());
        expect(stats.memoryLogEntries, isA<int>());
      });
    });
    
    group('Security Audit Tests', () {
      setUpAll(() async {
        await SecurityAudit.initialize();
      });
      
      test('should run complete security audit', () async {
        final report = await SecurityAudit.runCompleteAudit();
        
        expect(report.version, isNotEmpty);
        expect(report.checkResults, isNotEmpty);
        expect(report.testResults, isNotEmpty);
        expect(report.securityScore, isA<int>());
        expect(report.securityScore, inInclusiveRange(0, 100));
      });
      
      test('should run individual security checks', () async {
        final result = await SecurityAudit.runSecurityCheck('secure_storage_init');
        
        expect(result.check.id, equals('secure_storage_init'));
        expect(result.passed, isA<bool>());
        expect(result.message, isNotEmpty);
        expect(result.timestamp, isA<DateTime>());
      });
      
      test('should run individual vulnerability tests', () async {
        final result = await SecurityAudit.runVulnerabilityTest('xss_test');
        
        expect(result.test.id, equals('xss_test'));
        expect(result.vulnerable, isA<bool>());
        expect(result.message, isNotEmpty);
        expect(result.timestamp, isA<DateTime>());
      });
      
      test('should handle invalid check IDs', () async {
        expect(
          () => SecurityAudit.runSecurityCheck('invalid_check_id'),
          throwsArgumentError,
        );
      });
      
      test('should handle invalid test IDs', () async {
        expect(
          () => SecurityAudit.runVulnerabilityTest('invalid_test_id'),
          throwsArgumentError,
        );
      });
      
      test('should calculate security score correctly', () async {
        final report = await SecurityAudit.runCompleteAudit();
        final score = report.securityScore;
        
        expect(score, inInclusiveRange(0, 100));
        
        // If there are critical failures, score should be lower
        final criticalFailures = report.failedChecks
            .where((r) => r.check.severity == SecuritySeverity.critical)
            .length;
        
        if (criticalFailures > 0) {
          expect(score, lessThan(80));
        }
      });
      
      test('should identify failed checks and vulnerabilities', () async {
        final report = await SecurityAudit.runCompleteAudit();
        
        final failedChecks = report.failedChecks;
        final vulnerabilities = report.detectedVulnerabilities;
        
        expect(failedChecks, isA<List<SecurityCheckResult>>());
        expect(vulnerabilities, isA<List<VulnerabilityTestResult>>());
        
        // Each failed check should have a reason
        for (final failure in failedChecks) {
          expect(failure.message, isNotEmpty);
          expect(failure.passed, isFalse);
        }
        
        // Each vulnerability should have details
        for (final vuln in vulnerabilities) {
          expect(vuln.message, isNotEmpty);
          expect(vuln.vulnerable, isTrue);
        }
      });
    });
    
    group('Integration Security Tests', () {
      test('should handle secure storage with input validation', () async {
        const testEmail = 'test@example.com';
        const testNID = '1234567890';
        
        // Validate inputs before storing
        final emailValidation = InputValidator.validateEmail(testEmail);
        final nidValidation = InputValidator.validateNID(testNID);
        
        expect(emailValidation.isValid, isTrue);
        expect(nidValidation.isValid, isTrue);
        
        // Store validated data
        final credentials = {
          'email': testEmail,
          'nid': testNID,
        };
        
        await SecureStorageConfig.storeUserCredentials(credentials);
        final retrieved = await SecureStorageConfig.getUserCredentials();
        
        expect(retrieved, equals(credentials));
        
        // Clean up
        await SecureStorageConfig.deleteKey(SecureStorageConfig.userCredentialsKey);
      });
      
      test('should handle memory management with secure storage', () async {
        final memoryManager = MemoryManager();
        const sensitiveData = 'private_key_data';
        
        // Convert to secure bytes
        final secureBytes = memoryManager.stringToSecureBytes(sensitiveData);
        
        // Store in secure storage
        await SecureStorageConfig.storePrivateKey(sensitiveData);
        
        // Retrieve and verify
        final retrieved = await SecureStorageConfig.getPrivateKey();
        expect(retrieved, equals(sensitiveData));
        
        // Clean up memory
        memoryManager.forceCleanup();
        
        // Clean up storage
        await SecureStorageConfig.deleteKey(SecureStorageConfig.privateKeyKey);
      });
      
      test('should validate and sanitize before secure operations', () async {
        const rawInput = '<script>alert("xss")</script>test@example.com';
        
        // Sanitize input
        final sanitized = InputValidator.sanitizeInput(rawInput);
        expect(sanitized, isNot(contains('<script>')));
        
        // Validate sanitized input
        final validation = InputValidator.validateEmail(sanitized);
        
        // Only store if validation passes
        if (validation.isValid) {
          await SecureStorageConfig.storeUserCredentials({'email': sanitized});
          final retrieved = await SecureStorageConfig.getUserCredentials();
          expect(retrieved?['email'], equals(sanitized));
          
          // Clean up
          await SecureStorageConfig.deleteKey(SecureStorageConfig.userCredentialsKey);
        }
      });
    });
    
    group('Error Handling Security Tests', () {
      test('should handle secure storage errors gracefully', () async {
        // Test with null values
        expect(
          () => SecureStorageConfig.storePrivateKey(''),
          returnsNormally,
        );
        
        // Test retrieving non-existent keys
        final nonExistent = await SecureStorageConfig.getPrivateKey();
        expect(nonExistent, isNull);
      });
      
      test('should handle input validation errors gracefully', () {
        // Test with null inputs
        final nullResult = InputValidator.validateEmail(null);
        expect(nullResult.isValid, isFalse);
        
        // Test with empty inputs
        final emptyResult = InputValidator.validateEmail('');
        expect(emptyResult.isValid, isFalse);
        
        // Test with malformed inputs
        final malformedResult = InputValidator.validateWalletAddress('invalid');
        expect(malformedResult.isValid, isFalse);
      });
      
      test('should handle memory management errors gracefully', () {
        final memoryManager = MemoryManager();
        
        // Test with invalid operations
        expect(
          () => memoryManager.forceCleanup(),
          returnsNormally,
        );
        
        // Test stats retrieval
        final stats = memoryManager.getMemoryStats();
        expect(stats, isNotNull);
      });
    });
  });
}