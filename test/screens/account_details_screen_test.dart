import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_loan_app/screens/account_details_screen.dart';
import 'package:blockchain_loan_app/models/borrower_model.dart';
import 'package:blockchain_loan_app/utils/constants.dart';
import 'package:blockchain_loan_app/widgets/loading_indicator.dart';
import 'package:blockchain_loan_app/widgets/error_state_widget.dart';
import 'package:blockchain_loan_app/widgets/blockchain_status_indicator.dart';

/// Widget tests for AccountDetailsScreen
/// Requirements: 1.2, 1.3, 5.2, 5.3
void main() {
  // Create test borrower data
  final testBorrowerData = BorrowerModel(
    name: DemoUserData.name,
    nid: DemoUserData.nid,
    profession: DemoUserData.profession,
    accountBalance: BigInt.parse(DemoUserData.accountBalance),
    totalTransactions: BigInt.parse(DemoUserData.totalTransactions),
    onTimePayments: BigInt.from(DemoUserData.onTimePayments),
    missedPayments: BigInt.from(DemoUserData.missedPayments),
    totalRemainingLoan: BigInt.parse(DemoUserData.totalRemainingLoan),
    creditAgeMonths: BigInt.from(DemoUserData.creditAgeMonths),
    professionRiskScore: BigInt.from(DemoUserData.professionRiskScore),
    exists: true,
  );

  group('AccountDetailsScreen Widget Tests', () {
    testWidgets('should display app bar with correct title and tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      // Verify app bar elements
      expect(find.text('Account Details'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Verify tab bar
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Credit Score'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
    });

    testWidgets('should display tab icons correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      // Verify tab icons
      expect(find.byIcon(Icons.account_circle), findsOneWidget);
      expect(find.byIcon(Icons.assessment), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('should display borrower data in overview tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      // Wait for initial render
      await tester.pumpAndSettle();

      // Verify borrower data is displayed
      expect(find.text(testBorrowerData.name), findsWidgets);
      expect(find.text(testBorrowerData.nid), findsWidgets);
      expect(find.text(testBorrowerData.profession), findsWidgets);
    });

    testWidgets('should display account header card with gradient background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify account header elements
      expect(find.text(testBorrowerData.name), findsWidgets);
      expect(
        find.text('Account: ${DemoUserData.accountNumber}'),
        findsOneWidget,
      );
      expect(find.text('Available Balance'), findsOneWidget);
    });

    testWidgets('should display personal information card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify personal information section
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('National ID'), findsOneWidget);
      expect(find.text('Profession'), findsOneWidget);
    });

    testWidgets('should display financial summary card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify financial summary section
      expect(find.text('Financial Summary'), findsOneWidget);
      expect(find.text('Account Balance'), findsOneWidget);
      expect(find.text('Total Transactions'), findsOneWidget);
      expect(find.text('Monthly Income'), findsOneWidget);
    });

    testWidgets('should display account status card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify account status section
      expect(find.text('Account Status'), findsOneWidget);
      expect(find.text('Account Status'), findsOneWidget);
      expect(find.text('KYC Status'), findsOneWidget);
      expect(find.text('Decentralized Banking Status'), findsOneWidget);
    });

    testWidgets('should switch to credit score tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Tap on credit score tab
      await tester.tap(find.text('Credit Score'));
      await tester.pumpAndSettle();

      // Should show loading indicator for credit score
      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(
        find.text('Loading credit score from blockchain...'),
        findsOneWidget,
      );
    });

    testWidgets('should switch to activity tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Tap on activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // Verify activity tab content
      expect(find.text('Payment History'), findsOneWidget);
      expect(find.text('Transaction Summary'), findsOneWidget);
      expect(find.text('Loan History'), findsOneWidget);
    });

    testWidgets('should display Decentralized Banking Status indicators', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify Decentralized Banking Status indicators are present
      expect(find.byType(BlockchainStatusIndicator), findsWidgets);
    });

    testWidgets('should display formatted currency values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify currency formatting
      expect(find.textContaining('৳'), findsWidgets);
    });

    testWidgets('should handle refresh button tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Should trigger refresh (may show loading)
      expect(find.byType(AccountDetailsScreen), findsOneWidget);
    });

    testWidgets('should display user avatar with initials', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify avatar is displayed
      expect(find.byType(CircleAvatar), findsWidgets);
    });
  });

  group('AccountDetailsScreen Credit Score Tab Tests', () {
    testWidgets('should show loading state initially in credit score tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      // Switch to credit score tab
      await tester.tap(find.text('Credit Score'));
      await tester.pumpAndSettle();

      // Should show loading
      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('should handle credit score loading error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      // Switch to credit score tab
      await tester.tap(find.text('Credit Score'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show error state or continue loading
      final hasError = find.byType(ErrorStateWidget).evaluate().isNotEmpty;
      final hasLoading = find.byType(LoadingIndicator).evaluate().isNotEmpty;

      expect(hasError || hasLoading, isTrue);
    });
  });

  group('AccountDetailsScreen Activity Tab Tests', () {
    testWidgets('should display payment history information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      // Switch to activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // Verify payment history content
      expect(find.text('Payment History'), findsOneWidget);
      expect(find.text('On-time Payments'), findsOneWidget);
      expect(find.text('Missed Payments'), findsOneWidget);
      expect(find.text('Payment Success Rate'), findsOneWidget);
    });

    testWidgets('should display transaction summary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      // Switch to activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // Verify transaction summary content
      expect(find.text('Transaction Summary'), findsOneWidget);
      expect(find.text('Total Transaction Volume'), findsOneWidget);
    });

    testWidgets('should display loan history', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      // Switch to activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // Verify loan history content
      expect(find.text('Loan History'), findsOneWidget);
      expect(find.text('Active Loans'), findsOneWidget);
      expect(find.text('Total Remaining Amount'), findsOneWidget);
    });

    testWidgets('should calculate and display payment success rate', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      // Switch to activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // Should display calculated success rate
      expect(find.textContaining('%'), findsWidgets);
    });
  });

  group('AccountDetailsScreen Navigation Tests', () {
    testWidgets('should maintain tab state when switching', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Switch between tabs
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();

      // Should return to overview content
      expect(find.text('Personal Information'), findsOneWidget);
    });

    testWidgets('should handle back navigation properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify back button exists
      expect(find.byType(BackButton), findsOneWidget);
    });
  });

  group('AccountDetailsScreen Data Display Tests', () {
    testWidgets('should format large numbers with commas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Look for formatted numbers (should contain commas for large amounts)
      final formattedNumbers = find.textContaining(',');
      expect(formattedNumbers.evaluate().isNotEmpty, isTrue);
    });

    testWidgets('should display proper status indicators', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Look for status indicators
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Verified'), findsWidgets);
    });

    testWidgets('should show contact information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify contact information is displayed
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
    });
  });

  group('AccountDetailsScreen Error Handling Tests', () {
    testWidgets('should handle invalid borrower data gracefully', (
      WidgetTester tester,
    ) async {
      final invalidBorrower = BorrowerModel(
        name: '',
        nid: '',
        profession: '',
        accountBalance: BigInt.zero,
        totalTransactions: BigInt.zero,
        onTimePayments: BigInt.zero,
        missedPayments: BigInt.zero,
        totalRemainingLoan: BigInt.zero,
        creditAgeMonths: BigInt.zero,
        professionRiskScore: BigInt.zero,
        exists: false,
      );

      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: invalidBorrower)),
      );

      await tester.pumpAndSettle();

      // Should handle empty data gracefully
      expect(find.byType(AccountDetailsScreen), findsOneWidget);
    });
  });

  group('AccountDetailsScreen Accessibility Tests', () {
    testWidgets('should have proper semantic structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify semantic structure
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('should support tab navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AccountDetailsScreen(borrowerData: testBorrowerData)),
      );

      await tester.pumpAndSettle();

      // Verify tab controller is accessible
      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });
  });
}
