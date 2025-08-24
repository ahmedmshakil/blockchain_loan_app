import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/borrower_model.dart';
import '../models/credit_score_model.dart';
import '../models/loan_model.dart';
import '../utils/constants.dart';

/// Cache manager for local data storage and retrieval
/// Provides secure caching for frequently accessed blockchain data
/// Requirements: 5.4, 7.4
class CacheManager extends ChangeNotifier {
  static CacheManager? _instance;
  
  // Secure storage for sensitive data
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // In-memory cache for quick access
  final Map<String, CacheEntry> _memoryCache = {};
  
  // Cache configuration
  static const Duration _defaultCacheExpiration = Duration(minutes: 5);
  static const Duration _shortCacheExpiration = Duration(minutes: 1);
  
  // Cache keys
  static const String _borrowerCachePrefix = 'borrower_';
  static const String _creditScoreCachePrefix = 'credit_score_';
  static const String _loanCachePrefix = 'loan_';
  static const String _networkStatusCacheKey = 'network_status';
  static const String _eligibilityCachePrefix = 'eligibility_';
  
  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _cacheEvictions = 0;
  
  // Singleton pattern
  static CacheManager get instance {
    _instance ??= CacheManager._internal();
    return _instance!;
  }
  
  CacheManager._internal() {
    _startCacheCleanup();
  }
  
  // Getters for cache statistics
  int get cacheHits => _cacheHits;
  int get cacheMisses => _cacheMisses;
  int get cacheEvictions => _cacheEvictions;
  double get cacheHitRatio => _cacheHits + _cacheMisses > 0 
      ? _cacheHits / (_cacheHits + _cacheMisses) 
      : 0.0;
  
