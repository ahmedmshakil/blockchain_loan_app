import 'dart:developer' as developer;
import 'credit_scoring_service.dart';
import '../utils/constants.dart';

/// Example usage of CreditScoringService
/// This file demonstrates how to use the credit scoring service for various operations
class CreditScoringServiceExample {
  final CreditScoringService _creditScoringService = CreditScoringService.instance;
  
  /// Example: Calculate comprehensive credit score for a borrower
  Future<void> exampleCalculateCreditScore() async {
    try {
      const nid = DemoUserData.nid;
      final monthlyIncome = BigInt.parse(DemoUserData.monthlyIncome);
      
      developer.log('Calculating credit score for ${DemoUserData.name}...', name: 'CreditScoringExample');
      
      // Calculate comprehensive credit score with real-time blockchain data
      final creditScore = await _creditScoringService.calculateCreditScore(
        nid, 
        monthlyIncome: monthlyIncome,
      );
      
      developer.log('Credit Score Results:', name: 'CreditScoringExample');
      developer.log('- Score: ${creditScore.score}/1000', name: 'CreditScoringExample');
      developer.log('- Rating: ${creditScore.rating}', name: 'CreditScoringExample');
      developer.log('- Max Loan Amount: ${creditScore.maxLoanAmount} BDT', name: 'CreditScoringExample');
      developer.log('- Verified: ${creditScore.isBlockchainVerified}', name: 'CreditScoringExample');
      developer.log('- Score Breakdown: ${creditScore.scoreBreakdown}', name: 'CreditScoringExample');
      
    } catch (e) {
      developer.log('Error calculating credit score: $e', name: 'CreditScoringExample');
    }
  }
  
  /// Example: Get real-time credit score from blockchain
  Future<void> exampleGetRealTimeCreditScore() async {
    try {
      const nid = DemoUserData.nid;
      
      developer.log('Fetching real-time credit score...', name: 'CreditScoringExample');
      
      final score = await _creditScoringService.getRealTimeCreditScore(nid);
      final rating = _creditScoringService.calculateCreditRating(score);
      
      developer.log('Real-time Credit Score: $score ($rating)', name: 'CreditScoringExample');
      
    } catch (e) {
      developer.log('Error fetching real-time credit score: $e', name: 'CreditScoringExample');
    }
  }
  
  /// Example: Get detailed score breakdown with explanations
  Future<void> exampleGetDetailedScoreBreakdown() async {
    try {
      const nid = DemoUserData.nid;
      
      developer.log('Getting detailed score breakdown...', name: 'CreditScoringExample');
      
      final breakdown = await _creditScoringService.getDetailedScoreBreakdown(nid);
      
      developer.log('Detailed Score Breakdown:', name: 'CreditScoringExample');
      
      breakdown.forEach((category, data) {
        final categoryData = data as Map<String, dynamic>;
        developer.log('- $category:', name: 'CreditScoringExample');
        developer.log('  Score: ${categoryData['score']} points', name: 'CreditScoringExample');
        developer.log('  Weight: ${categoryData['weight']}%', name: 'CreditScoringExample');
        developer.log('  Value: ${categoryData['value']}', name: 'CreditScoringExample');
        developer.log('  Explanation: ${categoryData['explanation']}', name: 'CreditScoringExample');
      });
      
    } catch (e) {
      developer.log('Error getting detailed score breakdown: $e', name: 'CreditScoringExample');
    }
  }
  
  /// Example: Calculate maximum loan amount
  Future<void> exampleCalculateMaxLoanAmount() async {
    try {
      const nid = DemoUserData.nid;
      final monthlyIncome = BigInt.parse(DemoUserData.monthlyIncome);
      
      developer.log('Calculating maximum loan amount...', name: 'CreditScoringExample');
      
      final maxAmount = await _creditScoringService.calculateMaxLoanAmount(nid, monthlyIncome);
      
      developer.log('Maximum Loan Amount: $maxAmount BDT', name: 'CreditScoringExample');
      developer.log('Monthly Income: $monthlyIncome BDT', name: 'CreditScoringExample');
      
    } catch (e) {
      developer.log('Error calculating max loan amount: $e', name: 'CreditScoringExample');
    }
  }
  
