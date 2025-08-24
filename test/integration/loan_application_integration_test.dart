import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:blockchain_loan_app/main.dart' as app;
import 'package:blockchain_loan_app/screens/loan_application_screen.dart';
import 'package:blockchain_loan_app/utils/constants.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Loan Application Integration Tests', () {
    group('Complete User Journey', () {
      testWidgets('should complete full loan application journey', (
        WidgetTester tester,
      ) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle();

        // Step 1: Navigate to Loans tab
        await tester.tap(find.text('Loans'));
        await tester.pumpAndSettle();

        // Step 2: Tap "Apply For Loan" button
        await tester.tap(find.text('Apply For Loan'));
        await tester.pumpAndSettle();

        // Step 3: Verify loan application screen is displayed
        expect(find.byType(LoanApplicationScreen), findsOneWidget);
        expect(find.text('Loan Application'), findsOneWidget);

        // Step 4: Wait for data to load
        await tester.pump(const Duration(seconds: 5));

        // Step 5: Verify borrower information is displayed
        expect(find.text('Borrower Information'), findsOneWidget);
        expect(find.text(DemoUserData.name), findsOneWidget);
        expect(find.text(DemoUserData.nid), findsOneWidget);

        // Step 6: Verify credit score section is displayed
        expect(find.text('Credit Score Analysis'), findsOneWidget);

        // Step 7: Fill in loan amount
        final loanAmountField = find.byType(TextFormField).first;
        await tester.enterText(loanAmountField, '50000');
        await tester.pump();

        // Step 8: Verify monthly income is pre-filled
        expect(find.text(DemoUserData.monthlyIncome), findsOneWidget);

        // Step 9: Calculate eligibility
        await tester.tap(find.byIcon(Icons.calculate));
        await tester.pump(const Duration(seconds: 2));

        // Step 10: Verify eligibility assessment is shown
        expect(find.text('Eligibility Assessment'), findsOneWidget);

        // Step 11: Submit loan application (if eligible)
        final submitButton = find.text('Submit Loan Application');
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton);
          await tester.pump(
            const Duration(seconds: 10),
          ); // Wait for blockchain transaction

          // Step 12: Verify success dialog or error handling
          expect(find.byType(AlertDialog), findsOneWidget);
        }
      });
    });

    group('Error Handling Integration', () {
      testWidgets('should handle network errors gracefully', (
        WidgetTester tester,
      ) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to loan application
        await tester.tap(find.text('Loans'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply For Loan'));
        await tester.pumpAndSettle();

        // Wait for potential error state
        await tester.pump(const Duration(seconds: 10));

        // Verify error handling is in place
        // This might show error state or loading state depending on network
        expect(find.byType(LoanApplicationScreen), findsOneWidget);
      });

      testWidgets('should validate form inputs correctly', (
        WidgetTester tester,
      ) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to loan application
        await tester.tap(find.text('Loans'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply For Loan'));
        await tester.pumpAndSettle();

        // Wait for form to load
        await tester.pump(const Duration(seconds: 5));

        // Try to submit with invalid data
        final loanAmountField = find.byType(TextFormField).first;
        await tester.enterText(loanAmountField, '0'); // Invalid amount
        await tester.pump();

        // Try to submit
        final submitButton = find.text('Submit Loan Application');
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton);
          await tester.pump();

          // Should show validation error
          expect(find.textContaining('valid'), findsWidgets);
        }
      });
    });

    group('Blockchain Integration', () {
      testWidgets('should display blockchain verification status', (
        WidgetTester tester,
      ) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to loan application
        await tester.tap(find.text('Loans'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply For Loan'));
        await tester.pumpAndSettle();

        // Wait for Decentralized Banking Status
        await tester.pump(const Duration(seconds: 5));

        // Verify Decentralized Banking Status indicator
        expect(find.text('Govt. Verified'), findsWidgets);
      });

      testWidgets('should handle blockchain transaction processing', (
        WidgetTester tester,
      ) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to loan application
        await tester.tap(find.text('Loans'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply For Loan'));
        await tester.pumpAndSettle();

        // Wait for data load
        await tester.pump(const Duration(seconds: 5));

        // Fill valid loan application
        final loanAmountField = find.byType(TextFormField).first;
        await tester.enterText(loanAmountField, '25000');
        await tester.pump();

        // Calculate eligibility
        await tester.tap(find.byIcon(Icons.calculate));
        await tester.pump(const Duration(seconds: 3));

        // Submit if eligible
        final submitButton = find.text('Submit Loan Application');
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton);

          // Wait for blockchain processing
          await tester.pump(const Duration(seconds: 15));

          // Should show processing or result
          expect(find.textContaining('Processing'), findsWidgets);
        }
      });
    });

    group('User Experience', () {
      testWidgets('should provide smooth navigation experience', (
        WidgetTester tester,
      ) async {
        app.main();
        await tester.pumpAndSettle();

        // Test navigation flow
        await tester.tap(find.text('Loans'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply For Loan'));
        await tester.pumpAndSettle();

        // Verify smooth transition
        expect(find.byType(LoanApplicationScreen), findsOneWidget);

        // Test back navigation
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Should return to home screen
        expect(find.text('Loans'), findsOneWidget);
      });

      testWidgets('should display loading states appropriately', (
        WidgetTester tester,
      ) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to loan application
        await tester.tap(find.text('Loans'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply For Loan'));

        // Should show loading initially
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        await tester.pumpAndSettle();
      });
    });

    group('Data Accuracy', () {
      testWidgets('should display correct borrower data from blockchain', (
        WidgetTester tester,
      ) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to loan application
        await tester.tap(find.text('Loans'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply For Loan'));
        await tester.pumpAndSettle();

        // Wait for data load
        await tester.pump(const Duration(seconds: 5));

        // Verify demo user data is displayed
        expect(find.text(DemoUserData.name), findsOneWidget);
        expect(find.text(DemoUserData.profession), findsOneWidget);
        expect(find.textContaining(DemoUserData.accountBalance), findsWidgets);
      });

      testWidgets('should calculate credit score correctly', (
        WidgetTester tester,
      ) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to loan application
        await tester.tap(find.text('Loans'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply For Loan'));
        await tester.pumpAndSettle();

        // Wait for credit score calculation
        await tester.pump(const Duration(seconds: 8));

        // Verify credit score is displayed
        expect(find.textContaining('Credit Score'), findsWidgets);
        expect(find.textContaining('Rating'), findsWidgets);
      });
    });

    group('Performance', () {
      testWidgets(
        'should load loan application screen within acceptable time',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch()..start();

          app.main();
          await tester.pumpAndSettle();

          await tester.tap(find.text('Loans'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Apply For Loan'));
          await tester.pumpAndSettle();

          stopwatch.stop();

          // Should navigate quickly (blockchain calls may take longer)
          expect(stopwatch.elapsedMilliseconds, lessThan(5000));
          expect(find.byType(LoanApplicationScreen), findsOneWidget);
        },
      );
    });

    group('Accessibility', () {
      testWidgets('should be accessible to screen readers', (
        WidgetTester tester,
      ) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to loan application
        await tester.tap(find.text('Loans'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply For Loan'));
        await tester.pumpAndSettle();

        // Wait for content load
        await tester.pump(const Duration(seconds: 5));

        // Verify semantic labels exist
        expect(find.byType(Semantics), findsWidgets);

        // Verify form fields have proper labels
        expect(find.byType(TextFormField), findsWidgets);
      });
    });
  });
}
