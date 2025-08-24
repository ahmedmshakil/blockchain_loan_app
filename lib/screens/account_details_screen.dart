import 'package:flutter/material.dart';
import '../models/borrower_model.dart';
import '../models/credit_score_model.dart';
import '../services/blockchain_service.dart';
import '../services/credit_scoring_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/blockchain_status_indicator.dart';

/// Account Details Screen with comprehensive account information
/// Requirements: 1.2, 1.3, 5.2, 5.3
class AccountDetailsScreen extends StatefulWidget {
  final BorrowerModel borrowerData;

  const AccountDetailsScreen({super.key, required this.borrowerData});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen>
    with TickerProviderStateMixin {
  final BlockchainService _blockchainService = BlockchainService.instance;
  // final CreditScoringService _creditScoringService = CreditScoringService.instance;

  late TabController _tabController;
  CreditScoreModel? _creditScore;
  bool _isLoadingCreditScore = true;
  String? _creditScoreError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCreditScoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load credit score data from blockchain
  Future<void> _loadCreditScoreData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCreditScore = true;
      _creditScoreError = null;
    });

    try {
      // Get comprehensive credit score from blockchain
      final creditScore = await _blockchainService.getCompleteCreditScore(
        widget.borrowerData.nid,
        monthlyIncome: BigInt.parse(
          DemoUserData.monthlyIncome.replaceAll(',', ''),
        ),
      );

      if (!mounted) return;

      setState(() {
        _creditScore = creditScore;
        _isLoadingCreditScore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _creditScoreError = _getErrorMessage(e.toString());
        _isLoadingCreditScore = false;
      });
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(String error) {
    if (error.contains('network') || error.contains('connection')) {
      return AppConstants.networkErrorMessage;
    } else if (error.contains('contract') || error.contains('blockchain')) {
      return AppConstants.blockchainErrorMessage;
    }
    return AppConstants.genericErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Account Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCreditScoreData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.account_circle)),
            Tab(text: 'Credit Score', icon: Icon(Icons.assessment)),
            Tab(text: 'Activity', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCreditScoreTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccountHeaderCard(),
          const SizedBox(height: 16),
          _buildPersonalInformationCard(),
          const SizedBox(height: 16),
          _buildFinancialSummaryCard(),
          const SizedBox(height: 16),
          _buildAccountStatusCard(),
        ],
      ),
    );
  }

  Widget _buildCreditScoreTab() {
    if (_isLoadingCreditScore) {
      return const Center(
        child: LoadingIndicator(
          message: 'Loading credit score from blockchain...',
        ),
      );
    }

    if (_creditScoreError != null) {
      return ErrorStateWidget(
        title: 'Error Loading Credit Score',
        message: _creditScoreError!,
        onAction: _loadCreditScoreData,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCreditScoreCard(),
          const SizedBox(height: 16),
          _buildCreditScoreBreakdownCard(),
          const SizedBox(height: 16),
          _buildLoanEligibilityCard(),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentHistoryCard(),
          const SizedBox(height: 16),
          _buildTransactionSummaryCard(),
          const SizedBox(height: 16),
          _buildLoanHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildAccountHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppConstants.primaryBlue, AppConstants.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.borrowerData.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Account: ${DemoUserData.accountNumber}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    widget.borrowerData.name.isNotEmpty
                        ? widget.borrowerData.name
                              .split(' ')
                              .where((e) => e.isNotEmpty)
                              .map((e) => e[0])
                              .take(2)
                              .join()
                        : 'NA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    Text(
                      '৳${_formatBalance(widget.borrowerData.accountBalance)}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const BlockchainStatusIndicator(isVerified: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInformationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Full Name', widget.borrowerData.name),
            _buildDetailRow('National ID', widget.borrowerData.nid),
            _buildDetailRow('Profession', widget.borrowerData.profession),
            _buildDetailRow('Phone Number', DemoUserData.phoneNumber),
            _buildDetailRow('Email Address', DemoUserData.email),
            _buildDetailRow('Employment Status', DemoUserData.employmentStatus),
            _buildDetailRow('Company', DemoUserData.companyName),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFinancialRow(
              'Account Balance',
              '৳${_formatBalance(widget.borrowerData.accountBalance)}',
              AppConstants.successColor,
            ),
            _buildFinancialRow(
              'Total Transactions',
              '৳${_formatBalance(widget.borrowerData.totalTransactions)}',
              AppConstants.primaryBlue,
            ),
            _buildFinancialRow(
              'Monthly Income',
              '৳${DemoUserData.monthlyIncome}',
              AppConstants.successColor,
            ),
            _buildFinancialRow(
              'Remaining Loans',
              '৳${_formatBalance(widget.borrowerData.totalRemainingLoan)}',
              AppConstants.warningColor,
            ),
            _buildFinancialRow(
              'Active Loans',
              '${DemoUserData.totalActiveLoans}',
              AppConstants.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Account Status',
              'Active',
              AppConstants.successColor,
            ),
            _buildStatusRow(
              'KYC Status',
              'Verified',
              AppConstants.successColor,
            ),
            _buildStatusRow(
              'Decentralized Banking Status',
              'Active',
              AppConstants.successColor,
            ),
            _buildDetailRow('Account Opened', DemoUserData.accountOpenDate),
            _buildDetailRow(
              'Last Transaction',
              DemoUserData.lastTransactionDate,
            ),
            _buildDetailRow(
              'Credit Age',
              '${widget.borrowerData.creditAgeMonths} months',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditScoreCard() {
    final score =
        _creditScore?.score ??
        int.parse(DemoUserData.expectedCreditScore.toString());
    final rating = _creditScore?.rating ?? DemoUserData.expectedCreditRating;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Credit Score',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const BlockchainStatusIndicator(isVerified: true),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _getCreditScoreColors(score),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            score.toString(),
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Grade $rating',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getCreditScoreDescription(score),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditScoreBreakdownCard() {
    final breakdown =
        _creditScore?.scoreBreakdown ??
        {
          'Account Balance': 125,
          'Transactions': 75,
          'Payment History': 225,
          'Remaining Loans': 90,
          'Credit Age': 50,
          'Profession Risk': 85,
        };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Credit Score Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...breakdown.entries.map(
              (entry) => _buildScoreBreakdownRow(
                entry.key,
                entry.value,
                AppConstants.creditScoreWeights[_getWeightKey(entry.key)] ?? 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanEligibilityCard() {
    final maxLoanAmount =
        _creditScore?.maxLoanAmount ??
        BigInt.parse(DemoUserData.expectedMaxLoanAmount.replaceAll(',', ''));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Eligibility',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Maximum Loan Amount',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '৳${_formatBalance(maxLoanAmount)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Interest Rate',
                    '${AppConstants.loanInterestRate}% per annum',
                  ),
                  _buildDetailRow(
                    'Maximum Term',
                    '${AppConstants.maxLoanTermMonths} months',
                  ),
                  _buildDetailRow('Processing Time', 'Instant approval'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment History',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPaymentRow(
              'On-time Payments',
              widget.borrowerData.onTimePayments.toString(),
              AppConstants.successColor,
            ),
            _buildPaymentRow(
              'Missed Payments',
              widget.borrowerData.missedPayments.toString(),
              AppConstants.errorColor,
            ),
            _buildPaymentRow(
              'Payment Success Rate',
              '${_calculatePaymentSuccessRate()}%',
              AppConstants.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFinancialRow(
              'Total Transaction Volume',
              '৳${_formatBalance(widget.borrowerData.totalTransactions)}',
              AppConstants.primaryBlue,
            ),
            _buildDetailRow('Average Monthly Transactions', '৳125,433'),
            _buildDetailRow(
              'Last Transaction',
              DemoUserData.lastTransactionDate,
            ),
            _buildDetailRow('Transaction Frequency', 'High'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanHistoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan History',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFinancialRow(
              'Active Loans',
              DemoUserData.totalActiveLoans.toString(),
              AppConstants.primaryBlue,
            ),
            _buildFinancialRow(
              'Total Remaining Amount',
              '৳${_formatBalance(widget.borrowerData.totalRemainingLoan)}',
              AppConstants.warningColor,
            ),
            _buildDetailRow('Loan History', 'Good standing'),
            _buildDetailRow('Default History', 'None'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: valueColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdownRow(String category, int score, int weight) {
    final maxScore = (1000 * weight / 100).round();
    final percentage = (score / maxScore * 100).clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$score/$maxScore ($weight%)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getScoreColor(percentage.toDouble()),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper methods
  String _formatBalance(BigInt balance) {
    final balanceStr = balance.toString();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return balanceStr.replaceAllMapped(regex, (Match m) => '${m[1]},');
  }

  List<Color> _getCreditScoreColors(int score) {
    if (score >= AppConstants.excellentCreditThreshold) {
      return [AppConstants.successColor, const Color(0xFF059669)];
    } else if (score >= AppConstants.goodCreditThreshold) {
      return [AppConstants.lightBlue, AppConstants.primaryBlue];
    } else if (score >= AppConstants.fairCreditThreshold) {
      return [AppConstants.warningColor, const Color(0xFFD97706)];
    } else {
      return [AppConstants.errorColor, const Color(0xFFDC2626)];
    }
  }

  String _getCreditScoreDescription(int score) {
    if (score >= AppConstants.excellentCreditThreshold) {
      return 'Excellent Credit Score';
    } else if (score >= AppConstants.goodCreditThreshold) {
      return 'Good Credit Score';
    } else if (score >= AppConstants.fairCreditThreshold) {
      return 'Fair Credit Score';
    } else {
      return 'Poor Credit Score';
    }
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) {
      return AppConstants.successColor;
    } else if (percentage >= 60) {
      return AppConstants.primaryBlue;
    } else if (percentage >= 40) {
      return AppConstants.warningColor;
    } else {
      return AppConstants.errorColor;
    }
  }

  String _getWeightKey(String category) {
    switch (category) {
      case 'Account Balance':
        return 'accountBalance';
      case 'Transactions':
        return 'transactions';
      case 'Payment History':
        return 'paymentHistory';
      case 'Remaining Loans':
        return 'remainingLoans';
      case 'Credit Age':
        return 'creditAge';
      case 'Profession Risk':
        return 'professionRisk';
      default:
        return 'accountBalance';
    }
  }

  int _calculatePaymentSuccessRate() {
    final totalPayments =
        widget.borrowerData.onTimePayments + widget.borrowerData.missedPayments;
    if (totalPayments == BigInt.zero) return 0;

    return ((widget.borrowerData.onTimePayments * BigInt.from(100)) ~/
            totalPayments)
        .toInt();
  }
}
