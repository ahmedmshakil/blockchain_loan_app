import 'dart:developer' as developer;
import 'blockchain_service.dart';
import '../models/borrower_model.dart';
import '../models/loan_model.dart';
import '../utils/constants.dart';

/// Example usage of BlockchainService for demonstration purposes
/// This shows how the service would be used in the actual application
class BlockchainServiceExample {
  final BlockchainService _blockchainService = BlockchainService.instance;
  
  /// Example: Complete loan application flow
  Future<void> demonstrateLoanApplicationFlow() async {
    try {
      developer.log('Starting loan application demonstration...', name: 'BlockchainServiceExample');
      
      // Step 1: Initialize the blockchain service
      await _blockchainService.initialize();
      developer.log('✓ Blockchain service initialized', name: 'BlockchainServiceExample');
      
      // Step 2: Create demo borrower data
      final demoBorrower = BorrowerModel(
        name: DemoUserData.name,
        nid: DemoUserData.nid,
        profession: DemoUserData.profession,
        accountBalance: BigInt.parse(DemoUserData.accountBalance),
        totalTransactions: BigInt.parse(DemoUserData.totalTransactions),
        onTimePayments: BigInt.from(DemoUserData.onTimePayments),
        missedPayments: BigInt.from(DemoUserData.missedPayments),
        totalRemainingLoan: BigInt.parse(DemoUserData.totalRemainingLoan),
        creditAgeMonths: BigInt.from(DemoUserData.creditAgeMonths),
        professionRiskScore: BigInt.from(85), // Low risk for tech profession
        exists: false,
      );
      
      // Step 3: Add borrower to blockchain (if not exists)
      try {
        final addBorrowerTx = await _blockchainService.addBorrowerToBlockchain(demoBorrower);
        developer.log('✓ Borrower added to blockchain: $addBorrowerTx', name: 'BlockchainServiceExample');
      } catch (e) {
        if (e.toString().contains('already exists')) {
          developer.log('✓ Borrower already exists on blockchain', name: 'BlockchainServiceExample');
        } else {
          rethrow;
        }
      }
      
      // Step 4: Get borrower data from blockchain
      final borrowerData = await _blockchainService.getBorrowerData(DemoUserData.nid);
      developer.log('✓ Borrower data retrieved: ${borrowerData.name}', name: 'BlockchainServiceExample');
      
      // Step 5: Calculate credit score
      final creditScore = await _blockchainService.calculateCreditScore(DemoUserData.nid);
      developer.log('✓ Credit score calculated: $creditScore', name: 'BlockchainServiceExample');
      
      // Step 6: Get credit rating
      final creditRating = await _blockchainService.getCreditRating(DemoUserData.nid);
      developer.log('✓ Credit rating: $creditRating', name: 'BlockchainServiceExample');
      
      // Step 7: Get complete credit score information
      final completeCreditScore = await _blockchainService.getCompleteCreditScore(
        DemoUserData.nid,
        monthlyIncome: BigInt.from(50000),
      );
      developer.log('✓ Complete credit score: ${completeCreditScore.score} (${completeCreditScore.rating})', name: 'BlockchainServiceExample');
      
      // Step 8: Process loan application
      final loanAmount = BigInt.from(150000); // Request 150,000 loan
      final loanApplication = await _blockchainService.processLoanApplication(
        nid: DemoUserData.nid,
        requestedAmount: loanAmount,
        monthlyIncome: BigInt.from(50000),
        loanType: LoanType.personal,
      );
      
      developer.log('✓ Loan application processed successfully!', name: 'BlockchainServiceExample');
      developer.log('  - Loan ID: ${loanApplication.id}', name: 'BlockchainServiceExample');
      developer.log('  - Transaction Hash: ${loanApplication.transactionHash}', name: 'BlockchainServiceExample');
      developer.log('  - Approved Amount: ${loanApplication.approvedAmount}', name: 'BlockchainServiceExample');
      developer.log('  - Monthly Payment: ${loanApplication.monthlyPayment}', name: 'BlockchainServiceExample');
      
      // Step 9: Verify transaction
      if (loanApplication.transactionHash != null) {
        final isVerified = await _blockchainService.verifyTransaction(loanApplication.transactionHash!);
        developer.log('✓ Transaction verified: $isVerified', name: 'BlockchainServiceExample');
      }
      
      // Step 10: Get network status
      final networkStatus = await _blockchainService.getNetworkStatus();
      developer.log('✓ Network status: ${networkStatus['isConnected'] ? 'Connected' : 'Disconnected'}', name: 'BlockchainServiceExample');
      
      developer.log('🎉 Loan application demonstration completed successfully!', name: 'BlockchainServiceExample');
      
    } catch (e) {
      developer.log('❌ Loan application demonstration failed: $e', name: 'BlockchainServiceExample');
      rethrow;
    }
  }
  
