import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/loan_model.dart';
import '../models/credit_score_model.dart';
import '../services/blockchain_service.dart';
import '../services/credit_scoring_service.dart';
import '../utils/constants.dart';
import 'cache_manager.dart';

/// Provider for loan application state management and processing
/// Handles loan applications, eligibility checks, and loan history
/// Requirements: 4.1, 4.2, 4.3, 7.1
class LoanProvider extends ChangeNotifier {
  static LoanProvider? _instance;
  
  // Services
  final BlockchainService _blockchainService = BlockchainService.instance;
  final CreditScoringService _creditScoringService = CreditScoringService.instance;
  final CacheManager _cacheManager = CacheManager.instance;
  
  // Loan application state
  final List<LoanModel> _loanApplications = [];
  final Map<String, Map<String, dynamic>> _eligibilityCache = {};
  
  // Current application state
  LoanModel? _currentApplication;
  Map<String, dynamic>? _currentEligibility;
  
  // Loading states
  bool _isProcessingApplication = false;
  bool _isCheckingEligibility = false;
  bool _isLoadingHistory = false;
  
  // Form state
  BigInt _requestedAmount = BigInt.zero;
  BigInt _monthlyIncome = BigInt.from(DemoUserData.monthlyIncomeInt);
  LoanType _selectedLoanType = LoanType.personal;
  
  // Error state
  String? _lastError;
  DateTime? _lastErrorTime;
  
  // Cache management
  static const Duration _eligibilityCacheExpiration = Duration(minutes: 3);
  
  // Singleton pattern
  static LoanProvider get instance {
    _instance ??= LoanProvider._internal();
    return _instance!;
  }
  
  LoanProvider._internal();
  
  // Getters
  List<LoanModel> get loanApplications => List.unmodifiable(_loanApplications);
  LoanModel? get currentApplication => _currentApplication;
  Map<String, dynamic>? get currentEligibility => _currentEligibility;
  
  bool get isProcessingApplication => _isProcessingApplication;
  bool get isCheckingEligibility => _isCheckingEligibility;
  bool get isLoadingHistory => _isLoadingHistory;
  
  BigInt get requestedAmount => _requestedAmount;
  BigInt get monthlyIncome => _monthlyIncome;
  LoanType get selectedLoanType => _selectedLoanType;
  
  String? get lastError => _lastError;
  DateTime? get lastErrorTime => _lastErrorTime;
  bool get hasError => _lastError != null;
  
  // Computed properties
  bool get hasActiveLoans => _loanApplications.any((loan) => loan.isActive);
  bool get hasPendingApplications => _loanApplications.any((loan) => loan.isPending);
  
  List<LoanModel> get activeLoans => _loanApplications.where((loan) => loan.isActive).toList();
  List<LoanModel> get pendingLoans => _loanApplications.where((loan) => loan.isPending).toList();
  List<LoanModel> get completedLoans => _loanApplications.where((loan) => loan.isCompleted).toList();
  
  BigInt get totalActiveDebt => activeLoans.fold(
    BigInt.zero,
    (sum, loan) => sum + loan.remainingBalance,
  );
  
