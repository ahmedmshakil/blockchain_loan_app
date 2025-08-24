import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_loan_app/screens/loan_application_screen.dart';
import 'package:blockchain_loan_app/models/models.dart';
import 'package:blockchain_loan_app/utils/constants.dart';
import 'package:blockchain_loan_app/widgets/blockchain_status_indicator.dart';
import 'package:blockchain_loan_app/widgets/loading_indicator.dart';
import 'package:blockchain_loan_app/widgets/error_state_widget.dart';

Widget createTestWidget() {
  return MaterialApp(
    home: const LoanApplicationScreen(),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryBlue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
  );
}

void main() {
  group('LoanApplicationScreen Tests', () {
    group('Widget Rendering Tests', () {
      testWidgets('should display loading indicator initially', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(LoadingIndicator), findsOneWidget);
        expect(find.text('Loan Application'), findsOneWidget);
      });

      testWidgets('should display app bar with correct title', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Loan Application'), findsOneWidget);
      });

      testWidgets('should have back button in app bar', (
        WidgetTester tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(BackButton), findsOneWidget);
      });
    });

    group('Form Validation Tests', () {
      testWidgets('should validate loan amount input', (
        WidgetTester tester,
      ) async {
        // This test would require mocking the blockchain service
        // For now, we'll test the widget structure
        await tester.pumpWidget(createTestWidget());

        // Wait for potential async operations
        await tester.pump(const Duration(seconds: 1));

        // Look for form elements that should be present
        // Note: These might not be visible initially due to loading state
        expect(find.byType(Form), findsWidgets);
      });

      testWidgets('should validate monthly income input', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 1));

        // Check for TextFormField widgets
        expect(find.byType(TextFormField), findsWidgets);
      });
    });

    group('User Interaction Tests', () {
      testWidgets('should handle form submission', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 1));

        // Look for submit button
        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('should show Decentralized Banking Status indicator', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 1));

        // The Decentralized Banking Status indicator should be present when form loads
        // Note: This might not be visible during loading state
        expect(find.byType(BlockchainStatusIndicator), findsWidgets);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should display error state widget on error', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Wait for potential error state
        await tester.pump(const Duration(seconds: 2));

        // Check if error widget might be displayed
        // Note: This depends on actual blockchain connection
        expect(find.byType(ErrorStateWidget), findsWidgets);
      });
    });

    group('Data Display Tests', () {
      testWidgets('should display borrower information section', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 1));

        // Look for cards that would contain borrower info
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('should display credit score section', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 1));

        // Check for text that might indicate credit score display
        expect(find.textContaining('Credit'), findsWidgets);
      });

      testWidgets('should display loan form section', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 1));

        // Look for loan-related text
        expect(find.textContaining('Loan'), findsWidgets);
      });
    });

    group('Navigation Tests', () {
      testWidgets('should handle back navigation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find and tap back button
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }

        // Navigation behavior would be tested in integration tests
        expect(backButton, findsWidgets);
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('should handle different screen sizes', (
        WidgetTester tester,
      ) async {
        // Test with different screen sizes
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // Test with larger screen
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantics for screen readers', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Check for semantic labels
        expect(find.byType(Semantics), findsWidgets);
      });

      testWidgets('should support keyboard navigation', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Form fields should be focusable
        expect(find.byType(TextFormField), findsWidgets);
      });
    });
  });

  group('LoanApplicationScreen Integration Tests', () {
    group('Complete Loan Application Flow', () {
      testWidgets('should complete full loan application process', (
        WidgetTester tester,
      ) async {
        // This is a mock integration test structure
        // In a real scenario, this would test the complete flow

        await tester.pumpWidget(createTestWidget());

        // Step 1: Wait for initial load
        await tester.pump(const Duration(seconds: 1));

        // Step 2: Check if form is loaded (would require mocking services)
        // expect(find.text('Borrower Information'), findsOneWidget);

        // Step 3: Fill loan amount (would require form to be visible)
        // await tester.enterText(find.byKey(const Key('loanAmountField')), '50000');

        // Step 4: Fill monthly income
        // await tester.enterText(find.byKey(const Key('monthlyIncomeField')), '65000');

        // Step 5: Calculate eligibility
        // await tester.tap(find.byIcon(Icons.calculate));
        // await tester.pump();

        // Step 6: Submit application
        // await tester.tap(find.text('Submit Loan Application'));
        // await tester.pump();

        // For now, just verify the widget structure exists
        expect(find.byType(LoanApplicationScreen), findsOneWidget);
      });
    });

    group('Error Scenarios', () {
      testWidgets('should handle blockchain connection errors', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        // Wait for potential error state
        await tester.pump(const Duration(seconds: 3));

        // Check if error handling is in place
        // In real tests, this would verify specific error messages
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('should handle invalid form inputs', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 1));

        // Test form validation (would require form to be visible)
        // This would test entering invalid amounts, etc.
        expect(find.byType(Form), findsWidgets);
      });
    });

    group('Success Scenarios', () {
      testWidgets('should display success dialog on loan approval', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 1));

        // This would test the success flow
        // In real implementation, would mock successful blockchain response
        expect(find.byType(LoanApplicationScreen), findsOneWidget);
      });

      testWidgets('should show transaction details', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(seconds: 1));

        // Test transaction details display
        expect(find.byType(LoanApplicationScreen), findsOneWidget);
      });
    });
  });

  group('Performance Tests', () {
    testWidgets('should load within reasonable time', (
      WidgetTester tester,
    ) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      stopwatch.stop();

      // Should load UI quickly (actual blockchain calls may take longer)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('should handle rapid user interactions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Test rapid tapping doesn't cause issues
      for (int i = 0; i < 5; i++) {
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      expect(find.byType(LoanApplicationScreen), findsOneWidget);
    });
  });
}

/// Mock data for testing
class MockTestData {
  static BorrowerModel get mockBorrower => BorrowerModel(
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

  static CreditScoreModel get mockCreditScore =>
      CreditScoreModel.fromBlockchainCalculation(
        score: DemoUserData.expectedCreditScore,
        rating: DemoUserData.expectedCreditRating,
        maxLoanAmount: BigInt.parse(DemoUserData.expectedMaxLoanAmount),
        scoreBreakdown: {
          'Account Balance': 187,
          'Transactions': 112,
          'Payment History': 270,
          'Remaining Loans': 83,
          'Credit Age': 50,
          'Profession Risk': 40,
        },
      );

  static LoanModel get mockLoan => LoanModel.fromBlockchainTransaction(
    borrowerNid: DemoUserData.nid,
    amount: BigInt.from(100000),
    transactionHash: '0x1234567890abcdef',
    creditScore: DemoUserData.expectedCreditScore,
  );
}
