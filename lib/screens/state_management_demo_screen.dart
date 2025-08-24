import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider_registry.dart';
import '../providers/cache_manager.dart';
import '../utils/constants.dart';

/// Demo screen showing state management integration
/// Demonstrates how to use providers for data management and real-time updates
/// Requirements: 2.3, 5.4, 7.4
class StateManagementDemoScreen extends StatefulWidget {
  const StateManagementDemoScreen({super.key});

  @override
  State<StateManagementDemoScreen> createState() => _StateManagementDemoScreenState();
}

class _StateManagementDemoScreenState extends State<StateManagementDemoScreen> 
    with ProviderAware {
  
  @override
  void initState() {
    super.initState();
    // Initialize data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }
  
  Future<void> _loadInitialData() async {
    // Load borrower data and credit score
    await appState.loadBorrowerData(DemoUserData.nid);
    await appState.loadCreditScore(DemoUserData.nid);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('State Management Demo'),
        backgroundColor: AppConstants.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App State Section
            _buildAppStateSection(),
            const SizedBox(height: 24),
            
            // Blockchain State Section
            _buildBlockchainStateSection(),
            const SizedBox(height: 24),
            
            // Loan State Section
            _buildLoanStateSection(),
            const SizedBox(height: 24),
            
            // Cache Statistics Section
            _buildCacheStatisticsSection(),
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppStateSection() {
    return AppStateConsumer(
      builder: (context, appState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Application State',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Borrower Data
                _buildDataRow('Borrower Loaded', appState.currentBorrower != null),
                if (appState.currentBorrower != null) ...[
                  _buildDataRow('Name', appState.currentBorrower!.name),
                  _buildDataRow('NID', appState.currentBorrower!.nid),
                  _buildDataRow('Balance', '৳${appState.currentBorrower!.accountBalance}'),
                ],
                
                const Divider(),
                
                // Credit Score Data
                _buildDataRow('Credit Score Loaded', appState.currentCreditScore != null),
                if (appState.currentCreditScore != null) ...[
                  _buildDataRow('Score', '${appState.currentCreditScore!.score}'),
                  _buildDataRow('Rating', appState.currentCreditScore!.rating),
                  _buildDataRow('Verified', appState.currentCreditScore!.isBlockchainVerified),
                ],
                
                const Divider(),
                
                // Loading States
                _buildDataRow('Loading Borrower', appState.isLoadingBorrower),
                _buildDataRow('Loading Credit Score', appState.isLoadingCreditScore),
                
                // Error State
                if (appState.hasError) ...[
                  const Divider(),
                  Text(
                    'Error: ${appState.lastError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBlockchainStateSection() {
    return BlockchainConsumer(
      builder: (context, blockchain, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Blockchain State',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                _buildDataRow('Connected', blockchain.isConnected),
                _buildDataRow('Initialized', blockchain.isInitialized),
                _buildDataRow('Connecting', blockchain.isConnecting),
                
                if (blockchain.networkName != null)
                  _buildDataRow('Network', blockchain.networkName!),
                
                if (blockchain.chainId != null)
                  _buildDataRow('Chain ID', blockchain.chainId.toString()),
                
                if (blockchain.walletBalance != null)
                  _buildDataRow('Wallet Balance', '${blockchain.walletBalance} ETH'),
                
                _buildDataRow('Pending Transactions', blockchain.pendingTransactions.length),
                _buildDataRow('Confirmed Transactions', blockchain.confirmedTransactions.length),
                
                if (blockchain.hasConnectionError) ...[
                  const Divider(),
                  Text(
                    'Connection Error: ${blockchain.connectionError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildLoanStateSection() {
    return LoanConsumer(
      builder: (context, loan, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loan State',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                _buildDataRow('Total Applications', loan.loanApplications.length),
                _buildDataRow('Active Loans', loan.activeLoans.length),
                _buildDataRow('Pending Applications', loan.pendingLoans.length),
                _buildDataRow('Completed Loans', loan.completedLoans.length),
                
                if (loan.totalActiveDebt > BigInt.zero)
                  _buildDataRow('Total Active Debt', '৳${loan.totalActiveDebt}'),
                
                _buildDataRow('Requested Amount', '৳${loan.requestedAmount}'),
                _buildDataRow('Monthly Income', '৳${loan.monthlyIncome}'),
                _buildDataRow('Loan Type', loan.selectedLoanType.name),
                
                const Divider(),
                
                _buildDataRow('Processing Application', loan.isProcessingApplication),
                _buildDataRow('Checking Eligibility', loan.isCheckingEligibility),
                
                if (loan.currentEligibility != null) ...[
                  const Divider(),
                  _buildDataRow('Eligible', loan.currentEligibility!['isEligible']),
                  if (loan.currentEligibility!['maxLoanAmount'] != null)
                    _buildDataRow('Max Loan Amount', '৳${loan.currentEligibility!['maxLoanAmount']}'),
                ],
                
                if (loan.hasError) ...[
                  const Divider(),
                  Text(
                    'Error: ${loan.lastError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCacheStatisticsSection() {
    return Consumer<CacheManager>(
      builder: (context, cache, child) {
        final stats = cache.getCacheStatistics();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cache Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                _buildDataRow('Memory Entries', stats['memoryEntries']),
                _buildDataRow('Cache Hits', stats['cacheHits']),
                _buildDataRow('Cache Misses', stats['cacheMisses']),
                _buildDataRow('Cache Evictions', stats['cacheEvictions']),
                _buildDataRow('Hit Ratio', '${(stats['hitRatio'] * 100).toStringAsFixed(1)}%'),
                _buildDataRow('Expired Entries', stats['expiredEntries']),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await appState.refreshAllData();
                },
                child: const Text('Refresh All Data'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await blockchain.checkConnection();
                },
                child: const Text('Check Connection'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  loan.setLoanApplicationData(
                    requestedAmount: BigInt.from(100000),
                    monthlyIncome: BigInt.from(65000),
                  );
                },
                child: const Text('Set Loan Data'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await loan.checkLoanEligibility(DemoUserData.nid);
                },
                child: const Text('Check Eligibility'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  cache.clearAllCache();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Clear Cache'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  appState.clearError();
                  loan.clearError();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Clear Errors'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: value is bool 
                  ? (value ? Colors.green : Colors.red)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}