  /// Set loan application form data
  /// Requirements: 4.1
  void setLoanApplicationData({
    BigInt? requestedAmount,
    BigInt? monthlyIncome,
    LoanType? loanType,
  }) {
    bool hasChanges = false;
    
    if (requestedAmount != null && requestedAmount != _requestedAmount) {
      _requestedAmount = requestedAmount;
      hasChanges = true;
    }
    
    if (monthlyIncome != null && monthlyIncome != _monthlyIncome) {
      _monthlyIncome = monthlyIncome;
      hasChanges = true;
    }
    
    if (loanType != null && loanType != _selectedLoanType) {
      _selectedLoanType = loanType;
      hasChanges = true;
    }
    
    if (hasChanges) {
      // Clear eligibility cache when form data changes
      _currentEligibility = null;
      _clearError();
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Loan form data updated: Amount=$_requestedAmount, Income=$_monthlyIncome, Type=$_selectedLoanType', name: 'LoanProvider');
      }
      
      notifyListeners();
    }
  }
  
  /// Check loan eligibility for current form data
  /// Requirements: 3.3, 4.2
  Future<Map<String, dynamic>?> checkLoanEligibility(String nid, {bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh) {
      final cacheKey = _getEligibilityCacheKey(nid, _requestedAmount, _monthlyIncome);
      final cached = _eligibilityCache[cacheKey];
      if (cached != null) {
        final cacheAge = DateTime.now().difference(cached['timestamp'] as DateTime);
        if (cacheAge < _eligibilityCacheExpiration) {
          return cached['data'] as Map<String, dynamic>;
        }
      }
      
      // Also check persistent cache
      final cachedEligibility = _cacheManager.getCachedEligibilityAssessment(nid, _requestedAmount, _monthlyIncome);
      if (cachedEligibility != null) {
        _currentEligibility = cachedEligibility;
        return cachedEligibility;
      }
    }
    
    _isCheckingEligibility = true;
    _clearError();
    notifyListeners();
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Checking loan eligibility: NID=$nid, Amount=$_requestedAmount', name: 'LoanProvider');
      }
      
      // Validate form data first
      final validation = _validateLoanApplication(nid, _requestedAmount, _monthlyIncome);
      if (!validation['isValid']) {
        _setError('Invalid application data: ${validation['errors'].join(', ')}');
        return null;
      }
      
      // Get eligibility assessment from credit scoring service
      final eligibility = await _creditScoringService.getLoanEligibilityAssessment(
        nid,
        _monthlyIncome,
        _requestedAmount,
      );
      
      if (eligibility.isNotEmpty) {
        _currentEligibility = eligibility;
        
        // Cache the result in memory
        final cacheKey = _getEligibilityCacheKey(nid, _requestedAmount, _monthlyIncome);
        _eligibilityCache[cacheKey] = {
          'data': eligibility,
          'timestamp': DateTime.now(),
        };
        
        // Cache in persistent storage
        await _cacheManager.cacheEligibilityAssessment(nid, _requestedAmount, _monthlyIncome, eligibility);
        
        if (EnvironmentConfig.enableDetailedLogging) {
          developer.log('Eligibility checked: ${eligibility['isEligible']} for NID=$nid', name: 'LoanProvider');
        }
      }
      
      return eligibility;
    } catch (e) {
      _setError('Failed to check eligibility: $e');
      developer.log('Failed to check loan eligibility: $e', name: 'LoanProvider');
      return null;
    } finally {
      _isCheckingEligibility = false;
      notifyListeners();
    }
  }
  
  /// Submit loan application
  /// Requirements: 4.1, 4.2, 4.3, 7.1
  Future<LoanModel?> submitLoanApplication(String nid) async {
    _isProcessingApplication = true;
    _clearError();
    notifyListeners();
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Submitting loan application: NID=$nid, Amount=$_requestedAmount', name: 'LoanProvider');
      }
      
      // Validate application data
      final validation = _validateLoanApplication(nid, _requestedAmount, _monthlyIncome);
      if (!validation['isValid']) {
        throw Exception('Invalid application: ${validation['errors'].join(', ')}');
      }
      
      // Check eligibility one more time before submission
      final eligibility = await checkLoanEligibility(nid, forceRefresh: true);
      if (eligibility == null || !eligibility['isEligible']) {
        throw Exception('Loan application not eligible for approval');
      }
      
      // Process loan through blockchain service
      final loanModel = await _blockchainService.processLoanApplication(
        nid: nid,
        requestedAmount: _requestedAmount,
        monthlyIncome: _monthlyIncome,
        loanType: _selectedLoanType,
      );
      
      // Add to local applications list
      _loanApplications.add(loanModel);
      _currentApplication = loanModel;
      
      // Cache the loan data
      await _cacheManager.cacheLoanData(loanModel.id, loanModel);
      
      // Clear form data after successful submission
      _resetFormData();
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Loan application submitted successfully: ${loanModel.id}', name: 'LoanProvider');
      }
      
      return loanModel;
    } catch (e) {
      _setError('Failed to submit application: $e');
      developer.log('Failed to submit loan application: $e', name: 'LoanProvider');
      return null;
    } finally {
      _isProcessingApplication = false;
      notifyListeners();
    }
  }
  
  /// Load loan history for a borrower
  /// Requirements: 5.1, 5.2
  Future<void> loadLoanHistory(String nid) async {
    _isLoadingHistory = true;
    _clearError();
    notifyListeners();
    
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Loading loan history for NID: $nid', name: 'LoanProvider');
      }
      
      // Note: In a real implementation, this would fetch from blockchain or database
      // For now, we'll keep the existing applications as the history
      // This is a placeholder for future blockchain query implementation
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Loan history loaded: ${_loanApplications.length} applications', name: 'LoanProvider');
      }
    } catch (e) {
      _setError('Failed to load loan history: $e');
      developer.log('Failed to load loan history: $e', name: 'LoanProvider');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }
  
  /// Get loan recommendations based on credit score
  /// Requirements: 3.3, 4.2
  Future<List<Map<String, dynamic>>> getLoanRecommendations(String nid, CreditScoreModel creditScore) async {
    try {
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Getting loan recommendations for NID: $nid', name: 'LoanProvider');
      }
      
      final recommendations = <Map<String, dynamic>>[];
      
      // Base recommendations on credit score
      if (creditScore.score >= 800) {
        // Excellent credit - premium options
        recommendations.addAll([
          {
            'type': LoanType.personal,
            'title': 'Premium Personal Loan',
            'amount': creditScore.maxLoanAmount,
            'interestRate': 10.0,
            'termMonths': 24,
            'description': 'Best rates for excellent credit',
          },
          {
            'type': LoanType.business,
            'title': 'Business Expansion Loan',
            'amount': creditScore.maxLoanAmount * BigInt.from(2),
            'interestRate': 11.0,
            'termMonths': 36,
            'description': 'Grow your business with competitive rates',
          },
        ]);
      } else if (creditScore.score >= 650) {
        // Good credit - standard options
        recommendations.addAll([
          {
            'type': LoanType.personal,
            'title': 'Standard Personal Loan',
            'amount': creditScore.maxLoanAmount,
            'interestRate': 12.5,
            'termMonths': 18,
            'description': 'Competitive rates for good credit',
          },
          {
            'type': LoanType.emergency,
            'title': 'Emergency Fund Loan',
            'amount': creditScore.maxLoanAmount ~/ BigInt.from(2),
            'interestRate': 13.0,
            'termMonths': 12,
            'description': 'Quick access for emergencies',
          },
        ]);
      } else if (creditScore.score >= 500) {
        // Fair credit - limited options
        recommendations.add({
          'type': LoanType.personal,
          'title': 'Fair Credit Personal Loan',
          'amount': creditScore.maxLoanAmount,
          'interestRate': 15.0,
          'termMonths': 12,
          'description': 'Build your credit with responsible borrowing',
        });
      } else {
        // Poor credit - credit building options
        recommendations.add({
          'type': LoanType.personal,
          'title': 'Credit Builder Loan',
          'amount': BigInt.from(25000), // Small amount for credit building
          'interestRate': 18.0,
          'termMonths': 6,
          'description': 'Small loan to help build your credit history',
        });
      }
      
      if (EnvironmentConfig.enableDetailedLogging) {
        developer.log('Generated ${recommendations.length} loan recommendations', name: 'LoanProvider');
      }
      
      return recommendations;
    } catch (e) {
      developer.log('Failed to get loan recommendations: $e', name: 'LoanProvider');
      return [];
    }
  }
  
  /// Calculate loan payment schedule
  /// Requirements: 4.2
  List<Map<String, dynamic>> calculatePaymentSchedule(LoanModel loan) {
    try {
      final schedule = <Map<String, dynamic>>[];
      final monthlyPayment = loan.monthlyPayment;
      final monthlyRate = loan.interestRate / 100 / 12;
      var remainingBalance = loan.approvedAmount;
      
      for (int month = 1; month <= loan.termMonths; month++) {
        final interestPayment = BigInt.from((remainingBalance.toDouble() * monthlyRate).round());
        final principalPayment = monthlyPayment - interestPayment;
        remainingBalance = remainingBalance - principalPayment;
        
        // Ensure remaining balance doesn't go negative
        if (remainingBalance < BigInt.zero) {
          remainingBalance = BigInt.zero;
        }
        
        schedule.add({
          'month': month,
          'monthlyPayment': monthlyPayment,
          'principalPayment': principalPayment,
          'interestPayment': interestPayment,
          'remainingBalance': remainingBalance,
          'dueDate': loan.disbursementDate?.add(Duration(days: 30 * month)),
        });
      }
      
      return schedule;
    } catch (e) {
      developer.log('Failed to calculate payment schedule: $e', name: 'LoanProvider');
      return [];
    }
  }
  
  /// Reset form data to defaults
  void resetFormData() {
    _resetFormData();
    notifyListeners();
  }
  
  /// Clear all loan data
  void clearAllData() {
    _loanApplications.clear();
    _eligibilityCache.clear();
    _currentApplication = null;
    _currentEligibility = null;
    _resetFormData();
    _clearError();
    
    if (EnvironmentConfig.enableDetailedLogging) {
      developer.log('All loan data cleared', name: 'LoanProvider');
    }
    
    notifyListeners();
  }
  
  /// Clear error state
  void clearError() {
    _clearError();
    notifyListeners();
  }
  
  // Private helper methods
  
  void _resetFormData() {
    _requestedAmount = BigInt.zero;
    _monthlyIncome = BigInt.from(DemoUserData.monthlyIncomeInt);
    _selectedLoanType = LoanType.personal;
    _currentEligibility = null;
  }
  
  void _setError(String error) {
    _lastError = error;
    _lastErrorTime = DateTime.now();
  }
  
  void _clearError() {
    _lastError = null;
    _lastErrorTime = null;
  }
  
  String _getEligibilityCacheKey(String nid, BigInt amount, BigInt income) {
    return '${nid}_${amount}_$income';
  }
  
  Map<String, dynamic> _validateLoanApplication(String nid, BigInt requestedAmount, BigInt monthlyIncome) {
    return _creditScoringService.validateLoanApplication(
      nid: nid,
      requestedAmount: requestedAmount,
      monthlyIncome: monthlyIncome,
    );
  }
  
  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }
}