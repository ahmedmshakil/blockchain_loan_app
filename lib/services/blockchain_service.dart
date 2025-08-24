import 'dart:async';
import 'dart:developer' as developer;
import 'package:web3dart/web3dart.dart';
import '../models/borrower_model.dart';
import '../models/credit_score_model.dart';
import '../models/loan_model.dart';
import 'web3_service.dart';
import '../config/blockchain_config.dart';
import '../config/secure_storage_config.dart';
import '../config/network_security_config.dart';
import '../utils/input_validator.dart';
import '../utils/memory_manager.dart';

/// High-level blockchain service for smart contract interactions
/// Provides methods for credit scoring, loan processing, and borrower management
class BlockchainService {
  static BlockchainService? _instance;
  final Web3Service _web3Service = Web3Service.instance;
  
  // Singleton pattern for BlockchainService
  static BlockchainService get instance {
    _instance ??= BlockchainService._internal();
    return _instance!;
  }
  
  BlockchainService._internal();
  
  /// Initialize the blockchain service and verify connection
  Future<void> initialize() async {
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Initializing BlockchainService...', name: 'BlockchainService');
      }
      
      // Initialize security components
      await _initializeSecurity();
      
      // Verify Web3 connection
      await _web3Service.getWeb3Client();
      
      // Verify contract is accessible
      await _web3Service.getContract();
      
      // Check network connection
      final isConnected = await _web3Service.isConnectedToSepoliaNetwork();
      if (!isConnected) {
        throw Exception('Not connected to Sepolia testnet');
      }
      