  /// Cache borrower data
  /// Requirements: 5.4
  Future<void> cacheBorrowerData(String nid, BorrowerModel borrower, {Duration? expiration}) async {
    try {
      final key = _borrowerCachePrefix + nid;
      final cacheEntry = CacheEntry(
        data: borrower.toJson(),
        timestamp: DateTime.now(),
        expiration: expiration ?? _defaultCacheExpiration,
      );
      
      // Store in memory cache
      _memoryCache[key] = cacheEntry;
      
      // Store in secure storage for persistence
      await _secureStorage.write(
        key: key,
        value: jsonEncode(cacheEntry.toJson()),
      );
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Cached borrower data for NID: $nid', name: 'CacheManager');
      }
    } catch (e) {
      developer.log('Failed to cache borrower data: $e', name: 'CacheManager');
    }
  }
  
  /// Get cached borrower data
  /// Requirements: 5.4
  Future<BorrowerModel?> getCachedBorrowerData(String nid) async {
    try {
      final key = _borrowerCachePrefix + nid;
      
      // Check memory cache first
      var cacheEntry = _memoryCache[key];
      
      // If not in memory, check secure storage
      if (cacheEntry == null) {
        final storedData = await _secureStorage.read(key: key);
        if (storedData != null) {
          final entryJson = jsonDecode(storedData) as Map<String, dynamic>;
          cacheEntry = CacheEntry.fromJson(entryJson);
          
          // Add back to memory cache if still valid
          if (!cacheEntry.isExpired) {
            _memoryCache[key] = cacheEntry;
          }
        }
      }
      
      if (cacheEntry != null && !cacheEntry.isExpired) {
        _cacheHits++;
        
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Cache hit for borrower NID: $nid', name: 'CacheManager');
        }
        
        return BorrowerModel.fromJson(cacheEntry.data as Map<String, dynamic>);
      } else {
        _cacheMisses++;
        
        // Remove expired entry
        if (cacheEntry != null) {
          await _removeCacheEntry(key);
        }
        
        return null;
      }
    } catch (e) {
      developer.log('Failed to get cached borrower data: $e', name: 'CacheManager');
      _cacheMisses++;
      return null;
    }
  }
  
  /// Cache credit score data
  /// Requirements: 5.4
  Future<void> cacheCreditScoreData(String nid, CreditScoreModel creditScore, {Duration? expiration}) async {
    try {
      final key = _creditScoreCachePrefix + nid;
      final cacheEntry = CacheEntry(
        data: creditScore.toJson(),
        timestamp: DateTime.now(),
        expiration: expiration ?? _shortCacheExpiration, // Credit scores change frequently
      );
      
      _memoryCache[key] = cacheEntry;
      
      await _secureStorage.write(
        key: key,
        value: jsonEncode(cacheEntry.toJson()),
      );
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Cached credit score for NID: $nid', name: 'CacheManager');
      }
    } catch (e) {
      developer.log('Failed to cache credit score: $e', name: 'CacheManager');
    }
  }
  
  /// Get cached credit score data
  /// Requirements: 5.4
  Future<CreditScoreModel?> getCachedCreditScoreData(String nid) async {
    try {
      final key = _creditScoreCachePrefix + nid;
      
      var cacheEntry = _memoryCache[key];
      
      if (cacheEntry == null) {
        final storedData = await _secureStorage.read(key: key);
        if (storedData != null) {
          final entryJson = jsonDecode(storedData) as Map<String, dynamic>;
          cacheEntry = CacheEntry.fromJson(entryJson);
          
          if (!cacheEntry.isExpired) {
            _memoryCache[key] = cacheEntry;
          }
        }
      }
      
      if (cacheEntry != null && !cacheEntry.isExpired) {
        _cacheHits++;
        
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Cache hit for credit score NID: $nid', name: 'CacheManager');
        }
        
        return CreditScoreModel.fromJson(cacheEntry.data as Map<String, dynamic>);
      } else {
        _cacheMisses++;
        
        if (cacheEntry != null) {
          await _removeCacheEntry(key);
        }
        
        return null;
      }
    } catch (e) {
      developer.log('Failed to get cached credit score: $e', name: 'CacheManager');
      _cacheMisses++;
      return null;
    }
  }
  
  /// Cache loan data
  /// Requirements: 5.4
  Future<void> cacheLoanData(String loanId, LoanModel loan, {Duration? expiration}) async {
    try {
      final key = _loanCachePrefix + loanId;
      final cacheEntry = CacheEntry(
        data: loan.toJson(),
        timestamp: DateTime.now(),
        expiration: expiration ?? _defaultCacheExpiration,
      );
      
      _memoryCache[key] = cacheEntry;
      
      await _secureStorage.write(
        key: key,
        value: jsonEncode(cacheEntry.toJson()),
      );
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Cached loan data for ID: $loanId', name: 'CacheManager');
      }
    } catch (e) {
      developer.log('Failed to cache loan data: $e', name: 'CacheManager');
    }
  }
  
  /// Get cached loan data
  /// Requirements: 5.4
  Future<LoanModel?> getCachedLoanData(String loanId) async {
    try {
      final key = _loanCachePrefix + loanId;
      
      var cacheEntry = _memoryCache[key];
      
      if (cacheEntry == null) {
        final storedData = await _secureStorage.read(key: key);
        if (storedData != null) {
          final entryJson = jsonDecode(storedData) as Map<String, dynamic>;
          cacheEntry = CacheEntry.fromJson(entryJson);
          
          if (!cacheEntry.isExpired) {
            _memoryCache[key] = cacheEntry;
          }
        }
      }
      
      if (cacheEntry != null && !cacheEntry.isExpired) {
        _cacheHits++;
        return LoanModel.fromJson(cacheEntry.data as Map<String, dynamic>);
      } else {
        _cacheMisses++;
        
        if (cacheEntry != null) {
          await _removeCacheEntry(key);
        }
        
        return null;
      }
    } catch (e) {
      developer.log('Failed to get cached loan data: $e', name: 'CacheManager');
      _cacheMisses++;
      return null;
    }
  }
  
  /// Cache network status
  /// Requirements: 7.4
  Future<void> cacheNetworkStatus(Map<String, dynamic> status, {Duration? expiration}) async {
    try {
      final cacheEntry = CacheEntry(
        data: status,
        timestamp: DateTime.now(),
        expiration: expiration ?? _shortCacheExpiration,
      );
      
      _memoryCache[_networkStatusCacheKey] = cacheEntry;
      
      await _secureStorage.write(
        key: _networkStatusCacheKey,
        value: jsonEncode(cacheEntry.toJson()),
      );
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Cached network status', name: 'CacheManager');
      }
    } catch (e) {
      developer.log('Failed to cache network status: $e', name: 'CacheManager');
    }
  }
  
  /// Get cached network status
  /// Requirements: 7.4
  Future<Map<String, dynamic>?> getCachedNetworkStatus() async {
    try {
      var cacheEntry = _memoryCache[_networkStatusCacheKey];
      
      if (cacheEntry == null) {
        final storedData = await _secureStorage.read(key: _networkStatusCacheKey);
        if (storedData != null) {
          final entryJson = jsonDecode(storedData) as Map<String, dynamic>;
          cacheEntry = CacheEntry.fromJson(entryJson);
          
          if (!cacheEntry.isExpired) {
            _memoryCache[_networkStatusCacheKey] = cacheEntry;
          }
        }
      }
      
      if (cacheEntry != null && !cacheEntry.isExpired) {
        _cacheHits++;
        return cacheEntry.data as Map<String, dynamic>;
      } else {
        _cacheMisses++;
        
        if (cacheEntry != null) {
          await _removeCacheEntry(_networkStatusCacheKey);
        }
        
        return null;
      }
    } catch (e) {
      developer.log('Failed to get cached network status: $e', name: 'CacheManager');
      _cacheMisses++;
      return null;
    }
  }
  
  /// Cache eligibility assessment
  /// Requirements: 5.4
  Future<void> cacheEligibilityAssessment(String nid, BigInt amount, BigInt income, Map<String, dynamic> assessment) async {
    try {
      final key = '$_eligibilityCachePrefix${nid}_${amount}_$income';
      final cacheEntry = CacheEntry(
        data: assessment,
        timestamp: DateTime.now(),
        expiration: _shortCacheExpiration, // Eligibility changes frequently
      );
      
      _memoryCache[key] = cacheEntry;
      
      // Don't persist eligibility assessments to secure storage (they're temporary)
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Cached eligibility assessment for NID: $nid', name: 'CacheManager');
      }
    } catch (e) {
      developer.log('Failed to cache eligibility assessment: $e', name: 'CacheManager');
    }
  }
  
  /// Get cached eligibility assessment
  /// Requirements: 5.4
  Map<String, dynamic>? getCachedEligibilityAssessment(String nid, BigInt amount, BigInt income) {
    try {
      final key = '$_eligibilityCachePrefix${nid}_${amount}_$income';
      final cacheEntry = _memoryCache[key];
      
      if (cacheEntry != null && !cacheEntry.isExpired) {
        _cacheHits++;
        return cacheEntry.data as Map<String, dynamic>;
      } else {
        _cacheMisses++;
        
        if (cacheEntry != null) {
          _memoryCache.remove(key);
        }
        
        return null;
      }
    } catch (e) {
      developer.log('Failed to get cached eligibility assessment: $e', name: 'CacheManager');
      _cacheMisses++;
      return null;
    }
  }
  
  /// Clear all cache data
  Future<void> clearAllCache() async {
    try {
      _memoryCache.clear();
      await _secureStorage.deleteAll();
      
      _cacheHits = 0;
      _cacheMisses = 0;
      _cacheEvictions = 0;
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('All cache cleared', name: 'CacheManager');
      }
      
      notifyListeners();
    } catch (e) {
      developer.log('Failed to clear cache: $e', name: 'CacheManager');
    }
  }
  
  /// Clear cache for specific NID
  Future<void> clearCacheForNid(String nid) async {
    try {
      final keysToRemove = <String>[];
      
      // Find all keys related to this NID
      for (final key in _memoryCache.keys) {
        if (key.contains(nid)) {
          keysToRemove.add(key);
        }
      }
      
      // Remove from memory cache
      for (final key in keysToRemove) {
        _memoryCache.remove(key);
        await _secureStorage.delete(key: key);
      }
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Cache cleared for NID: $nid (${keysToRemove.length} entries)', name: 'CacheManager');
      }
      
      notifyListeners();
    } catch (e) {
      developer.log('Failed to clear cache for NID: $e', name: 'CacheManager');
    }
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'memoryEntries': _memoryCache.length,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'cacheEvictions': _cacheEvictions,
      'hitRatio': cacheHitRatio,
      'expiredEntries': _memoryCache.values.where((entry) => entry.isExpired).length,
    };
  }
  
  // Private helper methods
  
  /// Remove a cache entry from both memory and storage
  Future<void> _removeCacheEntry(String key) async {
    try {
      _memoryCache.remove(key);
      await _secureStorage.delete(key: key);
      _cacheEvictions++;
    } catch (e) {
      developer.log('Failed to remove cache entry: $e', name: 'CacheManager');
    }
  }
  
  /// Start periodic cache cleanup
  void _startCacheCleanup() {
    // Clean up expired entries every 5 minutes
    Stream.periodic(const Duration(minutes: 5)).listen((_) async {
      await _cleanupExpiredEntries();
    });
  }
  
  /// Clean up expired cache entries
  Future<void> _cleanupExpiredEntries() async {
    try {
      final expiredKeys = <String>[];
      
      // Find expired entries in memory cache
      for (final entry in _memoryCache.entries) {
        if (entry.value.isExpired) {
          expiredKeys.add(entry.key);
        }
      }
      
      // Remove expired entries
      for (final key in expiredKeys) {
        await _removeCacheEntry(key);
      }
      
      if (expiredKeys.isNotEmpty && EnvironmentConfig.enableDetailedLogging) {
        developer.log('Cleaned up ${expiredKeys.length} expired cache entries', name: 'CacheManager');
      }
    } catch (e) {
      developer.log('Failed to cleanup expired entries: $e', name: 'CacheManager');
    }
  }
  
  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }
}

/// Cache entry data structure
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration expiration;
  
  const CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiration,
  });
  
  bool get isExpired => DateTime.now().difference(timestamp) > expiration;
  
  Duration get age => DateTime.now().difference(timestamp);
  
  Duration get timeToExpiry => expiration - age;
  
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'expiration': expiration.inMilliseconds,
    };
  }
  
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiration: Duration(milliseconds: json['expiration'] as int),
    );
  }
  
  @override
  String toString() {
    return 'CacheEntry(age: ${age.inSeconds}s, expired: $isExpired)';
  }
}