  /// Example: Credit score analysis
  Future<void> demonstrateCreditScoreAnalysis() async {
    try {
      developer.log('Starting credit score analysis demonstration...', name: 'BlockchainServiceExample');
      
      // Get complete credit score with breakdown
      final creditScore = await _blockchainService.getCompleteCreditScore(
        DemoUserData.nid,
        monthlyIncome: BigInt.from(50000),
      );
      
      developer.log('Credit Score Analysis:', name: 'BlockchainServiceExample');
      developer.log('  - Overall Score: ${creditScore.score}/1000', name: 'BlockchainServiceExample');
      developer.log('  - Credit Rating: ${creditScore.rating}', name: 'BlockchainServiceExample');
      developer.log('  - Max Loan Amount: ${creditScore.maxLoanAmount}', name: 'BlockchainServiceExample');
      developer.log('  - Eligible for Loan: ${creditScore.isEligibleForLoan}', name: 'BlockchainServiceExample');
      developer.log('  - Verified: ${creditScore.isBlockchainVerified}', name: 'BlockchainServiceExample');
      
      developer.log('Score Breakdown:', name: 'BlockchainServiceExample');
      creditScore.scoreBreakdown.forEach((category, points) {
        developer.log('  - $category: $points points', name: 'BlockchainServiceExample');
      });
      
    } catch (e) {
      developer.log('❌ Credit score analysis failed: $e', name: 'BlockchainServiceExample');
    }
  }
  
  /// Example: Network diagnostics
  Future<void> demonstrateNetworkDiagnostics() async {
    try {
      developer.log('Starting network diagnostics...', name: 'BlockchainServiceExample');
      
      final networkStatus = await _blockchainService.getNetworkStatus();
      
      developer.log('Network Diagnostics:', name: 'BlockchainServiceExample');
      developer.log('  - Connected: ${networkStatus['isConnected']}', name: 'BlockchainServiceExample');
      developer.log('  - Network: ${networkStatus['network']}', name: 'BlockchainServiceExample');
      developer.log('  - Chain ID: ${networkStatus['chainId']}', name: 'BlockchainServiceExample');
      developer.log('  - Contract Address: ${networkStatus['contractAddress']}', name: 'BlockchainServiceExample');
      developer.log('  - RPC URL: ${networkStatus['rpcUrl']}', name: 'BlockchainServiceExample');
      
      if (networkStatus['walletBalance'] != null) {
        developer.log('  - Wallet Balance: ${networkStatus['walletBalance']} wei', name: 'BlockchainServiceExample');
      }
      
      if (networkStatus['gasPrice'] != null) {
        developer.log('  - Gas Price: ${networkStatus['gasPrice']} wei', name: 'BlockchainServiceExample');
      }
      
      if (networkStatus['error'] != null) {
        developer.log('  - Error: ${networkStatus['error']}', name: 'BlockchainServiceExample');
      }
      
    } catch (e) {
      developer.log('❌ Network diagnostics failed: $e', name: 'BlockchainServiceExample');
    }
  }
}