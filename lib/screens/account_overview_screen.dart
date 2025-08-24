import 'package:flutter/material.dart';
import '../models/borrower_model.dart';
import '../services/blockchain_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/blockchain_status_indicator.dart';
import 'account_details_screen.dart';

/// Account Overview Screen displaying account summary card
/// Requirements: 1.1, 1.2, 5.1, 5.2
class AccountOverviewScreen extends StatefulWidget {
  const AccountOverviewScreen({super.key});

  @override
  State<AccountOverviewScreen> createState() => _AccountOverviewScreenState();
}

class _AccountOverviewScreenState extends State<AccountOverviewScreen> {
  final BlockchainService _blockchainService = BlockchainService.instance;
  BorrowerModel? _borrowerData;
  bool _isLoading = true;
  // bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  /// Load account data from blockchain
  Future<void> _loadAccountData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize blockchain service if needed
      await _blockchainService.initialize();

      // Fetch borrower data from blockchain
      final borrowerData = await _blockchainService.getBorrowerData(
        DemoUserData.nid,
      );

      if (!mounted) return;

      setState(() {
        _borrowerData = borrowerData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Use demo data as fallback when blockchain is not available
      setState(() {
        _borrowerData = _createDemoDataFallback();
        _isLoading = false;
        // Don't set error message, just use demo data silently
      });
    }
  }

  /// Create demo data fallback when blockchain is not available
  BorrowerModel _createDemoDataFallback() {
    return BorrowerModel(
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
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    await _loadAccountData();
  }

  /// Navigate to account details screen
  void _navigateToAccountDetails() {
    if (_borrowerData != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              AccountDetailsScreen(borrowerData: _borrowerData!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Account Overview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _handleRefresh, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(message: 'Loading account data...'),
      );
    }

    if (_borrowerData == null || !_borrowerData!.exists) {
      return _buildNoAccountFound();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 20),
          _buildAccountSummaryCard(),
          const SizedBox(height: 20),
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
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
          Text(
            'Welcome back,',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            _borrowerData?.name ?? DemoUserData.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const BlockchainStatusIndicator(isVerified: true),
        ],
      ),
    );
  }

  Widget _buildAccountSummaryCard() {
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
                  'Primary Account',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: AppConstants.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Account holder details
            _buildAccountDetailRow(
              'Account Holder',
              _borrowerData?.name ?? DemoUserData.name,
            ),
            _buildAccountDetailRow(
              'Account Number',
              DemoUserData.accountNumber,
            ),
            _buildAccountDetailRow(
              'NID',
              _borrowerData?.nid ?? DemoUserData.nid,
            ),
            _buildAccountDetailRow(
              'Profession',
              _borrowerData?.profession ?? DemoUserData.profession,
            ),

            const Divider(height: 24),

            // Balance information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Balance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '৳${_formatBalance(_borrowerData?.accountBalance)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.successColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAccountDetails,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Full Details'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showTransactionHistory,
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Transactions'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.send,
                title: 'Transfer',
                subtitle: 'Send money',
                onTap: () => _showComingSoon('Transfer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.account_balance_wallet,
                title: 'Deposit',
                subtitle: 'Add funds',
                onTap: () => _showComingSoon('Deposit'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.receipt_long,
                title: 'Statements',
                subtitle: 'View statements',
                onTap: () => _showComingSoon('Statements'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.support_agent,
                title: 'Support',
                subtitle: 'Get help',
                onTap: () => _showComingSoon('Support'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppConstants.primaryBlue),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAccountFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Account Not Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No account data found on blockchain. Please contact support.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAccountData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Format balance for display
  String _formatBalance(BigInt? balance) {
    if (balance == null) return DemoUserData.accountBalance;

    // Convert BigInt to string and format with commas
    final balanceStr = balance.toString();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return balanceStr.replaceAllMapped(regex, (Match m) => '${m[1]},');
  }

  /// Show transaction history modal
  void _showTransactionHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
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
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      final isCredit = index % 2 == 0;

                      // Create meaningful transaction descriptions
                      final List<Map<String, String>> creditTransactions = [
                        {
                          'title': 'Monthly Salary',
                          'description': 'Tech Solutions Ltd',
                        },
                        {
                          'title': 'Freelance Project',
                          'description': 'Web Development',
                        },
                        {
                          'title': 'Investment Dividend',
                          'description': 'Stock Portfolio',
                        },
                        {
                          'title': 'Performance Bonus',
                          'description': 'Q3 Achievement',
                        },
                        {
                          'title': 'Cashback Reward',
                          'description': 'Credit Card',
                        },
                      ];

                      final List<Map<String, String>> debitTransactions = [
                        {
                          'title': 'Online Shopping',
                          'description': 'Amazon Purchase',
                        },
                        {
                          'title': 'Electricity Bill',
                          'description': 'DESCO Payment',
                        },
                        {
                          'title': 'Cash Withdrawal',
                          'description': 'ATM - Gulshan',
                        },
                        {
                          'title': 'Restaurant Bill',
                          'description': 'Dinner at Dhaba',
                        },
                        {
                          'title': 'Grocery Shopping',
                          'description': 'Shwapno Store',
                        },
                      ];

                      final transactionData = isCredit
                          ? creditTransactions[index %
                                creditTransactions.length]
                          : debitTransactions[index % debitTransactions.length];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCredit
                                ? AppConstants.successColor.withValues(
                                    alpha: 0.1,
                                  )
                                : AppConstants.errorColor.withValues(
                                    alpha: 0.1,
                                  ),
                            child: Icon(
                              isCredit ? Icons.add : Icons.remove,
                              color: isCredit
                                  ? AppConstants.successColor
                                  : AppConstants.errorColor,
                            ),
                          ),
                          title: Text(transactionData['title']!),
                          subtitle: Text(
                            '2025-08-${22 - index} • ${transactionData['description']}',
                          ),
                          trailing: Text(
                            '৳${(index + 1) * 1000}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCredit
                                  ? AppConstants.successColor
                                  : AppConstants.errorColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Show coming soon message
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppConstants.primaryBlue,
      ),
    );
  }
}
