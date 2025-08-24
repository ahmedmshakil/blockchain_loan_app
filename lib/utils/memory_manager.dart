import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Memory management utility for secure data cleanup and resource management
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();
  
  // Track sensitive data for cleanup
  final Set<WeakReference<Uint8List>> _sensitiveData = <WeakReference<Uint8List>>{};
  final Set<WeakReference<String>> _sensitiveStrings = <WeakReference<String>>{};
  final Map<String, Timer> _cleanupTimers = <String, Timer>{};
  final Queue<String> _memoryLog = Queue<String>();
  
  static const int _maxLogEntries = 100;
  static const Duration _defaultCleanupDelay = Duration(minutes: 5);
  
  /// Register sensitive data for automatic cleanup
  void registerSensitiveData(Uint8List data, {Duration? cleanupDelay}) {
    _sensitiveData.add(WeakReference(data));
    
    final delay = cleanupDelay ?? _defaultCleanupDelay;
    final timerId = DateTime.now().millisecondsSinceEpoch.toString();
    
    _cleanupTimers[timerId] = Timer(delay, () {
      _secureClearBytes(data);
      _cleanupTimers.remove(timerId);
    });
    
    _logMemoryOperation('Registered sensitive data: ${data.length} bytes');
  }
  
  /// Register sensitive string for automatic cleanup
  void registerSensitiveString(String data, {Duration? cleanupDelay}) {
    _sensitiveStrings.add(WeakReference(data));
    
    final delay = cleanupDelay ?? _defaultCleanupDelay;
    final timerId = DateTime.now().millisecondsSinceEpoch.toString();
    
    _cleanupTimers[timerId] = Timer(delay, () {
      // Note: Strings in Dart are immutable, so we can't actually clear them
      // But we can remove references and rely on GC
      _cleanupTimers.remove(timerId);
    });
    
    _logMemoryOperation('Registered sensitive string: ${data.length} characters');
  }
  
  /// Securely clear byte array
  void _secureClearBytes(Uint8List data) {
    try {
      // Overwrite with random data multiple times
      for (int pass = 0; pass < 3; pass++) {
        for (int i = 0; i < data.length; i++) {
          data[i] = (DateTime.now().millisecondsSinceEpoch + i) % 256;
        }
      }
      
      // Final pass with zeros
      data.fillRange(0, data.length, 0);
      
      _logMemoryOperation('Securely cleared ${data.length} bytes');
    } catch (e) {
      _logMemoryOperation('Failed to clear bytes: $e');
    }
  }
  
  /// Create secure byte array that will be automatically cleaned up
  Uint8List createSecureBytes(int length, {Duration? cleanupDelay}) {
    final data = Uint8List(length);
    registerSensitiveData(data, cleanupDelay: cleanupDelay);
    return data;
  }
  
  /// Copy string to secure byte array
  Uint8List stringToSecureBytes(String input, {Duration? cleanupDelay}) {
    final bytes = Uint8List.fromList(input.codeUnits);
    registerSensitiveData(bytes, cleanupDelay: cleanupDelay);
    return bytes;
  }
  
  /// Convert secure bytes back to string (use with caution)
  String secureBytesToString(Uint8List bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (e) {
      _logMemoryOperation('Failed to convert bytes to string: $e');
      return '';
    }
  }
  
  /// Force cleanup of all registered sensitive data
  void forceCleanup() {
    try {
      // Clear all timers
      for (final timer in _cleanupTimers.values) {
        timer.cancel();
      }
      _cleanupTimers.clear();
      
      // Clear sensitive data
      for (final ref in _sensitiveData) {
        final data = ref.target;
        if (data != null) {
          _secureClearBytes(data);
        }
      }
      _sensitiveData.clear();
      
      // Clear string references
      _sensitiveStrings.clear();
      
      // Force garbage collection
      _forceGarbageCollection();
      
      _logMemoryOperation('Forced cleanup completed');
    } catch (e) {
      _logMemoryOperation('Force cleanup failed: $e');
    }
  }
  
  /// Force garbage collection (best effort)
  void _forceGarbageCollection() {
    try {
      // Create and immediately discard large objects to trigger GC
      for (int i = 0; i < 10; i++) {
        final dummy = List.filled(1000000, 0);
        dummy.clear();
      }
    } catch (e) {
      // Ignore errors in GC forcing
    }
  }
  
  /// Get memory usage statistics
  MemoryStats getMemoryStats() {
    // Clean up dead references
    _sensitiveData.removeWhere((ref) => ref.target == null);
    _sensitiveStrings.removeWhere((ref) => ref.target == null);
    
    return MemoryStats(
      activeSensitiveDataCount: _sensitiveData.length,
      activeSensitiveStringCount: _sensitiveStrings.length,
      activeCleanupTimers: _cleanupTimers.length,
      memoryLogEntries: _memoryLog.length,
    );
  }
  
  /// Log memory operation
  void _logMemoryOperation(String operation) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $operation';
    
    _memoryLog.addLast(logEntry);
    
    // Keep log size manageable
    while (_memoryLog.length > _maxLogEntries) {
      _memoryLog.removeFirst();
    }
    
    if (kDebugMode) {
      print('MemoryManager: $operation');
    }
  }
  
  /// Get memory operation log
  List<String> getMemoryLog() {
    return List.from(_memoryLog);
  }
  
  /// Clear memory log
  void clearMemoryLog() {
    _memoryLog.clear();
    _logMemoryOperation('Memory log cleared');
  }
  
  /// Schedule periodic cleanup
  Timer schedulePeriodicCleanup({Duration interval = const Duration(minutes: 10)}) {
    return Timer.periodic(interval, (timer) {
      _performPeriodicCleanup();
    });
  }
  
  /// Perform periodic cleanup of dead references
  void _performPeriodicCleanup() {
    final initialDataCount = _sensitiveData.length;
    final initialStringCount = _sensitiveStrings.length;
    
    // Remove dead references
    _sensitiveData.removeWhere((ref) => ref.target == null);
    _sensitiveStrings.removeWhere((ref) => ref.target == null);
    
    final cleanedDataCount = initialDataCount - _sensitiveData.length;
    final cleanedStringCount = initialStringCount - _sensitiveStrings.length;
    
    if (cleanedDataCount > 0 || cleanedStringCount > 0) {
      _logMemoryOperation(
        'Periodic cleanup: removed $cleanedDataCount data refs, $cleanedStringCount string refs'
      );
    }
  }
  
  /// Create a secure disposable resource
  SecureDisposable<T> createSecureDisposable<T>(
    T resource,
    void Function(T) disposer, {
    Duration? autoDisposeDelay,
  }) {
    return SecureDisposable<T>(
      resource,
      disposer,
      autoDisposeDelay: autoDisposeDelay,
    );
  }
  
  /// Monitor memory pressure and cleanup if needed
  void monitorMemoryPressure() {
    // Listen to system memory warnings
    SystemChannels.system.setMessageHandler((message) async {
      if (message != null && message is Map && message['type'] == 'memoryPressure') {
        _logMemoryOperation('Memory pressure detected, performing cleanup');
        _performEmergencyCleanup();
      }
      return null;
    });
  }
  
  /// Perform emergency cleanup when memory pressure is detected
  void _performEmergencyCleanup() {
    try {
      // Cancel non-essential timers
      final timersToCancel = _cleanupTimers.length ~/ 2;
      final timerKeys = _cleanupTimers.keys.take(timersToCancel).toList();
      
      for (final key in timerKeys) {
        _cleanupTimers[key]?.cancel();
        _cleanupTimers.remove(key);
      }
      
      // Force cleanup of oldest sensitive data
      final dataToCleanup = _sensitiveData.take(_sensitiveData.length ~/ 2).toList();
      for (final ref in dataToCleanup) {
        final data = ref.target;
        if (data != null) {
          _secureClearBytes(data);
        }
      }
      
      // Remove cleaned references
      _sensitiveData.removeWhere((ref) => dataToCleanup.contains(ref));
      
      // Force garbage collection
      _forceGarbageCollection();
      
      _logMemoryOperation('Emergency cleanup completed');
    } catch (e) {
      _logMemoryOperation('Emergency cleanup failed: $e');
    }
  }
  
  /// Dispose of the memory manager
  void dispose() {
    forceCleanup();
    _memoryLog.clear();
    _logMemoryOperation('MemoryManager disposed');
  }
}

