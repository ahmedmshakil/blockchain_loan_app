import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/demo_user_initialization_service.dart';
import '../utils/constants.dart';
import '../utils/navigation_utils.dart';
import '../config/blockchain_config.dart';
import '../screens/home_screen.dart';

/// User onboarding flow widget for blockchain setup guidance
/// Provides step-by-step guidance for demo user initialization
/// Requirements: 1.4, 7.2
class UserOnboardingFlow extends StatefulWidget {
  final VoidCallback? onInitializationComplete;
  final VoidCallback? onSkip;
  final bool showSkipOption;

  const UserOnboardingFlow({
    super.key,
    this.onInitializationComplete,
    this.onSkip,
    this.showSkipOption = true,
  });

  @override
  State<UserOnboardingFlow> createState() => _UserOnboardingFlowState();
}

class _UserOnboardingFlowState extends State<UserOnboardingFlow>
    with TickerProviderStateMixin {
  final DemoUserInitializationService _initService =
      DemoUserInitializationService.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isInitializing = false;
  String? _initializationError;
  String? _initializationMessage;
  int _currentStep = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Welcome to Midnight Bank Ltd.',
      description: 'Your blockchain-powered banking experience starts here.',
      icon: Icons.account_balance,
      color: AppConstants.primaryBlue,
    ),
    OnboardingStep(
      title: 'Blockchain Setup',
      description:
          'We\'ll initialize your account on the Sepolia blockchain for secure, transparent banking.',
      icon: Icons.security,
      color: AppConstants.lightBlue,
    ),
    OnboardingStep(
      title: 'Demo User Creation',
      description:
          'Setting up your demo profile with credit history and financial data.',
      icon: Icons.person_add,
      color: AppConstants.successColor,
    ),
    OnboardingStep(
      title: 'Ready to Bank!',
      description:
          'Your blockchain banking account is ready. Enjoy secure, transparent financial services.',
      icon: Icons.check_circle,
      color: AppConstants.successColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Check if already initialized
    _checkInitializationStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkInitializationStatus() {
    if (_initService.isInitialized && mounted) {
      setState(() {
        _currentStep = _steps.length - 1;
      });
    }
  }

  Future<void> _startInitialization() async {
    if (_isInitializing) return;

    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _initializationError = null;
      _initializationMessage = 'Starting blockchain initialization...';
      _currentStep = 1;
    });

    try {
      // Step 1: Blockchain Setup
      if (!mounted) return;
      setState(() {
        _initializationMessage = 'Connecting to Sepolia blockchain...';
      });
      await Future.delayed(const Duration(seconds: 1)); // UI feedback delay

      // Step 2: Demo User Creation
      if (!mounted) return;
      setState(() {
        _currentStep = 2;
        _initializationMessage = 'Creating your demo profile on blockchain...';
      });

      final result = await _initService.initializeDemoUserWithRetry();

      if (!mounted) return;
      if (result.isSuccess) {
        setState(() {
          _currentStep = 3;
          _initializationMessage = 'Initialization completed successfully!';
        });

        // Wait a moment to show success
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          _handleInitializationComplete();
        }
      } else {
        setState(() {
          _initializationError = result.message;
          _initializationMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializationError = 'Unexpected error: $e';
        _initializationMessage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _retryInitialization() {
    if (!mounted) return;
    setState(() {
      _initializationError = null;
      _currentStep = 0;
    });
  }

  void _handleSkipSetup() {
    if (!mounted) return;

    // Navigate to home screen using this widget's context
    NavigationUtils.navigateWithFade(
      context,
      const HomeScreen(),
      replace: true,
    );

    // Also call the callback if provided
    widget.onSkip?.call();
  }

  void _handleInitializationComplete() {
    if (!mounted) return;

    // Navigate to home screen using this widget's context
    NavigationUtils.navigateWithFade(
      context,
      const HomeScreen(),
      replace: true,
    );

    // Also call the callback if provided
    widget.onInitializationComplete?.call();
  }

  void _copyWalletAddress() {
    if (!mounted) return;

    Clipboard.setData(
      const ClipboardData(text: BlockchainConfig.demoWalletAddress),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wallet address copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Header
                _buildHeader(),

                const SizedBox(height: 32),

                // Progress indicator
                _buildProgressIndicator(),

                const SizedBox(height: 32),

                // Current step content
                Expanded(child: _buildStepContent()),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.primaryBlue,
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.account_balance,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConstants.bankName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryBlue,
          ),
        ),
        Text(
          'Blockchain Banking Setup',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(_steps.length, (index) {
        final isActive = index <= _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? _steps[index].color : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < _steps.length - 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    final step = _steps[_currentStep];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Step icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: step.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Icon(step.icon, color: step.color, size: 48),
        ),

        const SizedBox(height: 24),

        // Step title
        Text(
          step.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryBlue,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Step description
        Text(
          step.description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Loading indicator or error message
        if (_isInitializing) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          if (_initializationMessage != null)
            Text(
              _initializationMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppConstants.primaryBlue),
              textAlign: TextAlign.center,
            ),
        ] else if (_initializationError != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppConstants.errorColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppConstants.errorColor,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Initialization Failed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppConstants.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _initializationError!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.errorColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTroubleshootingTips(),
        ],

        // Demo user information
        if (_currentStep >= 2 && !_isInitializing) ...[
          const SizedBox(height: 24),
          _buildDemoUserInfo(),
        ],
      ],
    );
  }

  Widget _buildDemoUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppConstants.successColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Demo User Profile',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppConstants.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Name', DemoUserData.name),
          _buildInfoRow('NID', DemoUserData.nid),
          _buildInfoRow('Profession', DemoUserData.profession),
          _buildInfoRow('Account Balance', '৳${DemoUserData.accountBalance}'),
          _buildInfoRow('Credit Age', '${DemoUserData.creditAgeMonths} months'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppConstants.warningColor,
                size: 20,
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
          _buildTipItem('Ensure you have internet connection'),
          _buildTipItem('Check if Sepolia testnet is accessible'),
          _buildTipItem('Verify wallet has sufficient Sepolia ETH'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Wallet: ${BlockchainConfig.demoWalletAddress}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
              IconButton(
                onPressed: _copyWalletAddress,
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy wallet address',
              ),
            ],
          ),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_currentStep == 0) ...[
          // Start initialization button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isInitializing ? null : _startInitialization,
              child: const Text('Start Account Setup'),
            ),
          ),
          if (widget.showSkipOption) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _handleSkipSetup,
              child: const Text('Skip Setup (Demo Mode)'),
            ),
          ],
        ] else if (_initializationError != null) ...[
          // Retry button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _retryInitialization,
              child: const Text('Retry Setup'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _handleSkipSetup,
            child: const Text('Continue Without Setup'),
          ),
        ] else if (_currentStep == _steps.length - 1 && !_isInitializing) ...[
          // Continue to app button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleInitializationComplete,
              child: const Text('Continue to Banking'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Data class for onboarding steps
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
