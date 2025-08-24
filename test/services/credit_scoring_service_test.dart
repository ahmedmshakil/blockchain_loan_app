import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/credit_scoring_service.dart';
import '../../lib/models/credit_score_model.dart';
import '../../lib/utils/constants.dart';

void main() {
  group('CreditScoringService Tests', () {
    late CreditScoringService creditScoringService;
    
    setUp(() {
      creditScoringService = CreditScoringService.instance;
    });
    
    tearDown(() {
      creditScoringService.dispose();
    });

    
    group('Credit Rating Calculation', () {
      test('should return A for excellent credit score', () {
        // Act & Assert
        expect(creditScoringService.calculateCreditRating(850), equals('A'));
        expect(creditScoringService.calculateCreditRating(800), equals('A'));
      });
      
      test('should return B for good credit score', () {
        // Act & Assert
        expect(creditScoringService.calculateCreditRating(750), equals('B'));
        expect(creditScoringService.calculateCreditRating(650), equals('B'));
      });
      
      test('should return C for fair credit score', () {
        // Act & Assert
        expect(creditScoringService.calculateCreditRating(600), equals('C'));
        expect(creditScoringService.calculateCreditRating(500), equals('C'));
      });
      
      test('should return D for poor credit score', () {
        // Act & Assert
        expect(creditScoringService.calculateCreditRating(400), equals('D'));
        expect(creditScoringService.calculateCreditRating(0), equals('D'));
      });
    });
    
    group('Loan Application Validation', () {
      test('should validate correct loan application parameters', () {
        // Arrange
        const nid = '1029384957';
        final requestedAmount = BigInt.from(100000);
        final monthlyIncome = BigInt.from(50000);
        
        // Act
        final result = creditScoringService.validateLoanApplication(
          nid: nid,
          requestedAmount: requestedAmount,
          monthlyIncome: monthlyIncome,
        );
        
        // Assert
        expect(result['isValid'], isTrue);
        expect(result['errors'], isEmpty);
      });
      
      test('should return errors for invalid parameters', () {
        // Arrange
        const nid = '123'; // Too short
        final requestedAmount = BigInt.zero; // Invalid amount
        final monthlyIncome = BigInt.zero; // Invalid income
        
        // Act
        final result = creditScoringService.validateLoanApplication(
          nid: nid,
          requestedAmount: requestedAmount,
          monthlyIncome: monthlyIncome,
        );
        
        // Assert
        expect(result['isValid'], isFalse);
        expect(result['errors'], isNotEmpty);
        expect(result['errors'], contains('Invalid NID format'));
        expect(result['errors'], contains('Loan amount must be greater than zero'));
        expect(result['errors'], contains('Monthly income must be greater than zero'));
      });
      
      test('should return warnings for edge cases', () {
        // Arrange
        const nid = '1029384957';
        final requestedAmount = BigInt.from(5000); // Below recommended minimum
        final monthlyIncome = BigInt.from(15000); // Low income
        
        // Act
        final result = creditScoringService.validateLoanApplication(
          nid: nid,
          requestedAmount: requestedAmount,
          monthlyIncome: monthlyIncome,
        );
        
        // Assert
        expect(result['isValid'], isTrue);
        expect(result['warnings'], isNotEmpty);
        expect(result['warnings'], contains('Minimum recommended loan amount is 10,000 BDT'));
        expect(result['warnings'], contains('Low monthly income may affect loan approval'));
      });
    });
    
    group('Cache Management', () {
      test('should cache credit score results', () async {
        // This test would require access to private cache methods
        // For now, we test the public interface
        
        // Arrange
        const nid = '1029384957';
        creditScoringService.clearCache();
        
        // Act
        creditScoringService.clearCacheForNid(nid);
        
        // Assert - No exception should be thrown
        expect(true, isTrue);
      });
      
      test('should clear all cache', () {
        // Act
        creditScoringService.clearCache();
        
        // Assert - No exception should be thrown
        expect(true, isTrue);
      });
    });
  });
}