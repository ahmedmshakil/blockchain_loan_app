import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/blockchain_service.dart';
import '../services/credit_scoring_service.dart';
import '../utils/constants.dart';
import '../widgets/blockchain_status_indicator.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_state_widget.dart';

class LoanApplicationScreen extends StatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loanAmountController = TextEditingController();
  final _monthlyIncomeController = TextEditingController(
    text: DemoUserData.monthlyIncome,
  );

  final BlockchainService _blockchainService = BlockchainService.instance;
  final CreditScoringService _creditScoringService =
      CreditScoringService.instance;

  BorrowerModel? _borrowerData;
  CreditScoreModel? _creditScore;
  Map<String, dynamic>? _loanEligibility;
  bool _isLoading = true;
  bool _isProcessingLoan = false;
  String? _errorMessage;
  String? _transactionHash;
  LoanModel? _processedLoan;

  @override
  void initState() {
    super.initState();
    _loadBorrowerData();
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _monthlyIncomeController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrowerData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load borrower data from blockchain
      final borrower = await _blockchainService.getBorrowerData(
        DemoUserData.nid,
      );

      if (!borrower.exists) {
        // Add demo user to blockchain if not exists
        final demoBorrower = BorrowerModel(
          name: DemoUserData.name,
          nid: DemoUserData.nid,
          profession: DemoUserData.profession,
          accountBalance: BigInt.parse(
            DemoUserData.accountBalance.replaceAll(',', ''),
          ),
          totalTransactions: BigInt.parse(
            DemoUserData.totalTransactions.replaceAll(',', ''),
          ),
          onTimePayments: BigInt.from(DemoUserData.onTimePayments),
          missedPayments: BigInt.from(DemoUserData.missedPayments),
          totalRemainingLoan: BigInt.parse(
            DemoUserData.totalRemainingLoan.replaceAll(',', ''),
          ),
          creditAgeMonths: BigInt.from(DemoUserData.creditAgeMonths),
          professionRiskScore: BigInt.from(DemoUserData.professionRiskScore),
          exists: true,
        );

        await _blockchainService.addBorrowerToBlockchain(demoBorrower);
        _borrowerData = demoBorrower;
      } else {
        _borrowerData = borrower;
      }

      // Calculate credit score with monthly income
      final monthlyIncome = BigInt.parse(
        DemoUserData.monthlyIncome.replaceAll(',', ''),
      );
      _creditScore = await _creditScoringService.calculateCreditScore(
        DemoUserData.nid,
        monthlyIncome: monthlyIncome,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load borrower data: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _calculateLoanEligibility() async {
    if (_loanAmountController.text.isEmpty ||
        _monthlyIncomeController.text.isEmpty) {
      return;
    }

    try {
      final requestedAmount = BigInt.parse(_loanAmountController.text);
      final monthlyIncome = BigInt.parse(_monthlyIncomeController.text);

      final eligibility = await _creditScoringService
          .getLoanEligibilityAssessment(
            DemoUserData.nid,
            monthlyIncome,
            requestedAmount,
          );

      setState(() {
        _loanEligibility = eligibility;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating eligibility: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _submitLoanApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_loanEligibility == null ||
        !(_loanEligibility!['isEligible'] as bool)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check loan eligibility before applying'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isProcessingLoan = true;
        _errorMessage = null;
        _transactionHash = null;
      });

      final requestedAmount = BigInt.parse(_loanAmountController.text);
      final monthlyIncome = BigInt.parse(_monthlyIncomeController.text);

      // Process loan application through blockchain
      final loan = await _blockchainService.processLoanApplication(
        nid: DemoUserData.nid,
        requestedAmount: requestedAmount,
        monthlyIncome: monthlyIncome,
      );

      setState(() {
        _processedLoan = loan;
        _transactionHash = loan.transactionHash;
        _isProcessingLoan = false;
      });

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isProcessingLoan = false;
        _errorMessage = e.toString();
      });

      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: AppConstants.successColor,
          size: 48,
        ),
        title: const Text('Loan Approved!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.loanApprovedMessage),
            const SizedBox(height: 16),
            if (_transactionHash != null) ...[
              const Text(
                'Transaction Hash:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(
                _transactionHash!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _viewTransactionDetails();
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error, color: AppConstants.errorColor, size: 48),
        title: const Text('Loan Application Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadBorrowerData(); // Retry loading data
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _viewTransactionDetails() {
    if (_transactionHash == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (_processedLoan != null) ...[
                        _buildDetailRow('Loan ID', _processedLoan!.id),
                        _buildDetailRow(
                          'Amount',
                          '৳${_processedLoan!.approvedAmount}',
                        ),
                        _buildDetailRow(
                          'Interest Rate',
                          '${_processedLoan!.interestRate}%',
                        ),
                        _buildDetailRow(
                          'Term',
                          '${_processedLoan!.termMonths} months',
                        ),
                        _buildDetailRow(
                          'Monthly Payment',
                          '৳${_processedLoan!.monthlyPayment}',
                        ),
                        _buildDetailRow(
                          'Status',
                          _processedLoan!.formattedStatus,
                        ),
                        _buildDetailRow(
                          'Application Date',
                          _processedLoan!.applicationDate.toString().split(
                            '.',
                          )[0],
                        ),
                        const Divider(height: 24),
                      ],
                      _buildDetailRow('Transaction Hash', _transactionHash!),
                      _buildDetailRow('Network', 'Sepolia Testnet'),
                      _buildDetailRow('Verification', 'Verified'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Loan Application',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
          ? ErrorStateWidget(
              title: 'Error Loading Data',
              message: _errorMessage!,
              onAction: _loadBorrowerData,
            )
          : _buildLoanApplicationForm(),
    );
  }

  Widget _buildLoanApplicationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blockchain Verification Status
            const BlockchainStatusIndicator(),
            const SizedBox(height: 24),

            // Borrower Information Section
            _buildBorrowerInfoSection(),
            const SizedBox(height: 24),

            // Credit Score Section
            _buildCreditScoreSection(),
            const SizedBox(height: 24),

            // Loan Application Form
            _buildLoanFormSection(),
            const SizedBox(height: 24),

            // Loan Eligibility Assessment
            if (_loanEligibility != null) ...[
              _buildEligibilitySection(),
              const SizedBox(height: 24),
            ],

            // Apply Button
            _buildApplyButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowerInfoSection() {
    if (_borrowerData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppConstants.primaryBlue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Borrower Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Personal Details
            _buildInfoRow('Name', _borrowerData!.name),
            _buildInfoRow('NID', _borrowerData!.nid),
            _buildInfoRow('Profession', _borrowerData!.profession),
            const Divider(height: 24),

            // Financial Details
            _buildInfoRow(
              'Account Balance',
              '৳${_borrowerData!.accountBalance}',
            ),
            _buildInfoRow(
              'Total Transactions',
              '৳${_borrowerData!.totalTransactions}',
            ),
            _buildInfoRow(
              'On-time Payments',
              '${_borrowerData!.onTimePayments}',
            ),
            _buildInfoRow(
              'Missed Payments',
              '${_borrowerData!.missedPayments}',
            ),
            _buildInfoRow(
              'Remaining Loans',
              '৳${_borrowerData!.totalRemainingLoan}',
            ),
            _buildInfoRow(
              'Credit Age',
              '${_borrowerData!.creditAgeMonths} months',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditScoreSection() {
    if (_creditScore == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppConstants.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Credit Score Analysis',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Credit Score Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryBlue.withValues(alpha: 0.1),
                    AppConstants.lightBlue.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credit Score',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_creditScore!.score}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryBlue,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rating',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCreditRatingColor(_creditScore!.rating),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _creditScore!.rating,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Score Breakdown
            if (_creditScore!.scoreBreakdown.isNotEmpty) ...[
              Text(
                'Score Breakdown',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._creditScore!.scoreBreakdown.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        '${entry.value} pts',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Max Loan Amount
            if (_creditScore!.maxLoanAmount > BigInt.zero) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Maximum Loan Amount',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '৳${_creditScore!.maxLoanAmount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoanFormSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  color: AppConstants.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Loan Application',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loan Terms Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.lightBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildLoanTermRow(
                    'Interest Rate',
                    '${AppConstants.loanInterestRate}% per annum',
                  ),
                  _buildLoanTermRow(
                    'Maximum Term',
                    '${AppConstants.maxLoanTermMonths} months',
                  ),
                  _buildLoanTermRow('Processing', 'Instant approval'),
                  _buildLoanTermRow('Verification', 'Blockchain secured'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loan Amount Input
            TextFormField(
              controller: _loanAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Requested Loan Amount (BDT)',
                prefixText: '৳ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate),
                  onPressed: _calculateLoanEligibility,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter loan amount';
                }
                final amount = int.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount < 10000) {
                  return 'Minimum loan amount is ৳10,000';
                }
                return null;
              },
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _calculateLoanEligibility();
                }
              },
            ),
            const SizedBox(height: 16),

            // Monthly Income Input
            TextFormField(
              controller: _monthlyIncomeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Monthly Income (BDT)',
                prefixText: '৳ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'Used for loan eligibility calculation',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter monthly income';
                }
                final income = int.tryParse(value);
                if (income == null || income <= 0) {
                  return 'Please enter a valid income';
                }
                if (income < 20000) {
                  return 'Minimum monthly income is ৳20,000';
                }
                return null;
              },
              onChanged: (value) {
                if (value.isNotEmpty && _loanAmountController.text.isNotEmpty) {
                  _calculateLoanEligibility();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilitySection() {
    final isEligible = _loanEligibility!['isEligible'] as bool;
    final reasons = _loanEligibility!['reasons'] as List<String>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEligible ? Icons.check_circle : Icons.cancel,
                  color: isEligible
                      ? AppConstants.successColor
                      : AppConstants.errorColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Eligibility Assessment',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Eligibility Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEligible
                    ? AppConstants.successColor.withValues(alpha: 0.1)
                    : AppConstants.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isEligible ? Icons.thumb_up : Icons.thumb_down,
                    color: isEligible
                        ? AppConstants.successColor
                        : AppConstants.errorColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEligible ? 'Loan Approved' : 'Loan Not Approved',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isEligible
                          ? AppConstants.successColor
                          : AppConstants.errorColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Assessment Details
            _buildAssessmentRow(
              'Credit Score',
              '${_loanEligibility!['creditScore']}',
            ),
            _buildAssessmentRow(
              'Credit Rating',
              _loanEligibility!['creditRating'],
            ),
            _buildAssessmentRow(
              'Requested Amount',
              '৳${_loanEligibility!['requestedAmount']}',
            ),
            _buildAssessmentRow(
              'Maximum Allowed',
              '৳${_loanEligibility!['maxLoanAmount']}',
            ),
            _buildAssessmentRow(
              'Interest Rate',
              '${_loanEligibility!['interestRate']}%',
            ),
            _buildAssessmentRow(
              'Debt-to-Income Ratio',
              '${_loanEligibility!['debtToIncomeRatio']}%',
            ),

            const SizedBox(height: 16),

            // Reasons
            Text(
              'Assessment Details:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    final canApply =
        _loanEligibility != null &&
        (_loanEligibility!['isEligible'] as bool) &&
        !_isProcessingLoan;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canApply ? _submitLoanApplication : null,
        icon: _isProcessingLoan
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send),
        label: Text(
          _isProcessingLoan
              ? 'Processing Application...'
              : 'Submit Loan Application',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: canApply ? AppConstants.primaryBlue : Colors.grey,
        ),
      ),
    );
  }

  // Helper methods

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  Widget _buildLoanTermRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getCreditRatingColor(String rating) {
    switch (rating) {
      case 'A':
        return AppConstants.successColor;
      case 'B':
        return AppConstants.primaryBlue;
      case 'C':
        return AppConstants.warningColor;
      case 'D':
        return AppConstants.errorColor;
      default:
        return Colors.grey;
    }
  }
}
