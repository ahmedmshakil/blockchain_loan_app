import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_loan_app/widgets/widgets.dart';

void main() {
  group('Core UI Widgets Tests', () {
    testWidgets('BankingHeader displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BankingHeader(userName: 'Test User', onProfileTap: () {}),
          ),
        ),
      );

      expect(find.text('Midnight Bank Ltd'), findsOneWidget);
      expect(find.text('Welcome, Test User'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('NavigationTabs displays all tabs', (
      WidgetTester tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationTabs(
              selectedIndex: selectedIndex,
              onTabSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Loans'), findsOneWidget);
    });

    testWidgets('AccountCard displays account information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountCard(
              accountHolderName: 'John Doe',
              nid: '1234567890',
              profession: 'Engineer',
              accountBalance: '50000',
              isBlockchainVerified: true,
            ),
          ),
        ),
      );

      expect(find.text('Account Overview'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
      expect(find.text('Engineer'), findsOneWidget);
      expect(find.text('৳50000'), findsOneWidget);
    });

    testWidgets('LoanInfoCard displays loan information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoanInfoCard(
              maxLoanAmount: '100000',
              isBlockchainVerified: true,
            ),
          ),
        ),
      );

      expect(find.text('Loan Information'), findsOneWidget);
      expect(find.text('Apply For Loan'), findsOneWidget);
      expect(find.text('12.5%'), findsOneWidget);
      expect(find.text('Instant Approval'), findsOneWidget);
      expect(find.text('12 months'), findsOneWidget);
    });

    testWidgets('BlockchainStatusIndicator shows verified state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BlockchainStatusIndicator(isVerified: true)),
        ),
      );

      expect(find.text('Verified Data'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('LoadingIndicator displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LoadingIndicator(message: 'Loading...')),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('ErrorStateWidget displays error information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              title: 'Error Title',
              message: 'Error message',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Error message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
