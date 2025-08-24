import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';

/// Performance optimization utilities
class PerformanceUtils {
  static final Map<String, Timer> _debounceTimers = {};
  static final Map<String, dynamic> _cache = {};
  static const int _maxCacheSize = 100;

  /// Debounce function calls to prevent excessive API calls
  static void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }

  /// Simple memory cache for frequently accessed data
  static void cacheData(String key, dynamic data) {
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry (simple FIFO)
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    _cache[key] = data;
  }

  /// Retrieve cached data
  static T? getCachedData<T>(String key) {
    return _cache[key] as T?;
  }

  /// Clear specific cache entry
  static void clearCache(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  static void clearAllCache() {
    _cache.clear();
  }

  /// Optimize image loading by reducing memory usage
  static void optimizeImageCache() {
    // Clear image cache when memory is low
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Memory cleanup utility
  static void performMemoryCleanup() {
    if (kDebugMode) {
      developer.log('Performing memory cleanup', name: 'PerformanceUtils');
    }
    
    // Clear image cache
    optimizeImageCache();
    
    // Clear old cache entries
    if (_cache.length > _maxCacheSize ~/ 2) {
      final keysToRemove = _cache.keys.take(_cache.length ~/ 2).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
    }
    
    // Cancel old debounce timers
    _debounceTimers.removeWhere((key, timer) {
      if (!timer.isActive) {
        timer.cancel();
        return true;
      }
      return false;
    });
    
    // Force garbage collection in debug mode
    if (kDebugMode) {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  /// Measure function execution time
  static Future<T> measureExecutionTime<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      if (kDebugMode) {
        developer.log(
          '$operationName completed in ${stopwatch.elapsedMilliseconds}ms',
          name: 'PerformanceUtils',
        );
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      if (kDebugMode) {
        developer.log(
          '$operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e',
          name: 'PerformanceUtils',
        );
      }
      
      rethrow;
    }
  }

  /// Batch multiple operations to reduce UI rebuilds
  static Future<List<T>> batchOperations<T>(
    List<Future<T> Function()> operations, {
    int batchSize = 5,
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((op) => op()),
      );
      results.addAll(batchResults);
      
      // Small delay between batches to prevent blocking UI
      if (i + batchSize < operations.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    
    return results;
  }

  /// Preload critical data
  static Future<void> preloadCriticalData() async {
    if (kDebugMode) {
      developer.log('Preloading critical data', name: 'PerformanceUtils');
    }
    
    // This would typically preload user data, blockchain connection, etc.
    // For now, we'll just simulate the process
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Monitor memory usage (debug only)
  static void monitorMemoryUsage() {
    if (!kDebugMode) return;
    
    Timer.periodic(const Duration(seconds: 30), (timer) {
      final imageCache = PaintingBinding.instance.imageCache;
      developer.log(
        'Memory usage - Image cache: ${imageCache.currentSize}/${imageCache.maximumSize}, '
        'Live images: ${imageCache.liveImageCount}',
        name: 'PerformanceUtils',
      );
    });
  }

  /// Dispose all resources
  static void dispose() {
    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    
    // Clear cache
    _cache.clear();
    
    if (kDebugMode) {
      developer.log('PerformanceUtils disposed', name: 'PerformanceUtils');
    }
  }
}

/// Mixin for widgets that need performance optimization
mixin PerformanceOptimizedWidget {
  /// Cache key for this widget
  String get cacheKey;
  
  /// Whether this widget should use caching
  bool get shouldCache => true;
  
  /// Cache widget data
  void cacheWidgetData(dynamic data) {
    if (shouldCache) {
      PerformanceUtils.cacheData(cacheKey, data);
    }
  }
  
  /// Get cached widget data
  T? getCachedWidgetData<T>() {
    if (shouldCache) {
      return PerformanceUtils.getCachedData<T>(cacheKey);
    }
    return null;
  }
  
  /// Clear widget cache
  void clearWidgetCache() {
    PerformanceUtils.clearCache(cacheKey);
  }
}