import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_loan_app/screens/home_screen.dart';
import 'package:blockchain_loan_app/utils/constants.dart';

void main() {
  group('HomeScreen Navigation Tests', () {
    testWidgets('should display home screen with navigation tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const HomeScreen()));

      // Verify app bar is displayed with correct title (appears twice - in app bar and header)
      expect(find.text(AppConstants.bankName), findsAtLeastNWidgets(1));

      // Verify navigation tabs are displayed
      expect(find.text('Accounts'), findsWidgets);
      expect(find.text('Loans'), findsWidgets);

      // Verify banking header is displayed
      expect(find.text('Welcome, ${DemoUserData.name}'), findsOneWidget);
    });

    testWidgets('should switch between tabs when tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const HomeScreen()));

      // Initially should show Accounts tab content
      expect(find.text('Account Overview'), findsOneWidget);

      // Tap on Loans tab in bottom navigation
      await tester.tap(find.byIcon(Icons.monetization_on).last);
      await tester.pumpAndSettle();

      // Should now show Loans tab content
      expect(find.text('Loan Services'), findsOneWidget);
      expect(find.text('Apply For Loan'), findsOneWidget);
    });

    testWidgets('should show profile dialog when profile icon is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: const HomeScreen()));

      // Tap on profile icon in app bar
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Should show profile dialog
      expect(find.text('User Profile'), findsOneWidget);
      expect(find.text('Name:'), findsOneWidget);
      expect(find.text(DemoUserData.name), findsWidgets);
    });

    testWidgets('should show navigation feedback for future screens', (
      WidgetTester tester,
    ) async {
      // Set a larger test size to accommodate the UI
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(MaterialApp(home: const HomeScreen()));

      // Scroll to make buttons visible
      await tester.scrollUntilVisible(find.text('View Details'), 500.0);

      // Tap on View Details button
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      // Should navigate to Account Details screen
      expect(find.text('Account Details'), findsOneWidget);

      // Navigate back to home for loan test
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Switch to loans tab and test loan application navigation
      await tester.tap(find.byIcon(Icons.monetization_on).last);
      await tester.pumpAndSettle();

      // Scroll to make the loan button visible
      await tester.scrollUntilVisible(find.text('Apply For Loan'), 500.0);

      // Tap on Apply For Loan button
      await tester.tap(find.text('Apply For Loan'));
      await tester.pumpAndSettle();

      // Should show snackbar with navigation message
      expect(find.textContaining('Loan application screen'), findsOneWidget);
    });
  });
}
