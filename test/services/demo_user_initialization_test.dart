import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_loan_app/services/demo_user_initialization_service.dart';
import 'package:blockchain_loan_app/utils/constants.dart';

void main() {
  group('DemoUserInitializationService', () {
    late DemoUserInitializationService service;
    
    setUp(() {
      service = DemoUserInitializationService.instance;
      service.resetInitializationState();
    });
    
    test('should create demo borrower model with correct data', () {
      // Act
      final borrower = service.createDemoBorrowerModel();
      
      // Assert
      expect(borrower.name, equals(DemoUserData.name));
      expect(borrower.nid, equals(DemoUserData.nid));
      expect(borrower.profession, equals(DemoUserData.profession));
      expect(borrower.accountBalance, equals(BigInt.parse(DemoUserData.accountBalance)));
      expect(borrower.totalTransactions, equals(BigInt.parse(DemoUserData.totalTransactions)));
      expect(borrower.onTimePayments, equals(BigInt.from(DemoUserData.onTimePayments)));
      expect(borrower.missedPayments, equals(BigInt.from(DemoUserData.missedPayments)));
      expect(borrower.totalRemainingLoan, equals(BigInt.parse(DemoUserData.totalRemainingLoan)));
      expect(borrower.creditAgeMonths, equals(BigInt.from(DemoUserData.creditAgeMonths)));
      expect(borrower.professionRiskScore, equals(BigInt.from(DemoUserData.professionRiskScore)));
      expect(borrower.exists, isFalse);
    });
    
    test('should create demo borrower model with custom NID', () {
      // Arrange
      const customNid = '9876543210';
      
      // Act
      final borrower = service.createDemoBorrowerModel(customNid: customNid);
      
      // Assert
      expect(borrower.nid, equals(customNid));
      expect(borrower.name, equals(DemoUserData.name));
    });
    
    test('should return correct initialization status', () {
      // Act
      final status = service.getInitializationStatus();
      
      // Assert
      expect(status['isInitialized'], isFalse);
      expect(status['isInitializing'], isFalse);
      expect(status['demoUserNid'], equals(DemoUserData.nid));
      expect(status['demoUserName'], equals(DemoUserData.name));
      expect(status['guidance'], isA<List<String>>());
      expect(status['guidance'], isNotEmpty);
    });
    
    test('should reset initialization state correctly', () {
      // Act
      service.resetInitializationState();
      
      // Assert
      expect(service.isInitialized, isFalse);
      expect(service.isInitializing, isFalse);
      expect(service.initializationError, isNull);
      expect(service.lastInitializationAttempt, isNull);
    });
  });
}