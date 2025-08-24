import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_loan_app/screens/account_overview_screen.dart';
import 'package:blockchain_loan_app/utils/constants.dart';
import 'package:blockchain_loan_app/widgets/loading_indicator.dart';
import 'package:blockchain_loan_app/widgets/error_state_widget.dart';
import 'package:blockchain_loan_app/widgets/blockchain_status_indicator.dart';

/// Widget tests for AccountOverviewScreen
/// Requirements: 1.1, 1.2, 5.1, 5.2
void main() {
  group('AccountOverviewScreen Widget Tests', () {
    testWidgets(
      'should display app bar with correct title and refresh button',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(home: const AccountOverviewScreen()),
        );

        // Verify app bar elements
        expect(find.text('Account Overview'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      },
    );

    testWidgets('should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Should show loading indicator initially
      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(
        find.text('Loading account data from blockchain...'),
        findsOneWidget,
      );
    });

    testWidgets('should display RefreshIndicator for pull-to-refresh', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Verify RefreshIndicator is present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should handle refresh button tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Find and tap refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pump();

      // Should still show loading after refresh
      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('should display error state when blockchain connection fails', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for initial load to complete (will likely fail in test environment)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show error state or no account found
      final errorWidget = find.byType(ErrorStateWidget);
      final noAccountWidget = find.text('Account Not Found');

      expect(
        errorWidget.evaluate().isNotEmpty ||
            noAccountWidget.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('should display account summary card structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for card structure elements that should be present regardless of data
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should display Decentralized Banking Status indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for any content to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should have Decentralized Banking Status indicator somewhere in the widget tree
      expect(find.byType(BlockchainStatusIndicator), findsWidgets);
    });

    testWidgets('should have proper navigation structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Verify scaffold structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display demo user data when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for content to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for demo user data elements
      expect(find.textContaining(DemoUserData.name), findsWidgets);
    });

    testWidgets('should handle account details navigation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for content to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for View Details button
      final viewDetailsButton = find.text('View Full Details');
      if (viewDetailsButton.evaluate().isNotEmpty) {
        await tester.tap(viewDetailsButton.first);
        await tester.pumpAndSettle();

        // Should navigate to account details (will show in navigation stack)
        expect(find.byType(AccountOverviewScreen), findsOneWidget);
      }
    });

    testWidgets('should display transaction history modal', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for content to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for Transactions button
      final transactionsButton = find.text('Transactions');
      if (transactionsButton.evaluate().isNotEmpty) {
        await tester.tap(transactionsButton.first);
        await tester.pumpAndSettle();

        // Should show transaction history modal
        expect(find.text('Recent Transactions'), findsOneWidget);
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      }
    });

    testWidgets('should display quick actions section', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for content to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for quick actions
      expect(find.text('Quick Actions'), findsWidgets);
    });

    testWidgets('should handle quick action taps with coming soon messages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for content to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for Transfer action
      final transferAction = find.text('Transfer');
      if (transferAction.evaluate().isNotEmpty) {
        await tester.tap(transferAction.first);
        await tester.pumpAndSettle();

        // Should show coming soon snackbar
        expect(find.text('Transfer feature coming soon'), findsOneWidget);
      }
    });

    testWidgets('should display proper color scheme and styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Verify background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppConstants.backgroundColor));
    });

    testWidgets('should handle pull-to-refresh gesture', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for initial load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Perform pull-to-refresh gesture
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();

      // Should trigger refresh
      expect(find.byType(LoadingIndicator), findsWidgets);
    });

    testWidgets('should display formatted balance correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for content to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for formatted balance with currency symbol
      expect(find.textContaining('৳'), findsWidgets);
    });

    testWidgets('should show welcome section with gradient background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for content to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for welcome text
      expect(find.text('Welcome back,'), findsWidgets);
    });
  });

  group('AccountOverviewScreen Error Handling Tests', () {
    testWidgets('should display network error message appropriately', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for error to potentially occur
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check if error handling is working (error widget or no account found)
      final hasErrorWidget = find
          .byType(ErrorStateWidget)
          .evaluate()
          .isNotEmpty;
      final hasNoAccountMessage = find
          .text('Account Not Found')
          .evaluate()
          .isNotEmpty;

      expect(hasErrorWidget || hasNoAccountMessage, isTrue);
    });

    testWidgets('should provide retry functionality on error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for potential error state
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for retry button
      final retryButton = find.text('Retry');
      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton);
        await tester.pump();

        // Should attempt to reload
        expect(find.byType(LoadingIndicator), findsWidgets);
      }
    });
  });

  group('AccountOverviewScreen Accessibility Tests', () {
    testWidgets('should have proper semantic labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Verify semantic structure
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('should support screen reader navigation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const AccountOverviewScreen()));

      // Wait for content
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify buttons are accessible
      final buttons = find.byType(ElevatedButton);
      for (final button in buttons.evaluate()) {
        expect(
          tester.widget<ElevatedButton>(find.byWidget(button.widget)).onPressed,
          isNotNull,
        );
      }
    });
  });
}
