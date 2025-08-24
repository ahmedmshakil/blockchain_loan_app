import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_loan_app/models/models.dart';

void main() {
  group('Data Models Tests', () {
    test('BorrowerModel should create and serialize correctly', () {
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
        professionRiskScore: BigInt.from(5),
        exists: true,
      );

      expect(borrower.name, 'Test User');
      expect(borrower.nid, '1234567890');
      expect(borrower.exists, true);

      // Test JSON serialization
      final json = borrower.toJson();
      final fromJson = BorrowerModel.fromJson(json);
      expect(fromJson.name, borrower.name);
      expect(fromJson.nid, borrower.nid);
      expect(fromJson.accountBalance, borrower.accountBalance);
    });

    test('CreditScoreModel should create and serialize correctly', () {
      final creditScore = CreditScoreModel(
        score: 750,
        rating: 'B',
        maxLoanAmount: BigInt.from(500000),
        scoreBreakdown: {
          'Account Balance': 187,
          'Transactions': 112,
          'Payment History': 225,
        },
        isBlockchainVerified: true,
        calculatedAt: DateTime.now(),
      );

      expect(creditScore.score, 750);
      expect(creditScore.rating, 'B');
      expect(creditScore.isEligibleForLoan, true);
      expect(creditScore.scorePercentage, 75.0);

      // Test JSON serialization
      final json = creditScore.toJson();
      final fromJson = CreditScoreModel.fromJson(json);
      expect(fromJson.score, creditScore.score);
      expect(fromJson.rating, creditScore.rating);
      expect(fromJson.isBlockchainVerified, creditScore.isBlockchainVerified);
    });

    test('LoanModel should create and serialize correctly', () {
      final loan = LoanModel.createApplication(
        borrowerNid: '1234567890',
        requestedAmount: BigInt.from(100000),
        creditScore: 750,
        type: LoanType.personal,
      );

      expect(loan.borrowerNid, '1234567890');
      expect(loan.requestedAmount, BigInt.from(100000));
      expect(loan.status, LoanStatus.pending);
      expect(loan.isPending, true);
      expect(loan.formattedStatus, 'Pending Approval');
      expect(loan.formattedType, 'Personal Loan');

      // Test JSON serialization
      final json = loan.toJson();
      final fromJson = LoanModel.fromJson(json);
      expect(fromJson.borrowerNid, loan.borrowerNid);
      expect(fromJson.requestedAmount, loan.requestedAmount);
      expect(fromJson.status, loan.status);
    });

    test('CreditScoreModel rating calculation should work correctly', () {
      expect(CreditScoreModel.getRatingFromScore(850), 'A');
      expect(CreditScoreModel.getRatingFromScore(700), 'B');
      expect(CreditScoreModel.getRatingFromScore(550), 'C');
      expect(CreditScoreModel.getRatingFromScore(400), 'D');
    });

    test('LoanModel blockchain transaction factory should work', () {
      final loan = LoanModel.fromBlockchainTransaction(
        borrowerNid: '1234567890',
        amount: BigInt.from(50000),
        transactionHash: '0x123abc',
        creditScore: 680,
      );

      expect(loan.status, LoanStatus.approved);
      expect(loan.transactionHash, '0x123abc');
      expect(loan.approvedAmount, BigInt.from(50000));
      expect(loan.isActive, true);
    });
  });
}