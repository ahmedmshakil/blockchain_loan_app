import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../lib/providers/app_state_provider.dart';
import '../../lib/providers/blockchain_provider.dart';
import '../../lib/providers/loan_provider.dart';
import '../../lib/providers/cache_manager.dart';
import '../../lib/providers/provider_registry.dart';
import '../../lib/models/loan_model.dart';
import '../../lib/services/credit_scoring_service.dart';
import '../../lib/utils/constants.dart';

void main() {
  group('State Management Tests', () {
    late AppStateProvider appStateProvider;
    late BlockchainProvider blockchainProvider;
    late LoanProvider loanProvider;
    late CacheManager cacheManager;

    setUp(() {
      appStateProvider = AppStateProvider.instance;
      blockchainProvider = BlockchainProvider.instance;
      loanProvider = LoanProvider.instance;
      cacheManager = CacheManager.instance;
    });

    test('should create provider instances', () {
      expect(appStateProvider, isNotNull);
      expect(blockchainProvider, isNotNull);
      expect(loanProvider, isNotNull);
      expect(cacheManager, isNotNull);
    });

    test('should have correct initial state', () {
      expect(appStateProvider.currentBorrower, isNull);
      expect(appStateProvider.currentCreditScore, isNull);
      expect(appStateProvider.isLoadingBorrower, isFalse);
      expect(appStateProvider.hasError, isFalse);
      
      expect(blockchainProvider.isConnected, isFalse);
      expect(blockchainProvider.isInitialized, isFalse);
      
      expect(loanProvider.loanApplications, isEmpty);
      expect(loanProvider.isProcessingApplication, isFalse);
      expect(loanProvider.requestedAmount, BigInt.zero);
    });

    test('should validate loan application data', () {
      final creditScoringService = CreditScoringService.instance;
      final validation = creditScoringService.validateLoanApplication(
        nid: DemoUserData.nid,
        requestedAmount: BigInt.from(50000),
        monthlyIncome: BigInt.from(65000),
      );
      
      expect(validation['isValid'], isTrue);
      expect(validation['errors'], isEmpty);
    });

    test('should handle cache statistics', () {
      final stats = cacheManager.getCacheStatistics();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('memoryEntries'), isTrue);
      expect(stats.containsKey('cacheHits'), isTrue);
      expect(stats.containsKey('cacheMisses'), isTrue);
      expect(stats.containsKey('hitRatio'), isTrue);
    });

    test('should create MultiProvider widget', () {
      final widget = ProviderRegistry.createMultiProvider(
        child: const Text('Test'),
      );
      
      expect(widget, isA<MultiProvider>());
    });

    testWidgets('should provide context to widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderRegistry.createMultiProvider(
            child: Builder(
              builder: (context) {
                final appState = context.read<AppStateProvider>();
                final blockchain = context.read<BlockchainProvider>();
                final loan = context.read<LoanProvider>();
                final cache = context.read<CacheManager>();
                
                return Column(
                  children: [
                    Text('App State: ${appState.isInitialized}'),
                    Text('Blockchain: ${blockchain.isConnected}'),
                    Text('Loans: ${loan.loanApplications.length}'),
                    Text('Cache: ${cache.cacheHits}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('App State: false'), findsOneWidget);
      expect(find.text('Blockchain: false'), findsOneWidget);
      expect(find.text('Loans: 0'), findsOneWidget);
      expect(find.text('Cache: 0'), findsOneWidget);
    });

    test('should handle loan form data updates', () {
      final initialAmount = loanProvider.requestedAmount;
      final initialIncome = loanProvider.monthlyIncome;
      
      loanProvider.setLoanApplicationData(
        requestedAmount: BigInt.from(100000),
        monthlyIncome: BigInt.from(80000),
        loanType: LoanType.business,
      );
      
      expect(loanProvider.requestedAmount, BigInt.from(100000));
      expect(loanProvider.monthlyIncome, BigInt.from(80000));
      expect(loanProvider.selectedLoanType, LoanType.business);
      
      // Reset to initial values
      loanProvider.setLoanApplicationData(
        requestedAmount: initialAmount,
        monthlyIncome: initialIncome,
        loanType: LoanType.personal,
      );
    });

    test('should handle data freshness checks', () {
      final freshness = appStateProvider.getDataFreshnessStatus();
      
      expect(freshness, isA<Map<String, dynamic>>());
      expect(freshness.containsKey('borrowerDataFresh'), isTrue);
      expect(freshness.containsKey('creditScoreDataFresh'), isTrue);
      expect(freshness.containsKey('networkStatusFresh'), isTrue);
    });

    test('should clear cache data', () async {
      // Add some test data to cache first
      await cacheManager.clearAllCache();
      
      final stats = cacheManager.getCacheStatistics();
      expect(stats['memoryEntries'], 0);
    });
  });
}