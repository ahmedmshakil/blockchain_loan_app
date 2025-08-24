import 'package:flutter/material.dart';

/// Application constants and demo user data
class AppConstants {
  // Application Information
  static const String appName = 'Midnight Bank Ltd.';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Blockchain-Powered Credit Scoring Application';
  static const String appTagline = 'Secure • Transparent • Instant';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);

  // Colors
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  // Banking Information
  static const String bankName = 'Midnight Bank Ltd.';
  static const String bankCode = 'MBL001';
  static const String branchName = 'Main Branch';

  // Loan Configuration
  static const double loanInterestRate = 9.0;
  static const int maxLoanTermMonths = 24;
  static const String loanType = 'Personal Loan';
  static const String loanFeatures =
      'Instant Approval • Up to 24 Months • Verified';

  // Navigation Tabs
  static const List<String> navigationTabs = ['Accounts', 'Loans'];

  // Credit Score Ranges
  static const int minCreditScore = 0;
  static const int maxCreditScore = 1000;
  static const int excellentCreditThreshold = 800;
  static const int goodCreditThreshold = 650;
  static const int fairCreditThreshold = 500;

  // Credit Score Weights (as percentages)
  static const Map<String, int> creditScoreWeights = {
    'accountBalance': 25,
    'transactions': 15,
    'paymentHistory': 30,
    'remainingLoans': 10,
    'creditAge': 10,
    'professionRisk': 10,
  };

  // Error Messages
  static const String networkErrorMessage =
      'Network connection failed. Please check your internet connection.';
  static const String blockchainErrorMessage =
      'Blockchain connection failed. Please try again later.';
  static const String insufficientFundsMessage =
      'Insufficient funds for transaction. Please add Sepolia ETH to your wallet.';
  static const String contractErrorMessage =
      'Smart contract interaction failed. Please try again.';
  static const String genericErrorMessage =
      'An unexpected error occurred. Please try again.';

  // Success Messages
  static const String transactionSuccessMessage =
      'Transaction completed successfully!';
  static const String loanApprovedMessage =
      'Loan application approved and processed on blockchain!';
  static const String dataVerifiedMessage =
      'Data verified on blockchain successfully!';
}

/// Demo user data for testing and demonstration
class DemoUserData {
  // Personal Information
  static const String name = 'Shakil Ahmed';
  static const String nid = '123456789';
  static const String profession = 'Blockchain Developer';
  static const String accountNumber = '1223-42934754363';
  static const String phoneNumber = '+880-1234-567890';
  static const String email = 'shakil@example.com';

  // Financial Information
  static const String accountBalance = '866,507'; // in BDT
  static const String totalTransactions = '1,306,800'; // in BDT
  static const int onTimePayments = 30;
  static const int missedPayments = 7;
  static const String totalRemainingLoan = '74,000'; // in BDT
  static const int creditAgeMonths = 12;

  // Profession and Risk Assessment
  static const String professionCategory = 'Technology';
  static const String professionRisk = 'Low';
  static const String professionRiskDescription = 'Tech industry stability';
  static const int professionRiskScore = 85; // out of 100

  // Account Activity
  static const int totalActiveLoans = 1;
  static const String lastTransactionDate = '2025-08-22';
  static const String accountOpenDate = '2025-03-15';

  // Monthly Income (for loan calculation)
  static const String monthlyIncome = '70,000'; // in BDT
  static const int monthlyIncomeInt = 70000; // in BDT as integer
  static const String employmentStatus = 'Hybrid';
  static const String companyName = 'Surray Software Technology';

  // Expected Credit Score Components
  static const int expectedCreditScore = 900;
  static const String expectedCreditRating = 'A';
  static const String expectedMaxLoanAmount = '200,000'; // in BDT

  /// Get demo user data as a map for easy serialization
  static Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nid': nid,
      'profession': profession,
      'accountNumber': accountNumber,
      'phoneNumber': phoneNumber,
      'email': email,
      'accountBalance': accountBalance,
      'totalTransactions': totalTransactions,
      'onTimePayments': onTimePayments,
      'missedPayments': missedPayments,
      'totalRemainingLoan': totalRemainingLoan,
      'creditAgeMonths': creditAgeMonths,
      'professionCategory': professionCategory,
      'professionRisk': professionRisk,
      'professionRiskDescription': professionRiskDescription,
      'professionRiskScore': professionRiskScore,
      'totalActiveLoans': totalActiveLoans,
      'lastTransactionDate': lastTransactionDate,
      'accountOpenDate': accountOpenDate,
      'monthlyIncome': monthlyIncome,
      'employmentStatus': employmentStatus,
      'companyName': companyName,
      'expectedCreditScore': expectedCreditScore,
      'expectedCreditRating': expectedCreditRating,
      'expectedMaxLoanAmount': expectedMaxLoanAmount,
    };
  }
}

/// Environment configuration
class EnvironmentConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // API Configuration based on environment
  static String get apiBaseUrl {
    switch (environment) {
      case 'production':
        return 'https://api.xyzbankltd.com';
      case 'staging':
        return 'https://staging-api.xyzbankltd.com';
      default:
        return 'https://dev-api.xyzbankltd.com';
    }
  }

  // Blockchain configuration based on environment
  static String get blockchainNetwork {
    switch (environment) {
      case 'production':
        return 'mainnet';
      case 'staging':
        return 'goerli';
      default:
        return 'sepolia';
    }
  }

  // Logging configuration
  static bool get enableDetailedLogging => isDevelopment;
  static bool get enableCrashReporting => isProduction || isStaging;
}
