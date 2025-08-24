import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:web3dart/web3dart.dart';
import '../services/blockchain_service.dart';
import '../services/web3_service.dart';
import '../config/blockchain_config.dart';
import '../models/borrower_model.dart';
import '../utils/constants.dart';

/// Screen for testing Sepolia testnet connectivity and blockchain functionality
/// Requirements: 2.1, 2.4, 8.2, 8.4
class SepoliaTestScreen extends StatefulWidget {
  const SepoliaTestScreen({super.key});

  @override
  State<SepoliaTestScreen> createState() => _SepoliaTestScreenState();
}

class _SepoliaTestScreenState extends State<SepoliaTestScreen> {
  final BlockchainService _blockchainService = BlockchainService.instance;
  final Web3Service _web3Service = Web3Service.instance;
  
  // Test status tracking
  bool _isTestingConnection = false;
  bool _isTestingContract = false;
  bool _isTestingTransaction = false;
  bool _isLoadingBalance = false;
  
  // Test results
  Map<String, dynamic>? _networkStatus;
  String? _walletBalance;
  String? _contractTestResult;
  String? _transactionTestResult;
  String? _lastError;
  
  // Connection status
  bool _isConnected = false;
  bool _contractAccessible = false;
  
  @override
  void initState() {
    super.initState();
    _initializeTests();
  }