  /// Example: Assess loan eligibility
  Future<void> exampleAssessLoanEligibility() async {
    try {
      const nid = DemoUserData.nid;
      final monthlyIncome = BigInt.parse(DemoUserData.monthlyIncome);
      final requestedAmount = BigInt.from(150000); // 150,000 BDT
      
      developer.log('Assessing loan eligibility...', name: 'CreditScoringExample');
      
      final assessment = await _creditScoringService.getLoanEligibilityAssessment(
        nid, 
        monthlyIncome, 
        requestedAmount,
      );
      
      developer.log('Loan Eligibility Assessment:', name: 'CreditScoringExample');
      developer.log('- Eligible: ${assessment['isEligible']}', name: 'CreditScoringExample');
      developer.log('- Credit Score: ${assessment['creditScore']}', name: 'CreditScoringExample');
      developer.log('- Credit Rating: ${assessment['creditRating']}', name: 'CreditScoringExample');
      developer.log('- Requested Amount: ${assessment['requestedAmount']} BDT', name: 'CreditScoringExample');
      developer.log('- Max Loan Amount: ${assessment['maxLoanAmount']} BDT', name: 'CreditScoringExample');
      developer.log('- Interest Rate: ${assessment['interestRate']}%', name: 'CreditScoringExample');
      developer.log('- Debt-to-Income Ratio: ${assessment['debtToIncomeRatio']}%', name: 'CreditScoringExample');
      
      final reasons = assessment['reasons'] as List<String>;
      developer.log('- Reasons:', name: 'CreditScoringExample');
      for (final reason in reasons) {
        developer.log('  * $reason', name: 'CreditScoringExample');
      }
      
    } catch (e) {
      developer.log('Error assessing loan eligibility: $e', name: 'CreditScoringExample');
    }
  }
  
  /// Example: Get credit score recommendations
  Future<void> exampleGetCreditScoreRecommendations() async {
    try {
      const nid = DemoUserData.nid;
      
      developer.log('Getting credit score recommendations...', name: 'CreditScoringExample');
      
      final recommendations = await _creditScoringService.getCreditScoreRecommendations(nid);
      
      developer.log('Credit Score Recommendations:', name: 'CreditScoringExample');
      for (int i = 0; i < recommendations.length; i++) {
        developer.log('${i + 1}. ${recommendations[i]}', name: 'CreditScoringExample');
      }
      
    } catch (e) {
      developer.log('Error getting credit score recommendations: $e', name: 'CreditScoringExample');
    }
  }
  
  /// Example: Validate loan application parameters
  void exampleValidateLoanApplication() {
    developer.log('Validating loan application parameters...', name: 'CreditScoringExample');
    
    // Test valid parameters
    final validResult = _creditScoringService.validateLoanApplication(
      nid: DemoUserData.nid,
      requestedAmount: BigInt.from(100000),
      monthlyIncome: BigInt.parse(DemoUserData.monthlyIncome),
    );
    
    developer.log('Valid Application Result:', name: 'CreditScoringExample');
    developer.log('- Is Valid: ${validResult['isValid']}', name: 'CreditScoringExample');
    developer.log('- Errors: ${validResult['errors']}', name: 'CreditScoringExample');
    developer.log('- Warnings: ${validResult['warnings']}', name: 'CreditScoringExample');
    
    // Test invalid parameters
    final invalidResult = _creditScoringService.validateLoanApplication(
      nid: '123', // Too short
      requestedAmount: BigInt.zero, // Invalid
      monthlyIncome: BigInt.from(5000), // Too low
    );
    
    developer.log('Invalid Application Result:', name: 'CreditScoringExample');
    developer.log('- Is Valid: ${invalidResult['isValid']}', name: 'CreditScoringExample');
    developer.log('- Errors: ${invalidResult['errors']}', name: 'CreditScoringExample');
    developer.log('- Warnings: ${invalidResult['warnings']}', name: 'CreditScoringExample');
  }
  
  /// Example: Demonstrate cache management
  void exampleCacheManagement() {
    developer.log('Demonstrating cache management...', name: 'CreditScoringExample');
    
    // Clear all cache
    _creditScoringService.clearCache();
    developer.log('All cache cleared', name: 'CreditScoringExample');
    
    // Clear cache for specific NID
    _creditScoringService.clearCacheForNid(DemoUserData.nid);
    developer.log('Cache cleared for NID: ${DemoUserData.nid}', name: 'CreditScoringExample');
  }
  
  /// Run all examples
  Future<void> runAllExamples() async {
    developer.log('Running CreditScoringService Examples...', name: 'CreditScoringExample');
    
    try {
      // Note: These examples require blockchain connectivity
      // In a real application, ensure blockchain service is initialized first
      
      await exampleCalculateCreditScore();
      await exampleGetRealTimeCreditScore();
      await exampleGetDetailedScoreBreakdown();
      await exampleCalculateMaxLoanAmount();
      await exampleAssessLoanEligibility();
      await exampleGetCreditScoreRecommendations();
      
      // These examples don't require blockchain connectivity
      exampleValidateLoanApplication();
      exampleCacheManagement();
      
      developer.log('All examples completed successfully!', name: 'CreditScoringExample');
      
    } catch (e) {
      developer.log('Error running examples: $e', name: 'CreditScoringExample');
      developer.log('Note: Blockchain connectivity is required for most examples', name: 'CreditScoringExample');
    }
  }
}