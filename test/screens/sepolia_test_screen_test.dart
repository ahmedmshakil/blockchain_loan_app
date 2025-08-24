import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/screens/sepolia_test_screen.dart';

void main() {
  group('SepoliaTestScreen Tests', () {
    testWidgets('should display screen title and main sections', (WidgetTester tester) async {
      // Build the SepoliaTestScreen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: SepoliaTestScreen(),
        ),
      );

      // Wait for the widget to be built completely
      await tester.pumpAndSettle();

      // Verify the screen title is displayed
      expect(find.text('Sepolia Testnet Testing'), findsOneWidget);

      // Verify main sections are present
      expect(find.text('Blockchain Testing Suite'), findsOneWidget);
      expect(find.text('Network Connection'), findsOneWidget);
      expect(find.text('Wallet Balance'), findsOneWidget);
      expect(find.text('Smart Contract Testing'), findsOneWidget);
      expect(find.text('Transaction Testing'), findsOneWidget);
      expect(find.text('Configuration Details'), findsOneWidget);
    });

    testWidgets('should display test buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SepoliaTestScreen(),
        ),
      );

      // Wait for the widget to be built completely
      await tester.pumpAndSettle();

      // Verify test buttons are present (they may be in different states)
      expect(find.textContaining('Network Connection'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Balance'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Contract'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Transaction'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display configuration information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SepoliaTestScreen(),
        ),
      );

      // Wait for the widget to be built completely
      await tester.pumpAndSettle();

      // Verify configuration details are shown
      expect(find.text('Network Name:'), findsAtLeastNWidgets(1));
      expect(find.text('Chain ID:'), findsAtLeastNWidgets(1));
      expect(find.text('Default Gas Limit:'), findsAtLeastNWidgets(1));
    });

    testWidgets('should have refresh functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SepoliaTestScreen(),
        ),
      );

      // Wait for the widget to be built completely
      await tester.pumpAndSettle();

      // Verify refresh button is present in app bar
      expect(find.byIcon(Icons.refresh), findsWidgets);
    });

    testWidgets('should display status indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SepoliaTestScreen(),
        ),
      );

      // Wait for the widget to be built completely
      await tester.pumpAndSettle();

      // Verify status indicators are present
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Contract'), findsOneWidget);
    });
  });
}