      if (BlockchainConfig.enableLogging) {
        developer.log('BlockchainService initialized successfully', name: 'BlockchainService');
      }
    } catch (e) {
      developer.log('Failed to initialize BlockchainService: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Initialize security components
  Future<void> _initializeSecurity() async {
    try {
      // Initialize secure storage
      final storageInitialized = await SecureStorageConfig.initialize();
      if (!storageInitialized) {
        throw Exception('Failed to initialize secure storage');
      }
      
      // Initialize network security
      await NetworkSecurityConfig.initialize();
      
      // Validate security configuration
      final securityValidation = await NetworkSecurityConfig.validateSecurityConfiguration();
      if (!securityValidation.isSecure) {
        developer.log('Security validation warnings: ${securityValidation.errors}', name: 'BlockchainService');
      }
      
      // Initialize memory manager
      MemoryManager().monitorMemoryPressure();
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Security components initialized', name: 'BlockchainService');
      }
    } catch (e) {
      developer.log('Security initialization failed: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Add a new borrower to the blockchain
  /// Requirements: 2.2, 7.2
  Future<String> addBorrowerToBlockchain(BorrowerModel borrower) async {
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Adding borrower to blockchain: ${borrower.nid}', name: 'BlockchainService');
      }
      
      // Validate input data before blockchain interaction
      await _validateBorrowerData(borrower);
      
      // Check if borrower already exists
      final existingBorrower = await getBorrowerData(borrower.nid);
      if (existingBorrower.exists) {
        throw Exception('Borrower with NID ${borrower.nid} already exists');
      }
      
      // Prepare parameters for smart contract call
      final params = [
        borrower.nid,
        borrower.name,
        borrower.profession,
        borrower.accountBalance,
        borrower.totalTransactions,
        borrower.onTimePayments,
        borrower.missedPayments,
        borrower.totalRemainingLoan,
        borrower.creditAgeMonths,
        borrower.professionRiskScore,
      ];
      
      // Send transaction to add borrower
      final txHash = await _web3Service.sendContractTransaction(
        'addBorrower',
        params,
        gasLimit: 500000, // Higher gas limit for complex operation
      );
      
      // Store transaction hash securely
      await _storeTransactionHash(txHash, 'add_borrower');
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Borrower added successfully. Transaction: $txHash', name: 'BlockchainService');
      }
      
      return txHash;
    } catch (e) {
      developer.log('Failed to add borrower: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Calculate credit score for a borrower using smart contract
  /// Requirements: 3.1, 3.2
  Future<int> calculateCreditScore(String nid) async {
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Calculating credit score for NID: $nid', name: 'BlockchainService');
      }
      
      // Call smart contract function to calculate credit score
      final result = await _web3Service.callContractFunction(
        'calculateCreditScore',
        [nid],
      );
      
      if (result.isEmpty) {
        throw Exception('No credit score returned from smart contract');
      }
      
      final score = (result[0] as BigInt).toInt();
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Credit score calculated: $score for NID: $nid', name: 'BlockchainService');
      }
      
      return score;
    } catch (e) {
      developer.log('Failed to calculate credit score: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Get credit rating for a borrower
  /// Requirements: 3.1, 3.2
  Future<String> getCreditRating(String nid) async {
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Getting credit rating for NID: $nid', name: 'BlockchainService');
      }
      
      // Call smart contract function to get credit rating
      final result = await _web3Service.callContractFunction(
        'getCreditRating',
        [nid],
      );
      
      if (result.isEmpty) {
        throw Exception('No credit rating returned from smart contract');
      }
      
      final rating = result[0] as String;
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Credit rating retrieved: $rating for NID: $nid', name: 'BlockchainService');
      }
      
      return rating;
    } catch (e) {
      developer.log('Failed to get credit rating: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Get maximum loan amount for a borrower based on credit score and income
  /// Requirements: 4.2
  Future<BigInt> getMaxLoanAmount(String nid, BigInt monthlyIncome) async {
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Getting max loan amount for NID: $nid, Income: $monthlyIncome', name: 'BlockchainService');
      }
      
      // Call smart contract function to get maximum loan amount
      final result = await _web3Service.callContractFunction(
        'getMaxLoanAmount',
        [nid, monthlyIncome],
      );
      
      if (result.isEmpty) {
        throw Exception('No max loan amount returned from smart contract');
      }
      
      final maxAmount = result[0] as BigInt;
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Max loan amount calculated: $maxAmount for NID: $nid', name: 'BlockchainService');
      }
      
      return maxAmount;
    } catch (e) {
      developer.log('Failed to get max loan amount: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Request a loan through the smart contract
  /// Requirements: 4.3, 7.1
  Future<String> requestLoan(String nid, BigInt amount) async {
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Requesting loan for NID: $nid, Amount: $amount', name: 'BlockchainService');
      }
      
      // Validate input data
      await _validateLoanAmount(nid, amount);
      
      // Validate borrower exists
      final borrower = await getBorrowerData(nid);
      if (!borrower.exists) {
        throw Exception('Borrower with NID $nid not found');
      }
      
      // Check if amount is within allowed limits
      final maxAmount = await getMaxLoanAmount(nid, BigInt.from(50000)); // Default monthly income
      if (amount > maxAmount) {
        throw Exception('Requested amount ($amount) exceeds maximum allowed ($maxAmount)');
      }
      
      // Send transaction to request loan
      final txHash = await _web3Service.sendContractTransaction(
        'requestLoan',
        [nid, amount],
        gasLimit: 400000, // Higher gas limit for loan processing
      );
      
      // Store transaction hash securely
      await _storeTransactionHash(txHash, 'loan_request');
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Loan requested successfully. Transaction: $txHash', name: 'BlockchainService');
      }
      
      return txHash;
    } catch (e) {
      developer.log('Failed to request loan: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Get borrower data from the blockchain
  /// Requirements: 2.3, 7.1
  Future<BorrowerModel> getBorrowerData(String nid) async {
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Getting borrower data for NID: $nid', name: 'BlockchainService');
      }
      
      // Call smart contract function to get borrower data
      final result = await _web3Service.callContractFunction(
        'getBorrower',
        [nid],
      );
      
      if (result.isEmpty || result.length < 10) {
        throw Exception('Invalid borrower data returned from smart contract');
      }
      
      // Create BorrowerModel from blockchain data
      final borrower = BorrowerModel(
        name: result[0] as String,
        nid: nid, // NID is the input parameter
        profession: result[1] as String,
        accountBalance: result[2] as BigInt,
        totalTransactions: result[3] as BigInt,
        onTimePayments: result[4] as BigInt,
        missedPayments: result[5] as BigInt,
        totalRemainingLoan: result[6] as BigInt,
        creditAgeMonths: result[7] as BigInt,
        professionRiskScore: result[8] as BigInt,
        exists: result[9] as bool,
      );
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Borrower data retrieved: ${borrower.name} (${borrower.nid})', name: 'BlockchainService');
      }
      
      return borrower;
    } catch (e) {
      developer.log('Failed to get borrower data: $e', name: 'BlockchainService');
      // Return empty borrower model if not found
      return BorrowerModel(
        name: '',
        nid: nid,
        profession: '',
        accountBalance: BigInt.zero,
        totalTransactions: BigInt.zero,
        onTimePayments: BigInt.zero,
        missedPayments: BigInt.zero,
        totalRemainingLoan: BigInt.zero,
        creditAgeMonths: BigInt.zero,
        professionRiskScore: BigInt.zero,
        exists: false,
      );
    }
  }  
  
/// Get detailed credit score breakdown from smart contract
  /// Requirements: 3.2
  Future<Map<String, int>> getCreditScoreBreakdown(String nid) async {
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Getting credit score breakdown for NID: $nid', name: 'BlockchainService');
      }
      
      // Call smart contract function to get score breakdown
      final result = await _web3Service.callContractFunction(
        'getScoreBreakdown',
        [nid],
      );
      
      if (result.isEmpty || result.length < 6) {
        throw Exception('Invalid score breakdown returned from smart contract');
      }
      
      // Map the breakdown results to named categories
      final breakdown = {
        'Account Balance': (result[0] as BigInt).toInt(),
        'Transactions': (result[1] as BigInt).toInt(),
        'Payment History': (result[2] as BigInt).toInt(),
        'Remaining Loans': (result[3] as BigInt).toInt(),
        'Credit Age': (result[4] as BigInt).toInt(),
        'Profession Risk': (result[5] as BigInt).toInt(),
      };
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Credit score breakdown retrieved for NID: $nid', name: 'BlockchainService');
      }
      
      return breakdown;
    } catch (e) {
      developer.log('Failed to get credit score breakdown: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Get comprehensive credit score information including breakdown
  /// Requirements: 3.1, 3.2
  Future<CreditScoreModel> getCompleteCreditScore(String nid, {BigInt? monthlyIncome}) async {
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Getting complete credit score for NID: $nid', name: 'BlockchainService');
      }
      
      // Get all credit-related data in parallel for efficiency
      final futures = await Future.wait([
        calculateCreditScore(nid),
        getCreditRating(nid),
        getCreditScoreBreakdown(nid),
        if (monthlyIncome != null) getMaxLoanAmount(nid, monthlyIncome),
      ]);
      
      final score = futures[0] as int;
      final rating = futures[1] as String;
      final breakdown = futures[2] as Map<String, int>;
      final maxLoanAmount = futures.length > 3 ? futures[3] as BigInt : BigInt.zero;
      
      // Create comprehensive credit score model
      final creditScore = CreditScoreModel.fromBlockchainCalculation(
        score: score,
        rating: rating,
        maxLoanAmount: maxLoanAmount,
        scoreBreakdown: breakdown,
      );
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Complete credit score retrieved: $score ($rating) for NID: $nid', name: 'BlockchainService');
      }
      
      return creditScore;
    } catch (e) {
      developer.log('Failed to get complete credit score: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Process a complete loan application with validation and blockchain recording
  /// Requirements: 4.1, 4.2, 4.3, 7.1
  Future<LoanModel> processLoanApplication({
    required String nid,
    required BigInt requestedAmount,
    BigInt? monthlyIncome, // Default monthly income
    LoanType loanType = LoanType.personal,
  }) async {
    monthlyIncome ??= BigInt.from(50000);
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Processing loan application for NID: $nid, Amount: $requestedAmount', name: 'BlockchainService');
      }
      
      // Step 1: Validate borrower exists
      final borrower = await getBorrowerData(nid);
      if (!borrower.exists) {
        throw Exception('Borrower with NID $nid not found. Please register first.');
      }
      
      // Step 2: Calculate current credit score
      final creditScore = await calculateCreditScore(nid);
      
      // Step 3: Check loan eligibility (minimum score of 300)
      if (creditScore < 300) {
        throw Exception('Credit score ($creditScore) is below minimum requirement (300)');
      }
      
      // Step 4: Validate requested amount against maximum allowed
      final maxAmount = await getMaxLoanAmount(nid, monthlyIncome);
      if (requestedAmount > maxAmount) {
        throw Exception('Requested amount (${requestedAmount.toString()}) exceeds maximum allowed (${maxAmount.toString()})');
      }
      
      // Step 5: Submit loan request to blockchain
      final transactionHash = await requestLoan(nid, requestedAmount);
      
      // Step 6: Create loan model from successful transaction
      final loanModel = LoanModel.fromBlockchainTransaction(
        borrowerNid: nid,
        amount: requestedAmount,
        transactionHash: transactionHash,
        creditScore: creditScore,
        type: loanType,
      );
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Loan application processed successfully. Loan ID: ${loanModel.id}', name: 'BlockchainService');
      }
      
      return loanModel;
    } catch (e) {
      developer.log('Failed to process loan application: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Verify transaction status and get confirmation
  /// Requirements: 7.1
  Future<bool> verifyTransaction(String transactionHash) async {
    try {
      if (BlockchainConfig.enableLogging) {
        developer.log('Verifying transaction: $transactionHash', name: 'BlockchainService');
      }
      
      final receipt = await _web3Service.waitForTransactionConfirmation(transactionHash);
      
      if (receipt != null) {
        final isSuccess = receipt.status == true;
        
        if (BlockchainConfig.enableLogging) {
          developer.log('Transaction verified: $transactionHash, Success: $isSuccess', name: 'BlockchainService');
        }
        
        return isSuccess;
      }
      
      // Transaction is still pending
      return false;
    } catch (e) {
      developer.log('Failed to verify transaction: $e', name: 'BlockchainService');
      return false;
    }
  }
  
  /// Get current blockchain network status and connection health
  /// Requirements: 2.1, 7.2
  Future<Map<String, dynamic>> getNetworkStatus() async {
    try {
      final futures = await Future.wait([
        _web3Service.isConnectedToSepoliaNetwork(),
        _web3Service.getBalance(),
        _web3Service.getGasPrice(),
      ]);
      
      final isConnected = futures[0] as bool;
      final balance = futures[1] as EtherAmount;
      final gasPrice = futures[2] as EtherAmount;
      
      return {
        'isConnected': isConnected,
        'network': BlockchainConfig.networkName,
        'chainId': BlockchainConfig.chainId,
        'walletBalance': balance.getInWei.toString(),
        'gasPrice': gasPrice.getInWei.toString(),
        'contractAddress': BlockchainConfig.contractAddress,
        'rpcUrl': BlockchainConfig.rpcUrl,
      };
    } catch (e) {
      developer.log('Failed to get network status: $e', name: 'BlockchainService');
      return {
        'isConnected': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Get blockchain event stream for real-time synchronization
  /// Requirements: 7.4
  Stream<Map<String, dynamic>>? getBlockchainEventStream() {
    try {
      // Create a stream controller for blockchain events
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      
      // In a real implementation, this would listen to blockchain events
      // For now, we'll create a periodic stream that simulates blockchain events
      Timer.periodic(const Duration(minutes: 1), (timer) {
        if (!controller.isClosed) {
          // Simulate network status change events
          controller.add({
            'type': 'network_status_changed',
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else {
          timer.cancel();
        }
      });
      
      // Listen for contract events (in a real implementation)
      // This would use web3dart's event filtering capabilities
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Blockchain event stream started', name: 'BlockchainService');
      }
      
      return controller.stream;
    } catch (e) {
      developer.log('Failed to create blockchain event stream: $e', name: 'BlockchainService');
      return null;
    }
  }
  
  /// Dispose resources and cleanup
  void dispose() {
    _web3Service.dispose();
    _instance = null;
  }
  
  /// Validate borrower data before blockchain operations
  Future<void> _validateBorrowerData(BorrowerModel borrower) async {
    try {
      // Validate NID
      final nidValidation = InputValidator.validateNID(borrower.nid);
      if (!nidValidation.isValid) {
        throw ArgumentError('Invalid NID: ${nidValidation.message}');
      }
      
      // Validate name
      final nameValidation = InputValidator.validateName(borrower.name);
      if (!nameValidation.isValid) {
        throw ArgumentError('Invalid name: ${nameValidation.message}');
      }
      
      // Validate profession
      final professionValidation = InputValidator.validateProfession(borrower.profession);
      if (!professionValidation.isValid) {
        throw ArgumentError('Invalid profession: ${professionValidation.message}');
      }
      
      // Validate numeric values
      if (borrower.accountBalance < BigInt.zero) {
        throw ArgumentError('Account balance cannot be negative');
      }
      
      if (borrower.totalTransactions < BigInt.zero) {
        throw ArgumentError('Total transactions cannot be negative');
      }
      
      if (borrower.onTimePayments < BigInt.zero) {
        throw ArgumentError('On-time payments cannot be negative');
      }
      
      if (borrower.missedPayments < BigInt.zero) {
        throw ArgumentError('Missed payments cannot be negative');
      }
      
      if (borrower.creditAgeMonths < BigInt.zero) {
        throw ArgumentError('Credit age cannot be negative');
      }
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Borrower data validation passed', name: 'BlockchainService');
      }
    } catch (e) {
      developer.log('Borrower data validation failed: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Validate loan amount before processing
  Future<void> _validateLoanAmount(String nid, BigInt amount) async {
    try {
      // Validate NID
      final nidValidation = InputValidator.validateNID(nid);
      if (!nidValidation.isValid) {
        throw ArgumentError('Invalid NID: ${nidValidation.message}');
      }
      
      // Validate loan amount
      final amountValidation = InputValidator.validateLoanAmount(
        amount.toString(),
        minAmount: 100.0, // Minimum loan amount
        maxAmount: 1000000.0, // Maximum loan amount
      );
      if (!amountValidation.isValid) {
        throw ArgumentError('Invalid loan amount: ${amountValidation.message}');
      }
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Loan amount validation passed', name: 'BlockchainService');
      }
    } catch (e) {
      developer.log('Loan amount validation failed: $e', name: 'BlockchainService');
      rethrow;
    }
  }
  
  /// Securely store transaction hash
  Future<void> _storeTransactionHash(String transactionHash, String operation) async {
    try {
      // Validate transaction hash format
      final hashValidation = InputValidator.validateTransactionHash(transactionHash);
      if (!hashValidation.isValid) {
        throw ArgumentError('Invalid transaction hash: ${hashValidation.message}');
      }
      
      // Store in secure storage with operation context
      final transactionData = {
        'hash': transactionHash,
        'operation': operation,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await SecureStorageConfig.storeUserCredentials(transactionData);
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Transaction hash stored securely', name: 'BlockchainService');
      }
    } catch (e) {
      developer.log('Failed to store transaction hash: $e', name: 'BlockchainService');
      // Don't rethrow - this is not critical for the main operation
    }
  }
  
  /// Clean up sensitive data from memory
  void _cleanupSensitiveData() {
    try {
      MemoryManager().forceCleanup();
      
      if (BlockchainConfig.enableLogging) {
        developer.log('Sensitive data cleanup completed', name: 'BlockchainService');
      }
    } catch (e) {
      developer.log('Sensitive data cleanup failed: $e', name: 'BlockchainService');
    }
  }
}