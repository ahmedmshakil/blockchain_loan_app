import 'dart:developer' as developer;
import '../models/credit_score_model.dart';
import '../utils/constants.dart';
import 'blockchain_service.dart';

/// Service for credit scoring calculations and real-time blockchain data fetching
/// Implements credit calculation logic, rating determination, and loan amount calculations
/// Requirements: 3.1, 3.2, 3.3, 4.2
class CreditScoringService {
  static CreditScoringService? _instance;
  final BlockchainService _blockchainService = BlockchainService.instance;
  
  // Cache for credit scores to avoid repeated blockchain calls
  final Map<String, CreditScoreModel> _creditScoreCache = {};
  final Duration _cacheExpiration = const Duration(minutes: 5);
  
  // Singleton pattern for CreditScoringService
  static CreditScoringService get instance {
    _instance ??= CreditScoringService._internal();
    return _instance!;
  }
  
  CreditScoringService._internal();
  
  /// Calculate comprehensive credit score with real-time blockchain data
  /// Requirements: 3.1, 3.2
  Future<CreditScoreModel> calculateCreditScore(String nid, {BigInt? monthlyIncome}) async {
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Calculating credit score for NID: $nid', name: 'CreditScoringService');
      }
      
      // Check cache first
      final cachedScore = _getCachedCreditScore(nid);
      if (cachedScore != null) {
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Returning cached credit score for NID: $nid', name: 'CreditScoringService');
        }
        return cachedScore;
      }
      
      // Fetch real-time data from blockchain
      final borrower = await _blockchainService.getBorrowerData(nid);
      if (!borrower.exists) {
        throw Exception('Borrower with NID $nid not found on blockchain');
      }
      
      // Calculate score using blockchain data
      final score = await _blockchainService.calculateCreditScore(nid);
      final rating = await _blockchainService.getCreditRating(nid);
      final scoreBreakdown = await _blockchainService.getCreditScoreBreakdown(nid);
      
      // Calculate maximum loan amount if monthly income is provided
      BigInt maxLoanAmount = BigInt.zero;
      if (monthlyIncome != null) {
        maxLoanAmount = await _blockchainService.getMaxLoanAmount(nid, monthlyIncome);
      }
      
      // Create comprehensive credit score model
      final creditScoreModel = CreditScoreModel.fromBlockchainCalculation(
        score: score,
        rating: rating,
        maxLoanAmount: maxLoanAmount,
        scoreBreakdown: scoreBreakdown,
      );
      
      // Cache the result
      _cacheCreditscore(nid, creditScoreModel);
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Credit score calculated: $score ($rating) for NID: $nid', name: 'CreditScoringService');
      }
      
      return creditScoreModel;
    } catch (e) {
      developer.log('Failed to calculate credit score: $e', name: 'CreditScoringService');
      rethrow;
    }
  }
  
  /// Get real-time credit score from smart contract
  /// Requirements: 3.1, 3.2
  Future<int> getRealTimeCreditScore(String nid) async {
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Fetching real-time credit score for NID: $nid', name: 'CreditScoringService');
      }
      
      // Direct call to blockchain for most up-to-date score
      final score = await _blockchainService.calculateCreditScore(nid);
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Real-time credit score fetched: $score for NID: $nid', name: 'CreditScoringService');
      }
      
      return score;
    } catch (e) {
      developer.log('Failed to fetch real-time credit score: $e', name: 'CreditScoringService');
      rethrow;
    }
  }
  
  /// Calculate credit rating based on score
  /// Requirements: 3.2
  String calculateCreditRating(int creditScore) {
    if (creditScore >= AppConstants.excellentCreditThreshold) {
      return 'A'; // Excellent (800-1000)
    } else if (creditScore >= AppConstants.goodCreditThreshold) {
      return 'B'; // Good (650-799)
    } else if (creditScore >= AppConstants.fairCreditThreshold) {
      return 'C'; // Fair (500-649)
    } else {
      return 'D'; // Poor (0-499)
    }
  }
  
  /// Get detailed credit score breakdown with explanations
  /// Requirements: 3.2, 3.3
  Future<Map<String, dynamic>> getDetailedScoreBreakdown(String nid) async {
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Getting detailed score breakdown for NID: $nid', name: 'CreditScoringService');
      }
      
      // Get borrower data and score breakdown from blockchain
      final borrower = await _blockchainService.getBorrowerData(nid);
      final scoreBreakdown = await _blockchainService.getCreditScoreBreakdown(nid);
      
      // Calculate detailed breakdown with explanations
      final detailedBreakdown = {
        'accountBalance': {
          'score': scoreBreakdown['Account Balance'] ?? 0,
          'weight': AppConstants.creditScoreWeights['accountBalance'],
          'value': borrower.accountBalance.toString(),
          'explanation': 'Higher account balance indicates better financial stability',
        },
        'transactions': {
          'score': scoreBreakdown['Transactions'] ?? 0,
          'weight': AppConstants.creditScoreWeights['transactions'],
          'value': borrower.totalTransactions.toString(),
          'explanation': 'Regular transaction activity shows active financial management',
        },
        'paymentHistory': {
          'score': scoreBreakdown['Payment History'] ?? 0,
          'weight': AppConstants.creditScoreWeights['paymentHistory'],
          'value': '${borrower.onTimePayments}/${borrower.onTimePayments + borrower.missedPayments}',
          'explanation': 'On-time payments are the most important factor in credit scoring',
        },
        'remainingLoans': {
          'score': scoreBreakdown['Remaining Loans'] ?? 0,
          'weight': AppConstants.creditScoreWeights['remainingLoans'],
          'value': borrower.totalRemainingLoan.toString(),
          'explanation': 'Lower outstanding debt improves credit score',
        },
        'creditAge': {
          'score': scoreBreakdown['Credit Age'] ?? 0,
          'weight': AppConstants.creditScoreWeights['creditAge'],
          'value': '${borrower.creditAgeMonths} months',
          'explanation': 'Longer credit history demonstrates experience with credit management',
        },
        'professionRisk': {
          'score': scoreBreakdown['Profession Risk'] ?? 0,
          'weight': AppConstants.creditScoreWeights['professionRisk'],
          'value': borrower.profession,
          'explanation': 'Profession stability affects credit risk assessment',
        },
      };
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Detailed score breakdown calculated for NID: $nid', name: 'CreditScoringService');
      }
      
      return detailedBreakdown;
    } catch (e) {
      developer.log('Failed to get detailed score breakdown: $e', name: 'CreditScoringService');
      rethrow;
    }
  }
  
  /// Calculate maximum loan amount based on credit score and income
  /// Requirements: 4.2
  Future<BigInt> calculateMaxLoanAmount(String nid, BigInt monthlyIncome) async {
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Calculating max loan amount for NID: $nid, Income: $monthlyIncome', name: 'CreditScoringService');
      }
      
      // Get real-time calculation from smart contract
      final maxAmount = await _blockchainService.getMaxLoanAmount(nid, monthlyIncome);
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Max loan amount calculated: $maxAmount for NID: $nid', name: 'CreditScoringService');
      }
      
      return maxAmount;
    } catch (e) {
      developer.log('Failed to calculate max loan amount: $e', name: 'CreditScoringService');
      rethrow;
    }
  }
  
  /// Get loan eligibility assessment
  /// Requirements: 3.3, 4.2
  Future<Map<String, dynamic>> getLoanEligibilityAssessment(String nid, BigInt monthlyIncome, BigInt requestedAmount) async {
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Assessing loan eligibility for NID: $nid, Amount: $requestedAmount', name: 'CreditScoringService');
      }
      
      // Get current credit score and maximum loan amount
      final creditScore = await getRealTimeCreditScore(nid);
      final maxLoanAmount = await calculateMaxLoanAmount(nid, monthlyIncome);
      final creditRating = calculateCreditRating(creditScore);
      
      // Determine eligibility
      final isEligible = creditScore >= 300 && requestedAmount <= maxLoanAmount;
      
      // Calculate debt-to-income ratio
      final borrower = await _blockchainService.getBorrowerData(nid);
      final currentDebt = borrower.totalRemainingLoan;
      final totalDebtAfterLoan = currentDebt + (isEligible ? requestedAmount : BigInt.zero);
      final debtToIncomeRatio = (totalDebtAfterLoan.toDouble() / (monthlyIncome.toDouble() * 12)) * 100;
      
      // Determine interest rate based on credit score
      double interestRate = AppConstants.loanInterestRate;
      if (creditScore >= 800) {
        interestRate = 10.0; // Excellent credit gets lower rate
      } else if (creditScore >= 650) {
        interestRate = 11.5; // Good credit gets slightly lower rate
      }
      
      final assessment = {
        'isEligible': isEligible,
        'creditScore': creditScore,
        'creditRating': creditRating,
        'requestedAmount': requestedAmount.toString(),
        'maxLoanAmount': maxLoanAmount.toString(),
        'monthlyIncome': monthlyIncome.toString(),
        'currentDebt': currentDebt.toString(),
        'debtToIncomeRatio': debtToIncomeRatio.toStringAsFixed(2),
        'interestRate': interestRate,
        'loanTermMonths': AppConstants.maxLoanTermMonths,
        'reasons': _getEligibilityReasons(isEligible, creditScore, requestedAmount, maxLoanAmount),
      };
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Loan eligibility assessed: $isEligible for NID: $nid', name: 'CreditScoringService');
      }
      
      return assessment;
    } catch (e) {
      developer.log('Failed to assess loan eligibility: $e', name: 'CreditScoringService');
      rethrow;
    }
  }
  
  /// Get credit score improvement recommendations
  /// Requirements: 3.3
  Future<List<String>> getCreditScoreRecommendations(String nid) async {
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Getting credit score recommendations for NID: $nid', name: 'CreditScoringService');
      }
      
      final borrower = await _blockchainService.getBorrowerData(nid);
      final scoreBreakdown = await _blockchainService.getCreditScoreBreakdown(nid);
      final recommendations = <String>[];
      
      // Analyze each component and provide recommendations
      
      // Account Balance
      final balanceScore = scoreBreakdown['Account Balance'] ?? 0;
      if (balanceScore < 200) { // Assuming max 250 points for account balance
        recommendations.add('Maintain a higher account balance to improve your credit score');
      }
      
      // Payment History
      final paymentScore = scoreBreakdown['Payment History'] ?? 0;
      if (paymentScore < 250) { // Assuming max 300 points for payment history
        recommendations.add('Make all payments on time to build a strong payment history');
      }
      
      // Remaining Loans
      final loanScore = scoreBreakdown['Remaining Loans'] ?? 0;
      if (loanScore < 80 && borrower.totalRemainingLoan > BigInt.zero) { // Assuming max 100 points
        recommendations.add('Pay down existing loans to reduce your debt burden');
      }
      
      // Credit Age
      final ageScore = scoreBreakdown['Credit Age'] ?? 0;
      if (ageScore < 80) { // Assuming max 100 points
        recommendations.add('Continue building your credit history over time');
      }
      
      // Transaction Activity
      final transactionScore = scoreBreakdown['Transactions'] ?? 0;
      if (transactionScore < 120) { // Assuming max 150 points
        recommendations.add('Maintain regular transaction activity to show active account usage');
      }
      
      // General recommendations
      if (recommendations.isEmpty) {
        recommendations.add('Excellent credit profile! Continue your current financial habits');
      } else {
        recommendations.add('Monitor your credit score regularly for improvements');
        recommendations.add('Consider setting up automatic payments to avoid missed payments');
      }
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Generated ${recommendations.length} recommendations for NID: $nid', name: 'CreditScoringService');
      }
      
      return recommendations;
    } catch (e) {
      developer.log('Failed to get credit score recommendations: $e', name: 'CreditScoringService');
      rethrow;
    }
  }
  
  /// Validate loan application parameters
  /// Requirements: 4.2
  Map<String, dynamic> validateLoanApplication({
    required String nid,
    required BigInt requestedAmount,
    required BigInt monthlyIncome,
  }) {
    final validationResults = <String, dynamic>{
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };
    
    // Validate NID format
    if (nid.isEmpty || nid.length < 10) {
      validationResults['errors'].add('Invalid NID format');
      validationResults['isValid'] = false;
    }
    
    // Validate requested amount
    if (requestedAmount <= BigInt.zero) {
      validationResults['errors'].add('Loan amount must be greater than zero');
      validationResults['isValid'] = false;
    }
    
    if (requestedAmount < BigInt.from(10000)) {
      validationResults['warnings'].add('Minimum recommended loan amount is 10,000 BDT');
    }
    
    // Validate monthly income
    if (monthlyIncome <= BigInt.zero) {
      validationResults['errors'].add('Monthly income must be greater than zero');
      validationResults['isValid'] = false;
    }
    
    if (monthlyIncome < BigInt.from(20000)) {
      validationResults['warnings'].add('Low monthly income may affect loan approval');
    }
    
    // Check debt-to-income ratio (basic validation)
    final maxRecommendedLoan = monthlyIncome * BigInt.from(36); // 3x annual income
    if (requestedAmount > maxRecommendedLoan) {
      validationResults['warnings'].add('Requested amount exceeds recommended debt-to-income ratio');
    }
    
    return validationResults;
  }
  
  /// Clear credit score cache
  void clearCache() {
    _creditScoreCache.clear();
    if (EnvironmentConfig.enableDetailedLogging) {
      developer.log('Credit score cache cleared', name: 'CreditScoringService');
    }
  }
  
  /// Clear cache for specific NID
  void clearCacheForNid(String nid) {
    _creditScoreCache.remove(nid);
    if (EnvironmentConfig.enableDetailedLogging) {
      developer.log('Cache cleared for NID: $nid', name: 'CreditScoringService');
    }
  }
  
  // Private helper methods
  
  /// Get cached credit score if available and not expired
  CreditScoreModel? _getCachedCreditScore(String nid) {
    final cached = _creditScoreCache[nid];
    if (cached != null) {
      final age = DateTime.now().difference(cached.calculatedAt);
      if (age < _cacheExpiration) {
        return cached;
      } else {
        // Remove expired cache entry
        _creditScoreCache.remove(nid);
      }
    }
    return null;
  }
  
  /// Cache credit score result
  void _cacheCreditscore(String nid, CreditScoreModel creditScore) {
    _creditScoreCache[nid] = creditScore;
  }
  
  /// Get eligibility reasons based on assessment
  List<String> _getEligibilityReasons(bool isEligible, int creditScore, BigInt requestedAmount, BigInt maxLoanAmount) {
    final reasons = <String>[];
    
    if (isEligible) {
      reasons.add('Credit score ($creditScore) meets minimum requirement');
      reasons.add('Requested amount is within approved limit');
      reasons.add('Blockchain verification successful');
    } else {
      if (creditScore < 300) {
        reasons.add('Credit score ($creditScore) is below minimum requirement (300)');
      }
      if (requestedAmount > maxLoanAmount) {
        reasons.add('Requested amount exceeds maximum approved limit');
      }
    }
    
    return reasons;
  }
  
  /// Dispose resources and cleanup
  void dispose() {
    clearCache();
    _instance = null;
  }
}