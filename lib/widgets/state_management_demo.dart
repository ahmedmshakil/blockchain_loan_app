import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/blockchain_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/cache_manager.dart';
import '../utils/constants.dart';

/// Demo widget showing state management integration
/// Demonstrates real-time updates, caching, and provider coordination
/// Requirements: 2.3, 5.4, 7.4
class StateManagementDemo extends StatelessWidget {
  const StateManagementDemo({super.key});

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
            _buildAppStateSection(),
            const SizedBox(height: 20),
            _buildBlockchainStateSection(),
            const SizedBox(height: 20),
            _buildLoanStateSection(),
            const SizedBox(height: 20),
            _buildCacheSection(),
            const SizedBox(height: 20),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppStateSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App State Provider',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusRow('Initialized', appState.isInitialized),
                _buildStatusRow('Loading Borrower', appState.isLoadingBorrower),
                _buildStatusRow('Loading Credit Score', appState.isLoadingCreditScore),
                _buildStatusRow('Has Error', appState.hasError),
                if (appState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Error: ${appState.lastError}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (appState.currentBorrower != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Current Borrower: ${appState.currentBorrower!.name}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                if (appState.currentCreditScore != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Credit Score: ${appState.currentCreditScore!.score} (${appState.currentCreditScore!.rating})',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockchainStateSection() {
    return Consumer<BlockchainProvider>(
      builder: (context, blockchain, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Blockchain Provider',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusRow('Connected', blockchain.isConnected),
                _buildStatusRow('Initialized', blockchain.isInitialized),
                _buildStatusRow('Connecting', blockchain.isConnecting),
                if (blockchain.networkName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Network: ${blockchain.networkName}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                if (blockchain.walletBalance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Balance: ${blockchain.walletBalance} wei',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Pending Transactions: ${blockchain.pendingTransactions.length}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoanStateSection() {
    return Consumer<LoanProvider>(
      builder: (context, loan, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loan Provider',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusRow('Processing Application', loan.isProcessingApplication),
                _buildStatusRow('Checking Eligibility', loan.isCheckingEligibility),
                _buildStatusRow('Has Active Loans', loan.hasActiveLoans),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Total Applications: ${loan.loanApplications.length}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Requested Amount: ${loan.requestedAmount}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Monthly Income: ${loan.monthlyIncome}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCacheSection() {
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
                  'Cache Manager',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Memory Entries: ${stats['memoryEntries']}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cache Hits: ${stats['cacheHits']}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cache Misses: ${stats['cacheMisses']}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hit Ratio: ${(stats['hitRatio'] * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expired Entries: ${stats['expiredEntries']}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Consumer<AppStateProvider>(
                  builder: (context, appState, child) {
                    return ElevatedButton(
                      onPressed: appState.isLoadingBorrower
                          ? null
                          : () => _refreshBorrowerData(context),
                      child: const Text('Refresh Borrower'),
                    );
                  },
                ),
                Consumer<AppStateProvider>(
                  builder: (context, appState, child) {
                    return ElevatedButton(
                      onPressed: appState.isLoadingCreditScore
                          ? null
                          : () => _refreshCreditScore(context),
                      child: const Text('Refresh Credit Score'),
                    );
                  },
                ),
                Consumer<BlockchainProvider>(
                  builder: (context, blockchain, child) {
                    return ElevatedButton(
                      onPressed: blockchain.isConnecting
                          ? null
                          : () => _checkConnection(context),
                      child: const Text('Check Connection'),
                    );
                  },
                ),
                Consumer<CacheManager>(
                  builder: (context, cache, child) {
                    return ElevatedButton(
                      onPressed: () => _clearCache(context),
                      child: const Text('Clear Cache'),
                    );
                  },
                ),
                Consumer<LoanProvider>(
                  builder: (context, loan, child) {
                    return ElevatedButton(
                      onPressed: () => _updateLoanForm(context),
                      child: const Text('Update Loan Form'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${status ? 'Yes' : 'No'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _refreshBorrowerData(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    appState.loadBorrowerData(DemoUserData.nid, forceRefresh: true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing borrower data...')),
    );
  }

  void _refreshCreditScore(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    appState.loadCreditScore(DemoUserData.nid, forceRefresh: true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing credit score...')),
    );
  }

  void _checkConnection(BuildContext context) {
    final blockchain = context.read<BlockchainProvider>();
    blockchain.checkConnection();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking blockchain connection...')),
    );
  }

  void _clearCache(BuildContext context) {
    final cache = context.read<CacheManager>();
    cache.clearAllCache();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared!')),
    );
  }

  void _updateLoanForm(BuildContext context) {
    final loan = context.read<LoanProvider>();
    final random = DateTime.now().millisecondsSinceEpoch;
    
    loan.setLoanApplicationData(
      requestedAmount: BigInt.from(50000 + (random % 100000)),
      monthlyIncome: BigInt.from(60000 + (random % 40000)),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loan form updated with random values!')),
    );
  }
}