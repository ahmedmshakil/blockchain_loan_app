import 'package:flutter/material.dart';
import 'package:blockchain_loan_app/widgets/widgets.dart';

class WidgetDemoScreen extends StatefulWidget {
  const WidgetDemoScreen({Key? key}) : super(key: key);

  @override
  State<WidgetDemoScreen> createState() => _WidgetDemoScreenState();
}

class _WidgetDemoScreenState extends State<WidgetDemoScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Banking Header
          BankingHeader(
            userName: 'Shakil Ahmed',
            onProfileTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile tapped')),
              );
            },
          ),
          
          // Navigation Tabs
          NavigationTabs(
            selectedIndex: selectedTab,
            onTabSelected: (index) {
              setState(() {
                selectedTab = index;
              });
            },
          ),
          
          // Content based on selected tab
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (selectedTab == 0) ...[
                    // Accounts Tab - Account Card
                    AccountCard(
                      accountHolderName: 'Shakil Ahmed',
                      nid: '1234567890',
                      profession: 'Blockchain Developer',
                      accountBalance: '600,000',
                      isBlockchainVerified: true,
                      onViewDetails: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('View details tapped')),
                        );
                      },
                    ),
                  ] else if (selectedTab == 3) ...[
                    // Loans Tab - Loan Info Card
                    LoanInfoCard(
                      maxLoanAmount: '100,000',
                      isBlockchainVerified: true,
                      onLoanApply: (amount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Loan application for ৳$amount')),
                        );
                      },
                    ),
                  ] else ...[
                    // Other tabs - Coming soon
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.construction,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'This section is under development',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}