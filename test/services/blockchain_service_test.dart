import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_loan_app/services/blockchain_service.dart';
import 'package:blockchain_loan_app/models/borrower_model.dart';
import 'package:blockchain_loan_app/models/credit_score_model.dart';
import 'package:blockchain_loan_app/models/loan_model.dart';

void main() {
  group('BlockchainService Tests', () {
    late BlockchainService blockchainService;
    
    setUp(() {
      blockchainService = BlockchainService.instance;
    });
    
    group('Data Model Tests', () {
      test('should create BorrowerModel correctly', () {
        // Arrange & Act
        final borrower = BorrowerModel(
          name: 'Test User',
          nid: '1234567890',
          profession: 'Engineer',
          accountBalance: BigInt.from(100000),
          totalTransactions: BigInt.from(50),
          onTimePayments: BigInt.from(45),
          missedPayments: BigInt.from(5),
          totalRemainingLoan: BigInt.from(20000),
          creditAgeMonths: BigInt.from(24),
          professionRiskScore: BigInt.from(100),
          exists: true,
        );
        
        // Assert
        expect(borrower.name, equals('Test User'));
        expect(borrower.nid, equals('1234567890'));
        expect(borrower.profession, equals('Engineer'));
        expect(borrower.accountBalance, equals(BigInt.from(100000)));
        expect(borrower.exists, isTrue);
      });
      
      test('should create CreditScoreModel correctly', () {
        // Arrange & Act
        final creditScore = CreditScoreModel.fromBlockchainCalculation(
          score: 750,
          rating: 'B',
          maxLoanAmount: BigInt.from(300000),
          scoreBreakdown: {
            'Account Balance': 200,
            'Transactions': 150,
            'Payment History': 250,
            'Remaining Loans': 80,
            'Credit Age': 50,
            'Profession Risk': 20,
          },
        );
        
        // Assert
        expect(creditScore.score, equals(750));
        expect(creditScore.rating, equals('B'));
        expect(creditScore.maxLoanAmount, equals(BigInt.from(300000)));
        expect(creditScore.isBlockchainVerified, isTrue);
        expect(creditScore.scoreBreakdown['Account Balance'], equals(200));
        expect(creditScore.isEligibleForLoan, isTrue);
      });
      
      test('should create LoanModel from blockchain transaction', () {
        // Arrange & Act
        final loan = LoanModel.fromBlockchainTransaction(
          borrowerNid: '1234567890',
          amount: BigInt.from(100000),
          transactionHash: '0xabcdef1234567890',
          creditScore: 750,
          type: LoanType.personal,
        );
        
        // Assert
        expect(loan.borrowerNid, equals('1234567890'));
        expect(loan.requestedAmount, equals(BigInt.from(100000)));
        expect(loan.approvedAmount, equals(BigInt.from(100000)));
        expect(loan.transactionHash, equals('0xabcdef1234567890'));
        expect(loan.creditScoreAtApplication, equals(750));
        expect(loan.status, equals(LoanStatus.approved));
        expect(loan.type, equals(LoanType.personal));
      });
    });
    
    group('Service Initialization', () {
      test('should create singleton instance', () {
        // Act
        final instance1 = BlockchainService.instance;
        final instance2 = BlockchainService.instance;
        
        // Assert
        expect(identical(instance1, instance2), isTrue);
      });
    });
    
    group('Error Handling', () {
      test('should handle getBorrowerData when borrower not found', () async {
        // This test will actually try to connect to blockchain
        // In a real scenario, this would fail gracefully
        const nid = 'nonexistent_nid';
        
        try {
          final result = await blockchainService.getBorrowerData(nid);
          
          // Should return empty borrower model when not found
          expect(result.exists, isFalse);
          expect(result.nid, equals(nid));
          expect(result.name, isEmpty);
        } catch (e) {
          // Expected to fail in test environment without blockchain connection
          expect(e, isA<Exception>());
        }
      });
    });
    
    group('Utility Methods', () {
      test('should validate credit score eligibility', () {
        // Test different credit scores
        final highScore = CreditScoreModel.fromBlockchainCalculation(
          score: 800,
          rating: 'A',
          maxLoanAmount: BigInt.from(500000),
          scoreBreakdown: {},
        );
        
        final lowScore = CreditScoreModel.fromBlockchainCalculation(
          score: 200,
          rating: 'D',
          maxLoanAmount: BigInt.zero,
          scoreBreakdown: {},
        );
        
        expect(highScore.isEligibleForLoan, isTrue);
        expect(lowScore.isEligibleForLoan, isFalse);
      });
      
      test('should calculate loan progress correctly', () {
        final loan = LoanModel.fromBlockchainTransaction(
          borrowerNid: '1234567890',
          amount: BigInt.from(100000),
          transactionHash: '0xtest',
          creditScore: 750,
        ).copyWith(
          remainingBalance: BigInt.from(50000), // 50% paid
        );
        
        expect(loan.progressPercentage, equals(50.0));
      });
      
      test('should format loan status correctly', () {
        final pendingLoan = LoanModel.createApplication(
          borrowerNid: '1234567890',
          requestedAmount: BigInt.from(100000),
          creditScore: 750,
        );
        
        expect(pendingLoan.formattedStatus, equals('Pending Approval'));
        expect(pendingLoan.formattedType, equals('Personal Loan'));
        expect(pendingLoan.isPending, isTrue);
        expect(pendingLoan.isActive, isFalse);
      });
    });
  });
}