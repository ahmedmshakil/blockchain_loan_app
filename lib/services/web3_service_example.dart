import 'dart:developer' as developer;
import 'package:web3dart/web3dart.dart';
import 'web3_service.dart';

/// Example usage of Web3Service
/// This file demonstrates how to use the Web3Service for common blockchain operations
class Web3ServiceExample {
  final Web3Service _web3Service = Web3Service.instance;
  
  /// Example: Initialize and test blockchain connection
  Future<void> testBlockchainConnection() async {
    try {
      developer.log('Testing blockchain connection...', name: 'Web3ServiceExample');
      
      // Initialize Web3 client
      final web3Client = await _web3Service.getWeb3Client();
      developer.log('✓ Web3 client initialized', name: 'Web3ServiceExample');
      
      // Check network connection
      final isConnected = await _web3Service.isConnectedToSepoliaNetwork();
      developer.log('✓ Connected to Sepolia: $isConnected', name: 'Web3ServiceExample');
      
      // Get contract
      final contract = await _web3Service.getContract();
      developer.log('✓ Contract loaded at: ${contract.address.hex}', name: 'Web3ServiceExample');
      
    } catch (e) {
      developer.log('✗ Blockchain connection failed: $e', name: 'Web3ServiceExample');
      rethrow;
    }
  }
  
  /// Example: Add a borrower to the blockchain
  Future<String> addBorrowerExample() async {
    try {
      developer.log('Adding borrower to blockchain...', name: 'Web3ServiceExample');
      
      // Example borrower data
      final params = [
        '1029384957', // nid
        'Shakil AHmed', // name
        'Blockchain Developer', // profession
        BigInt.from(508088), // accountBalance
        BigInt.from(1505200), // totalTransactions
        BigInt.from(45), // onTimePayments
        BigInt.from(1), // missedPayments
        BigInt.from(83000), // totalRemainingLoan
        BigInt.from(5), // creditAgeMonths
        BigInt.from(20), // professionRiskScore (low risk for tech)
      ];
      
      final txHash = await _web3Service.sendContractTransaction(
        'addBorrower',
        params,
      );
      
      developer.log('✓ Borrower added successfully: $txHash', name: 'Web3ServiceExample');
      return txHash;
      
    } catch (e) {
      developer.log('✗ Failed to add borrower: $e', name: 'Web3ServiceExample');
      rethrow;
    }
  }
  
  /// Example: Calculate credit score
  Future<BigInt> calculateCreditScoreExample(String nid) async {
    try {
      developer.log('Calculating credit score for NID: $nid', name: 'Web3ServiceExample');
      
      final result = await _web3Service.callContractFunction(
        'calculateCreditScore',
        [nid],
      );
      
      final creditScore = result[0] as BigInt;
      developer.log('✓ Credit score calculated: $creditScore', name: 'Web3ServiceExample');
      
      return creditScore;
      
    } catch (e) {
      developer.log('✗ Failed to calculate credit score: $e', name: 'Web3ServiceExample');
      rethrow;
    }
  }
  
  /// Example: Get credit rating
  Future<String> getCreditRatingExample(String nid) async {
    try {
      developer.log('Getting credit rating for NID: $nid', name: 'Web3ServiceExample');
      
      final result = await _web3Service.callContractFunction(
        'getCreditRating',
        [nid],
      );
      
      final rating = result[0] as String;
      developer.log('✓ Credit rating: $rating', name: 'Web3ServiceExample');
      
      return rating;
      
    } catch (e) {
      developer.log('✗ Failed to get credit rating: $e', name: 'Web3ServiceExample');
      rethrow;
    }
  }
  
  /// Example: Get maximum loan amount
  Future<BigInt> getMaxLoanAmountExample(String nid, BigInt monthlyIncome) async {
    try {
      developer.log('Getting max loan amount for NID: $nid', name: 'Web3ServiceExample');
      
      final result = await _web3Service.callContractFunction(
        'getMaxLoanAmount',
        [nid, monthlyIncome],
      );
      
      final maxAmount = result[0] as BigInt;
      developer.log('✓ Max loan amount: $maxAmount', name: 'Web3ServiceExample');
      
      return maxAmount;
      
    } catch (e) {
      developer.log('✗ Failed to get max loan amount: $e', name: 'Web3ServiceExample');
      rethrow;
    }
  }
  
