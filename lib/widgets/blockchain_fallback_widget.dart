import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/startup_initialization_service.dart';
import '../services/demo_user_initialization_service.dart';

/// Widget that displays fallback options when blockchain initialization fails
/// Provides guidance and retry options for users
/// Requirements: 7.2
class BlockchainFallbackWidget extends StatefulWidget {
  final VoidCallback? onRetryInitialization;
  final VoidCallback? onContinueWithoutBlockchain;
  final String? errorMessage;
  final bool showRetryOption;
  final bool showContinueOption;
  
  const BlockchainFallbackWidget({
    super.key,
    this.onRetryInitialization,
    this.onContinueWithoutBlockchain,
    this.errorMessage,
    this.showRetryOption = true,
    this.showContinueOption = true,
  });
  
  @override
  State<BlockchainFallbackWidget> createState() => _BlockchainFallbackWidgetState();
}

class _BlockchainFallbackWidgetState extends State<BlockchainFallbackWidget> {
  final StartupInitializationService _startupService = StartupInitializationService.instance;
  final DemoUserInitializationService _demoUserService = DemoUserInitializationService.instance;
  
  bool _isRetrying = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon and title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.cloud_off,
              size: 48,
              color: AppConstants.errorColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Blockchain Connection Issue',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.errorColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Unable to connect to the blockchain network. You can retry the connection or continue with limited functionality.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstants.errorColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppConstants.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Error Details',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppConstants.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Status information
          _buildStatusInformation(),
          
          const SizedBox(height: 24),
          
          // Troubleshooting tips
          _buildTroubleshootingTips(),
          
          const SizedBox(height: 24),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildStatusInformation() {
    final startupStatus = _startupService.getStartupStatus();
    final demoUserStatus = _demoUserService.getInitializationStatus();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.lightBlue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppConstants.lightBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'System Status',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppConstants.lightBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusRow('Startup Phase', startupStatus['currentPhase'] ?? 'Unknown'),
          _buildStatusRow('Demo User', demoUserStatus['isInitialized'] ? 'Initialized' : 'Not Initialized'),
          _buildStatusRow('Blockchain Network', startupStatus['fallbackModeActive'] ? 'Fallback Mode' : 'Disconnected'),
          _buildStatusRow('Last Attempt', _formatDateTime(startupStatus['endTime'])),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTroubleshootingTips() {
    final guidance = _startupService.getInitializationGuidance();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.warningColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppConstants.warningColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Troubleshooting Tips',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppConstants.warningColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...guidance.map((tip) => _buildTipItem(tip)),
          const SizedBox(height: 8),
          _buildTipItem('Check your internet connection'),
          _buildTipItem('Verify Sepolia testnet is accessible'),
          _buildTipItem('Ensure wallet has sufficient Sepolia ETH'),
          _buildTipItem('Try again in a few minutes'),
        ],
      ),
    );
  }
  
  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.warningColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.showRetryOption) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRetrying ? null : _handleRetry,
              icon: _isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isRetrying ? 'Retrying...' : 'Retry Connection'),
            ),
          ),
        ],
        
        if (widget.showContinueOption) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onContinueWithoutBlockchain,
              icon: const Icon(Icons.offline_bolt),
              label: const Text('Continue Offline'),
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        Text(
          'Note: Some features may be limited without blockchain connection',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    
    setState(() {
      _isRetrying = true;
    });
    
    try {
      // Reset startup state and retry
      _startupService.resetStartupState();
      
      // Wait a moment for UI feedback
      await Future.delayed(const Duration(seconds: 1));
      
      // Call the retry callback
      widget.onRetryInitialization?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }
  
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Never';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}