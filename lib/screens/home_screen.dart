import 'package:flutter/material.dart';
import '../widgets/banking_header.dart';
import '../widgets/navigation_tabs.dart';
import '../utils/constants.dart';
import '../utils/navigation_utils.dart';
import '../models/borrower_model.dart';
import 'account_details_screen.dart';
import 'loan_application_screen.dart';
import 'sepolia_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
      // Restart animation for smooth transition
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _onProfileTap() {
    _showProfileDialog();
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileRow('Name', DemoUserData.name),
              _buildProfileRow('Account', DemoUserData.accountNumber),
              _buildProfileRow('NID', DemoUserData.nid),
              _buildProfileRow('Profession', DemoUserData.profession),
              _buildProfileRow('Phone', DemoUserData.phoneNumber),
              _buildProfileRow('Email', DemoUserData.email),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppConstants.bankName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () {
              NavigationUtils.navigateWithSlide(
                context,
                const SepoliaTestScreen(),
              );
            },
            tooltip: 'Blockchain Testing',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              NavigationUtils.showWarningSnackBar(
                context,
                'Notifications feature coming soon',
                duration: const Duration(seconds: 2),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _onProfileTap,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banking Header with branding and user profile
          BankingHeader(
            userName: DemoUserData.name,
            onProfileTap: _onProfileTap,
          ),

          // Navigation Tabs
          NavigationTabs(
            selectedIndex: _selectedTabIndex,
            onTabSelected: _onTabSelected,
          ),

          // Main Content Area with animation
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedTabIndex,
      onTap: _onTabSelected,
      selectedItemColor: AppConstants.primaryBlue,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Accounts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monetization_on),
          label: 'Loans',
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAccountsTab();
      case 1:
        return _buildLoansTab();
      default:
        return _buildAccountsTab();
    }
  }

  Widget _buildAccountsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),

          // Account Summary Card
          Card(
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.successColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: AppConstants.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Govt. Verified',
                              style: TextStyle(
                                color: AppConstants.successColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Account Details
                  _buildAccountDetailRow('Account Holder', DemoUserData.name),
                  _buildAccountDetailRow(
                    'Account Number',
                    DemoUserData.accountNumber,
                  ),
                  _buildAccountDetailRow('NID', DemoUserData.nid),
                  _buildAccountDetailRow('Profession', DemoUserData.profession),
                  const Divider(height: 24),

                  // Balance Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Balance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '৳${DemoUserData.accountBalance}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.successColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _navigateToAccountDetails();
                          },
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('View Details'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showTransactionHistory();
                          },
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('Transactions'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loan Services',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),

          // Loan Information Card
          Card(
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
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Loan',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              AppConstants.loanFeatures,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Loan Terms
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.lightBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildLoanDetailRow(
                          'Interest Rate',
                          '${AppConstants.loanInterestRate}% per annum',
                        ),
                        _buildLoanDetailRow(
                          'Maximum Term',
                          '${AppConstants.maxLoanTermMonths} months',
                        ),
                        _buildLoanDetailRow(
                          'Processing Time',
                          'Instant approval',
                        ),
                        _buildLoanDetailRow('Verification', 'Govt. Verified'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _navigateToLoanApplication();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text(
                        'Apply For Loan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Current Loans Section
          Text(
            'Current Loans',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Loans',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${DemoUserData.totalActiveLoans}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryBlue,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Remaining Amount',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '৳${DemoUserData.totalRemainingLoan}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.warningColor,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildLoanDetailRow(String label, String value) {
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

  // Navigation methods
  void _navigateToAccountDetails() {
    // Create demo borrower data for account details
    // Remove commas from string values before parsing to BigInt
    final demoData = BorrowerModel(
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

    NavigationUtils.navigateWithSlide(
      context,
      AccountDetailsScreen(borrowerData: demoData),
    );
  }

  void _navigateToLoanApplication() {
    NavigationUtils.navigateWithSlide(context, const LoanApplicationScreen());
  }

  void _showTransactionHistory() {
    NavigationUtils.showEnhancedBottomSheet(
      context,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction History',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  final isCredit = index % 2 == 0;

                  // Create meaningful transaction descriptions
                  final List<String> creditTransactions = [
                    'Salary Deposit',
                    'Freelance Payment',
                    'Investment Return',
                    'Bonus Payment',
                    'Refund Received',
                  ];

                  final List<String> debitTransactions = [
                    'Online Purchase',
                    'Utility Payment',
                    'ATM Withdrawal',
                    'Restaurant Bill',
                    'Grocery Shopping',
                  ];

                  final transactionTitle = isCredit
                      ? creditTransactions[index % creditTransactions.length]
                      : debitTransactions[index % debitTransactions.length];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCredit
                            ? AppConstants.successColor.withValues(alpha: 0.1)
                            : AppConstants.errorColor.withValues(alpha: 0.1),
                        child: Icon(
                          isCredit ? Icons.add : Icons.remove,
                          color: isCredit
                              ? AppConstants.successColor
                              : AppConstants.errorColor,
                        ),
                      ),
                      title: Text(transactionTitle),
                      subtitle: Text('2025-08-${22 - index}'),
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
      ),
    );
  }
}