/// Memory statistics
class MemoryStats {
  final int activeSensitiveDataCount;
  final int activeSensitiveStringCount;
  final int activeCleanupTimers;
  final int memoryLogEntries;
  
  const MemoryStats({
    required this.activeSensitiveDataCount,
    required this.activeSensitiveStringCount,
    required this.activeCleanupTimers,
    required this.memoryLogEntries,
  });
  
  @override
  String toString() {
    return 'MemoryStats('
        'sensitiveData: $activeSensitiveDataCount, '
        'sensitiveStrings: $activeSensitiveStringCount, '
        'timers: $activeCleanupTimers, '
        'logEntries: $memoryLogEntries'
        ')';
  }
}

/// Secure disposable resource wrapper
class SecureDisposable<T> {
  T? _resource;
  final void Function(T) _disposer;
  Timer? _autoDisposeTimer;
  bool _isDisposed = false;
  
  SecureDisposable(
    T resource,
    this._disposer, {
    Duration? autoDisposeDelay,
  }) : _resource = resource {
    if (autoDisposeDelay != null) {
      _autoDisposeTimer = Timer(autoDisposeDelay, dispose);
    }
  }
  
  /// Get the resource (throws if disposed)
  T get resource {
    if (_isDisposed || _resource == null) {
      throw StateError('Resource has been disposed');
    }
    return _resource!;
  }
  
  /// Check if resource is disposed
  bool get isDisposed => _isDisposed;
  
  /// Dispose of the resource
  void dispose() {
    if (_isDisposed) return;
    
    _autoDisposeTimer?.cancel();
    _autoDisposeTimer = null;
    
    if (_resource != null) {
      try {
        _disposer(_resource!);
      } catch (e) {
        if (kDebugMode) {
          print('Error disposing resource: $e');
        }
      }
      _resource = null;
    }
    
    _isDisposed = true;
  }
}

/// Extension for automatic memory management
extension SecureString on String {
  /// Convert string to secure bytes with automatic cleanup
  Uint8List toSecureBytes({Duration? cleanupDelay}) {
    return MemoryManager().stringToSecureBytes(this, cleanupDelay: cleanupDelay);
  }
}

extension SecureUint8List on Uint8List {
  /// Register for automatic secure cleanup
  void registerForCleanup({Duration? cleanupDelay}) {
    MemoryManager().registerSensitiveData(this, cleanupDelay: cleanupDelay);
  }
  
  /// Securely clear this byte array
  void secureClear() {
    MemoryManager()._secureClearBytes(this);
  }
}