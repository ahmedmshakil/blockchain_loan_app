import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure storage configuration for managing sensitive data like private keys
class SecureStorageConfig {
  // Storage instance with security options
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.bankofiub.blockchain_loan_app',
      accountName: 'blockchain_loan_app_keychain',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    lOptions: LinuxOptions(),
    webOptions: WebOptions(
      dbName: 'blockchain_loan_app_secure_db',
      publicKey: 'blockchain_loan_app_public_key',
    ),
    mOptions: MacOsOptions(
      groupId: 'group.com.bankofiub.blockchain_loan_app',
      accountName: 'blockchain_loan_app_keychain',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
  );
  
  // Storage keys
  static const String privateKeyKey = 'user_private_key';
  static const String walletAddressKey = 'user_wallet_address';
  static const String mnemonicKey = 'user_mnemonic';
  static const String userCredentialsKey = 'user_credentials';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String lastLoginKey = 'last_login_timestamp';
  
  /// Get the secure storage instance
  static FlutterSecureStorage get storage => _storage;
  
  /// Store private key securely
  static Future<void> storePrivateKey(String privateKey) async {
    try {
      await _storage.write(key: privateKeyKey, value: privateKey);
      if (kDebugMode) {
        print('Private key stored securely');
      }
    } catch (e) {
      throw SecureStorageException('Failed to store private key: $e');
    }
  }
  
  /// Retrieve private key
  static Future<String?> getPrivateKey() async {
    try {
      return await _storage.read(key: privateKeyKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve private key: $e');
    }
  }
  
  /// Store wallet address
  static Future<void> storeWalletAddress(String address) async {
    try {
      await _storage.write(key: walletAddressKey, value: address);
      if (kDebugMode) {
        print('Wallet address stored securely');
      }
    } catch (e) {
      throw SecureStorageException('Failed to store wallet address: $e');
    }
  }
  
  /// Retrieve wallet address
  static Future<String?> getWalletAddress() async {
    try {
      return await _storage.read(key: walletAddressKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve wallet address: $e');
    }
  }
  
  /// Store mnemonic phrase securely
  static Future<void> storeMnemonic(String mnemonic) async {
    try {
      await _storage.write(key: mnemonicKey, value: mnemonic);
      if (kDebugMode) {
        print('Mnemonic stored securely');
      }
    } catch (e) {
      throw SecureStorageException('Failed to store mnemonic: $e');
    }
  }
  
  /// Retrieve mnemonic phrase
  static Future<String?> getMnemonic() async {
    try {
      return await _storage.read(key: mnemonicKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve mnemonic: $e');
    }
  }
  
  /// Store user credentials (encrypted)
  static Future<void> storeUserCredentials(Map<String, String> credentials) async {
    try {
      final credentialsJson = credentials.entries
          .map((e) => '${e.key}:${e.value}')
          .join('|');
      await _storage.write(key: userCredentialsKey, value: credentialsJson);
      if (kDebugMode) {
        print('User credentials stored securely');
      }
    } catch (e) {
      throw SecureStorageException('Failed to store user credentials: $e');
    }
  }
  
  /// Retrieve user credentials
  static Future<Map<String, String>?> getUserCredentials() async {
    try {
      final credentialsJson = await _storage.read(key: userCredentialsKey);
      if (credentialsJson == null) return null;
      
      final credentials = <String, String>{};
      for (final entry in credentialsJson.split('|')) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          credentials[parts[0]] = parts[1];
        }
      }
      return credentials;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve user credentials: $e');
    }
  }
  
  /// Enable/disable biometric authentication
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: biometricEnabledKey, value: enabled.toString());
    } catch (e) {
      throw SecureStorageException('Failed to set biometric preference: $e');
    }
  }
  
  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }
  
  /// Store last login timestamp
  static Future<void> storeLastLogin() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.write(key: lastLoginKey, value: timestamp);
    } catch (e) {
      throw SecureStorageException('Failed to store last login: $e');
    }
  }
  
  /// Get last login timestamp
  static Future<DateTime?> getLastLogin() async {
    try {
      final timestamp = await _storage.read(key: lastLoginKey);
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    } catch (e) {
      return null;
    }
  }
  
  /// Check if storage contains a specific key
  static Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      return false;
    }
  }
  
  /// Delete a specific key
  static Future<void> deleteKey(String key) async {
    try {
      await _storage.delete(key: key);
      if (kDebugMode) {
        print('Deleted key: $key');
      }
    } catch (e) {
      throw SecureStorageException('Failed to delete key $key: $e');
    }
  }
  
  /// Clear all stored data (use with caution)
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      if (kDebugMode) {
        print('All secure storage data cleared');
      }
    } catch (e) {
      throw SecureStorageException('Failed to clear all data: $e');
    }
  }
  
  /// Get all stored keys (for debugging purposes)
  static Future<Map<String, String>> getAllData() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw SecureStorageException('Failed to read all data: $e');
    }
  }
  
  /// Initialize secure storage (check if it's working)
  static Future<bool> initialize() async {
    try {
      // Test write and read operation
      const testKey = 'test_key';
      const testValue = 'test_value';
      
      await _storage.write(key: testKey, value: testValue);
      final readValue = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);
      
      return readValue == testValue;
    } catch (e) {
      if (kDebugMode) {
        print('Secure storage initialization failed: $e');
      }
      return false;
    }
  }
}

/// Custom exception for secure storage operations
class SecureStorageException implements Exception {
  final String message;
  
  const SecureStorageException(this.message);
  
  @override
  String toString() => 'SecureStorageException: $message';
}