  /// Initialize basic connectivity tests on screen load
  Future<void> _initializeTests() async {
    await _testNetworkConnection();
    await _checkWalletBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sepolia Testnet Testing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllTests,
            tooltip: 'Refresh All Tests',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            _buildNetworkStatusSection(),
            const SizedBox(height: 24),
            _buildWalletSection(),
            const SizedBox(height: 24),
            _buildContractTestSection(),
            const SizedBox(height: 24),
            _buildTransactionTestSection(),
            const SizedBox(height: 24),
            _buildConfigurationSection(),
            if (_lastError != null) ...[
              const SizedBox(height: 24),
              _buildErrorSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science,
                  color: AppConstants.primaryBlue,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blockchain Testing Suite',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Test connectivity and functionality with Sepolia testnet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusIndicator('Network', _isConnected),
                const SizedBox(width: 16),
                _buildStatusIndicator('Contract', _contractAccessible),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? AppConstants.successColor.withValues(alpha: 0.1)
            : AppConstants.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.error,
            size: 16,
            color: isActive ? AppConstants.successColor : AppConstants.errorColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppConstants.successColor : AppConstants.errorColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Network Connection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isTestingConnection)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _testNetworkConnection,
                    tooltip: 'Test Network Connection',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_networkStatus != null) ...[
              _buildNetworkDetailRow('Network', _networkStatus!['network'] ?? 'Unknown'),
              _buildNetworkDetailRow('Chain ID', _networkStatus!['chainId']?.toString() ?? 'Unknown'),
              _buildNetworkDetailRow('Connected', _networkStatus!['isConnected']?.toString() ?? 'false'),
              _buildNetworkDetailRow('RPC URL', _networkStatus!['rpcUrl'] ?? 'Not configured'),
              _buildNetworkDetailRow('Gas Price', _formatGasPrice(_networkStatus!['gasPrice'])),
            ] else ...[
              const Text('Network status not available. Click refresh to test connection.'),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTestingConnection ? null : _testNetworkConnection,
                icon: _isTestingConnection 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check),
                label: Text(_isTestingConnection ? 'Testing...' : 'Test Network Connection'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wallet Balance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoadingBalance)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _checkWalletBalance,
                    tooltip: 'Refresh Balance',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNetworkDetailRow('Wallet Address', BlockchainConfig.demoWalletAddress),
            _buildNetworkDetailRow(
              'Sepolia ETH Balance', 
              _walletBalance ?? 'Loading...',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingBalance ? null : _checkWalletBalance,
                    icon: _isLoadingBalance 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.account_balance_wallet),
                    label: Text(_isLoadingBalance ? 'Checking...' : 'Check Balance'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyWalletAddress,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Address'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Smart Contract Testing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isTestingContract)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNetworkDetailRow('Contract Address', BlockchainConfig.contractAddress),
            if (_contractTestResult != null) ...[
              _buildNetworkDetailRow('Test Result', _contractTestResult!),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTestingContract ? null : _testContractInteraction,
                icon: _isTestingContract 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.smart_toy),
                label: Text(_isTestingContract ? 'Testing Contract...' : 'Test Contract Interaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Testing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isTestingTransaction)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Test blockchain transaction functionality by adding a test borrower to the smart contract.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (_transactionTestResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _transactionTestResult!.startsWith('Success')
                      ? AppConstants.successColor.withValues(alpha: 0.1)
                      : AppConstants.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _transactionTestResult!.startsWith('Success')
                          ? Icons.check_circle
                          : Icons.error,
                      color: _transactionTestResult!.startsWith('Success')
                          ? AppConstants.successColor
                          : AppConstants.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _transactionTestResult!,
                        style: TextStyle(
                          color: _transactionTestResult!.startsWith('Success')
                              ? AppConstants.successColor
                              : AppConstants.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTestingTransaction ? null : _testTransaction,
                icon: _isTestingTransaction 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isTestingTransaction ? 'Sending Transaction...' : 'Test Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildNetworkDetailRow('Network Name', BlockchainConfig.networkName),
            _buildNetworkDetailRow('Chain ID', BlockchainConfig.chainId.toString()),
            _buildNetworkDetailRow('Default Gas Limit', BlockchainConfig.defaultGasLimit.toString()),
            _buildNetworkDetailRow('Max Retry Attempts', BlockchainConfig.maxRetryAttempts.toString()),
            _buildNetworkDetailRow('Transaction Timeout', '${BlockchainConfig.transactionTimeout.inMinutes} minutes'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Card(
      color: AppConstants.errorColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppConstants.errorColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last Error',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _lastError!,
              style: TextStyle(
                color: AppConstants.errorColor,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _clearError,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Error'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.errorColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _copyError,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Error'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkDetailRow(String label, String value) {
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

  // Test Methods

  /// Test network connection and retrieve status
  /// Requirements: 2.1, 8.2
  Future<void> _testNetworkConnection() async {
    setState(() {
      _isTestingConnection = true;
      _lastError = null;
    });

    try {
      developer.log('Testing network connection...', name: 'SepoliaTestScreen');
      
      final networkStatus = await _blockchainService.getNetworkStatus();
      
      setState(() {
        _networkStatus = networkStatus;
        _isConnected = networkStatus['isConnected'] == true;
        _isTestingConnection = false;
      });

      if (_isConnected) {
        _showSuccessSnackBar('Network connection successful!');
      } else {
        _showErrorSnackBar('Network connection failed');
      }
    } catch (e) {
      developer.log('Network connection test failed: $e', name: 'SepoliaTestScreen');
      setState(() {
        _lastError = e.toString();
        _isConnected = false;
        _isTestingConnection = false;
      });
      _showErrorSnackBar('Network test failed: ${e.toString()}');
    }
  }

  /// Check wallet balance on Sepolia testnet
  /// Requirements: 2.1, 8.2
  Future<void> _checkWalletBalance() async {
    setState(() {
      _isLoadingBalance = true;
      _lastError = null;
    });

    try {
      developer.log('Checking wallet balance...', name: 'SepoliaTestScreen');
      
      final balance = await _web3Service.getBalance();
      final balanceInEth = balance.getValueInUnit(EtherUnit.ether);
      
      setState(() {
        _walletBalance = '${balanceInEth.toStringAsFixed(6)} ETH';
        _isLoadingBalance = false;
      });

      if (balanceInEth > 0) {
        _showSuccessSnackBar('Wallet balance loaded successfully!');
      } else {
        _showWarningSnackBar('Wallet has no Sepolia ETH. Get testnet ETH from faucet.');
      }
    } catch (e) {
      developer.log('Balance check failed: $e', name: 'SepoliaTestScreen');
      setState(() {
        _lastError = e.toString();
        _walletBalance = 'Error loading balance';
        _isLoadingBalance = false;
      });
      _showErrorSnackBar('Balance check failed: ${e.toString()}');
    }
  }

  /// Test smart contract interaction
  /// Requirements: 2.4, 8.2
  Future<void> _testContractInteraction() async {
    setState(() {
      _isTestingContract = true;
      _lastError = null;
    });

    try {
      developer.log('Testing contract interaction...', name: 'SepoliaTestScreen');
      
      // Test contract accessibility by trying to get a borrower (read operation)
      final testNid = 'TEST_${DateTime.now().millisecondsSinceEpoch}';
      await _blockchainService.getBorrowerData(testNid);
      
      setState(() {
        _contractTestResult = 'Success: Contract is accessible and responding';
        _contractAccessible = true;
        _isTestingContract = false;
      });

      _showSuccessSnackBar('Contract interaction test successful!');
    } catch (e) {
      developer.log('Contract interaction test failed: $e', name: 'SepoliaTestScreen');
      setState(() {
        _lastError = e.toString();
        _contractTestResult = 'Failed: ${e.toString()}';
        _contractAccessible = false;
        _isTestingContract = false;
      });
      _showErrorSnackBar('Contract test failed: ${e.toString()}');
    }
  }

  /// Test blockchain transaction functionality
  /// Requirements: 2.4, 8.4
  Future<void> _testTransaction() async {
    setState(() {
      _isTestingTransaction = true;
      _lastError = null;
    });

    try {
      developer.log('Testing blockchain transaction...', name: 'SepoliaTestScreen');
      
      // Create a test borrower with unique NID
      final testNid = 'TEST_${DateTime.now().millisecondsSinceEpoch}';
      final testBorrower = BorrowerModel(
        name: 'Test User',
        nid: testNid,
        profession: 'Software Tester',
        accountBalance: BigInt.from(100000),
        totalTransactions: BigInt.from(50),
        onTimePayments: BigInt.from(45),
        missedPayments: BigInt.from(5),
        totalRemainingLoan: BigInt.from(0),
        creditAgeMonths: BigInt.from(12),
        professionRiskScore: BigInt.from(2),
        exists: false,
      );

      // Attempt to add borrower to blockchain
      final txHash = await _blockchainService.addBorrowerToBlockchain(testBorrower);
      
      setState(() {
        _transactionTestResult = 'Success: Transaction sent with hash: ${txHash.substring(0, 10)}...';
        _isTestingTransaction = false;
      });

      _showSuccessSnackBar('Transaction test successful!');
      
      // Optionally verify the transaction
      _verifyTestTransaction(txHash);
    } catch (e) {
      developer.log('Transaction test failed: $e', name: 'SepoliaTestScreen');
      setState(() {
        _lastError = e.toString();
        _transactionTestResult = 'Failed: ${e.toString()}';
        _isTestingTransaction = false;
      });
      
      if (e.toString().contains('insufficient funds')) {
        _showErrorSnackBar('Transaction failed: Insufficient Sepolia ETH for gas fees');
      } else {
        _showErrorSnackBar('Transaction test failed: ${e.toString()}');
      }
    }
  }

  /// Verify test transaction status
  Future<void> _verifyTestTransaction(String txHash) async {
    try {
      developer.log('Verifying transaction: $txHash', name: 'SepoliaTestScreen');
      
      // Wait a moment for transaction to be processed
      await Future.delayed(const Duration(seconds: 3));
      
      final isConfirmed = await _blockchainService.verifyTransaction(txHash);
      
      if (isConfirmed) {
        setState(() {
          _transactionTestResult = 'Success: Transaction confirmed on blockchain';
        });
        _showSuccessSnackBar('Transaction confirmed on blockchain!');
      } else {
        setState(() {
          _transactionTestResult = 'Pending: Transaction is still being processed';
        });
        _showInfoSnackBar('Transaction is pending confirmation');
      }
    } catch (e) {
      developer.log('Transaction verification failed: $e', name: 'SepoliaTestScreen');
      // Don't update the UI state for verification errors
    }
  }

  // Utility Methods

  /// Refresh all tests
  Future<void> _refreshAllTests() async {
    await _testNetworkConnection();
    await _checkWalletBalance();
    await _testContractInteraction();
  }

  /// Copy wallet address to clipboard
  void _copyWalletAddress() {
    Clipboard.setData(ClipboardData(text: BlockchainConfig.demoWalletAddress));
    _showSuccessSnackBar('Wallet address copied to clipboard');
  }

  /// Copy error message to clipboard
  void _copyError() {
    if (_lastError != null) {
      Clipboard.setData(ClipboardData(text: _lastError!));
      _showSuccessSnackBar('Error message copied to clipboard');
    }
  }

  /// Clear the last error
  void _clearError() {
    setState(() {
      _lastError = null;
    });
  }

  /// Format gas price for display
  String _formatGasPrice(dynamic gasPrice) {
    if (gasPrice == null) return 'Unknown';
    try {
      final gasPriceBigInt = BigInt.parse(gasPrice.toString());
      final gasPriceGwei = gasPriceBigInt / BigInt.from(1000000000); // Convert wei to gwei
      return '${gasPriceGwei.toString()} Gwei';
    } catch (e) {
      return 'Invalid';
    }
  }

  // SnackBar helpers
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.warningColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.primaryBlue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}