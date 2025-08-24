import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state_provider.dart';
import 'blockchain_provider.dart';
import 'loan_provider.dart';
import 'cache_manager.dart';
import 'state_synchronization_service.dart';

/// Provider registry for managing all application providers
/// Provides centralized provider configuration and initialization
/// Requirements: 2.3, 5.4, 7.4
class ProviderRegistry {
  static ProviderRegistry? _instance;
  
  // Provider instances
  late final AppStateProvider _appStateProvider;
  late final BlockchainProvider _blockchainProvider;
  late final LoanProvider _loanProvider;
  late final CacheManager _cacheManager;
  late final StateSynchronizationService _syncService;
  
  // Initialization state
  bool _isInitialized = false;
  
  /// Check if providers are initialized
  static bool get isInitialized => instance._isInitialized;
  
  // Singleton pattern
  static ProviderRegistry get instance {
    _instance ??= ProviderRegistry._internal();
    return _instance!;
  }
  
  ProviderRegistry._internal() {
    _initializeProviders();
  }
  
  // Getters for provider instances
  AppStateProvider get appState => _appStateProvider;
  BlockchainProvider get blockchain => _blockchainProvider;
  LoanProvider get loan => _loanProvider;
  CacheManager get cache => _cacheManager;
  StateSynchronizationService get sync => _syncService;
  

  
  /// Initialize all providers
  void _initializeProviders() {
    _appStateProvider = AppStateProvider.instance;
    _blockchainProvider = BlockchainProvider.instance;
    _loanProvider = LoanProvider.instance;
    _cacheManager = CacheManager.instance;
    _syncService = StateSynchronizationService.instance;
    
    _isInitialized = true;
  }
  
  /// Create MultiProvider widget with all providers
  /// Requirements: 2.3, 5.4, 7.4
  static Widget createMultiProvider({required Widget child}) {
    final registry = ProviderRegistry.instance;
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateProvider>.value(
          value: registry._appStateProvider,
        ),
        ChangeNotifierProvider<BlockchainProvider>.value(
          value: registry._blockchainProvider,
        ),
        ChangeNotifierProvider<LoanProvider>.value(
          value: registry._loanProvider,
        ),
        ChangeNotifierProvider<CacheManager>.value(
          value: registry._cacheManager,
        ),
      ],
      child: child,
    );
  }
  
  /// Initialize all providers with application startup
  /// Requirements: 2.3, 7.4
  static Future<void> initializeAll() async {
    final registry = ProviderRegistry.instance;
    
    try {
      // Initialize blockchain provider first
      await registry._blockchainProvider.initialize();
      
      // Initialize app state provider
      await registry._appStateProvider.initialize();
      
      // Initialize state synchronization service
      await registry._syncService.initialize(
        appStateProvider: registry._appStateProvider,
        blockchainProvider: registry._blockchainProvider,
        loanProvider: registry._loanProvider,
        cacheManager: registry._cacheManager,
      );
      
      // Loan provider doesn't need async initialization
      // Cache manager starts automatically
      
    } catch (e) {
      // Handle initialization errors
      rethrow;
    }
  }
  
  /// Dispose all providers
  static void disposeAll() {
    final registry = _instance;
    if (registry != null) {
      registry._syncService.dispose();
      registry._appStateProvider.dispose();
      registry._blockchainProvider.dispose();
      registry._loanProvider.dispose();
      registry._cacheManager.dispose();
      
      _instance = null;
    }
  }
}

/// Provider-aware widget mixin for easy provider access
/// Requirements: 2.3, 5.4
mixin ProviderAware<T extends StatefulWidget> on State<T> {
  AppStateProvider get appState => context.read<AppStateProvider>();
  BlockchainProvider get blockchain => context.read<BlockchainProvider>();
  LoanProvider get loan => context.read<LoanProvider>();
  CacheManager get cache => context.read<CacheManager>();
  
  // Watch methods for reactive updates
  AppStateProvider watchAppState() => context.watch<AppStateProvider>();
  BlockchainProvider watchBlockchain() => context.watch<BlockchainProvider>();
  LoanProvider watchLoan() => context.watch<LoanProvider>();
  CacheManager watchCache() => context.watch<CacheManager>();
}

/// Provider-aware stateless widget base class
/// Requirements: 2.3, 5.4
abstract class ProviderAwareWidget extends StatelessWidget {
  const ProviderAwareWidget({super.key});
  
  // Provider access methods
  AppStateProvider appState(BuildContext context) => context.read<AppStateProvider>();
  BlockchainProvider blockchain(BuildContext context) => context.read<BlockchainProvider>();
  LoanProvider loan(BuildContext context) => context.read<LoanProvider>();
  CacheManager cache(BuildContext context) => context.read<CacheManager>();
  
  // Watch methods for reactive updates
  AppStateProvider watchAppState(BuildContext context) => context.watch<AppStateProvider>();
  BlockchainProvider watchBlockchain(BuildContext context) => context.watch<BlockchainProvider>();
  LoanProvider watchLoan(BuildContext context) => context.watch<LoanProvider>();
  CacheManager watchCache(BuildContext context) => context.watch<CacheManager>();
}

/// Consumer widgets for specific providers
/// Requirements: 2.3, 5.4

class AppStateConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, AppStateProvider appState, Widget? child) builder;
  final Widget? child;
  
  const AppStateConsumer({
    super.key,
    required this.builder,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: builder,
      child: child,
    );
  }
}

class BlockchainConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, BlockchainProvider blockchain, Widget? child) builder;
  final Widget? child;
  
  const BlockchainConsumer({
    super.key,
    required this.builder,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<BlockchainProvider>(
      builder: builder,
      child: child,
    );
  }
}

class LoanConsumer extends StatelessWidget {
  final Widget Function(BuildContext context, LoanProvider loan, Widget? child) builder;
  final Widget? child;
  
  const LoanConsumer({
    super.key,
    required this.builder,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: builder,
      child: child,
    );
  }
}

/// Multi-consumer for multiple providers
/// Requirements: 2.3, 5.4
class MultiProviderConsumer extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    AppStateProvider appState,
    BlockchainProvider blockchain,
    LoanProvider loan,
    Widget? child,
  ) builder;
  final Widget? child;
  
  const MultiProviderConsumer({
    super.key,
    required this.builder,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer3<AppStateProvider, BlockchainProvider, LoanProvider>(
      builder: (context, appState, blockchain, loan, child) {
        return builder(context, appState, blockchain, loan, child);
      },
      child: child,
    );
  }
}