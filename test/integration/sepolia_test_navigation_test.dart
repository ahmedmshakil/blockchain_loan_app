import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/screens/home_screen.dart';
import '../../lib/screens/sepolia_test_screen.dart';

void main() {
  group('Sepolia Test Navigation Integration Tests', () {
    testWidgets('should navigate to SepoliaTestScreen from HomeScreen', (WidgetTester tester) async {
      // Build the HomeScreen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Wait for the widget to be built completely
      await tester.pumpAndSettle();

      // Find and tap the blockchain testing button (science icon)
      final testingButton = find.byIcon(Icons.science);
      expect(testingButton, findsOneWidget);

      await tester.tap(testingButton);
      await tester.pumpAndSettle();

      // Verify that we navigated to the SepoliaTestScreen
      expect(find.text('Sepolia Testnet Testing'), findsOneWidget);
      expect(find.text('Blockchain Testing Suite'), findsOneWidget);
    });

    testWidgets('should be able to go back from SepoliaTestScreen', (WidgetTester tester) async {
      // Build the HomeScreen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Wait for the widget to be built completely
      await tester.pumpAndSettle();

      // Navigate to SepoliaTestScreen
      final testingButton = find.byIcon(Icons.science);
      await tester.tap(testingButton);
      await tester.pumpAndSettle();

      // Verify we're on the SepoliaTestScreen
      expect(find.text('Sepolia Testnet Testing'), findsOneWidget);

      // Find and tap the back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we're back on the HomeScreen by checking for unique home screen content
      expect(find.text('Account Overview'), findsOneWidget);
    });
  });
}