  /// Example: Request a loan
  Future<String> requestLoanExample(String nid, BigInt amount) async {
    try {
      developer.log('Requesting loan for NID: $nid, Amount: $amount', name: 'Web3ServiceExample');
      
      final txHash = await _web3Service.sendContractTransaction(
        'requestLoan',
        [nid, amount],
      );
      
      developer.log('✓ Loan requested successfully: $txHash', name: 'Web3ServiceExample');
      return txHash;
      
    } catch (e) {
      developer.log('✗ Failed to request loan: $e', name: 'Web3ServiceExample');
      rethrow;
    }
  }
  
  /// Example: Get borrower data
  Future<Map<String, dynamic>> getBorrowerDataExample(String nid) async {
    try {
      developer.log('Getting borrower data for NID: $nid', name: 'Web3ServiceExample');
      
      final result = await _web3Service.callContractFunction(
        'getBorrower',
        [nid],
      );
      
      final borrowerData = {
        'name': result[0] as String,
        'profession': result[1] as String,
        'accountBalance': result[2] as BigInt,
        'totalTransactions': result[3] as BigInt,
        'onTimePayments': result[4] as BigInt,
        'missedPayments': result[5] as BigInt,
        'totalRemainingLoan': result[6] as BigInt,
        'creditAgeMonths': result[7] as BigInt,
        'professionRiskScore': result[8] as BigInt,
        'exists': result[9] as bool,
      };
      
      developer.log('✓ Borrower data retrieved successfully', name: 'Web3ServiceExample');
      return borrowerData;
      
    } catch (e) {
      developer.log('✗ Failed to get borrower data: $e', name: 'Web3ServiceExample');
      rethrow;
    }
  }
  
  /// Example: Check wallet balance
  Future<EtherAmount> checkWalletBalanceExample() async {
    try {
      developer.log('Checking wallet balance...', name: 'Web3ServiceExample');
      
      final balance = await _web3Service.getBalance();
      developer.log('✓ Wallet balance: ${balance.getInWei} wei', name: 'Web3ServiceExample');
      
      return balance;
      
    } catch (e) {
      developer.log('✗ Failed to check wallet balance: $e', name: 'Web3ServiceExample');
      rethrow;
    }
  }
  
  /// Example: Wait for transaction confirmation
  Future<bool> waitForTransactionExample(String txHash) async {
    try {
      developer.log('Waiting for transaction confirmation: $txHash', name: 'Web3ServiceExample');
      
      final receipt = await _web3Service.waitForTransactionConfirmation(txHash);
      
      if (receipt != null) {
        developer.log('✓ Transaction confirmed in block: ${receipt.blockNumber}', name: 'Web3ServiceExample');
        return true;
      } else {
        developer.log('⏳ Transaction still pending...', name: 'Web3ServiceExample');
        return false;
      }
      
    } catch (e) {
      developer.log('✗ Failed to get transaction confirmation: $e', name: 'Web3ServiceExample');
      rethrow;
    }
  }
  
  /// Complete example workflow
  Future<void> completeWorkflowExample() async {
    try {
      developer.log('Starting complete blockchain workflow...', name: 'Web3ServiceExample');
      
      // 1. Test connection
      await testBlockchainConnection();
      
      // 2. Check wallet balance
      await checkWalletBalanceExample();
      
      // 3. Add borrower (if not exists)
      final addTxHash = await addBorrowerExample();
      await waitForTransactionExample(addTxHash);
      
      // 4. Get borrower data
      final borrowerData = await getBorrowerDataExample('1029384957');
      
      // 5. Calculate credit score
      final creditScore = await calculateCreditScoreExample('1029384957');
      
      // 6. Get credit rating
      final rating = await getCreditRatingExample('1029384957');
      
      // 7. Get max loan amount
      final maxLoan = await getMaxLoanAmountExample('1029384957', BigInt.from(50000));
      
      // 8. Request loan
      final loanTxHash = await requestLoanExample('1029384957', BigInt.from(25000));
      await waitForTransactionExample(loanTxHash);
      
      developer.log('✓ Complete workflow finished successfully!', name: 'Web3ServiceExample');
      
    } catch (e) {
      developer.log('✗ Workflow failed: $e', name: 'Web3ServiceExample');
      rethrow;
    }
  }
}