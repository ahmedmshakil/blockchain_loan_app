import 'package:flutter/material.dart';
import 'dart:async';
import '../services/startup_initialization_service.dart';
import '../widgets/user_onboarding_flow.dart';
import '../utils/constants.dart';
import '../utils/integration_validator.dart';
import '../utils/navigation_utils.dart';
import 'home_screen.dart';

/// Splash screen that handles application startup initialization
/// Shows loading animation and manages demo user setup
/// Requirements: 1.4, 2.2, 7.2
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final StartupInitializationService _startupService =
      StartupInitializationService.instance;

  late AnimationController _logoAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _progressAnimation;

  bool _showProgress = false;
  bool _initializationComplete = false;
  String _currentMessage = 'Initializing...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialization();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    // Logo animation
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Progress animation
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start logo animation
    _logoAnimationController.forward();
  }

  Future<void> _startInitialization() async {
    // Wait for logo animation to complete
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _showProgress = true;
      _currentMessage = 'Starting initialization...';
    });

    _progressAnimationController.forward();

    try {
      // Perform startup initialization
      setState(() {
        _currentMessage = 'Initializing services...';
      });

      final result = await _startupService.performStartupInitialization();

      if (result.isSuccess) {
        setState(() {
          _currentMessage = 'Validating integration...';
        });

        // Perform integration validation
        final validationResult =
            await IntegrationValidator.validateIntegration();

        if (validationResult.isSuccess) {
          setState(() {
            _currentMessage = 'Ready to launch!';
            _initializationComplete = true;
          });

          // Wait a moment to show success message
          await Future.delayed(const Duration(milliseconds: 1500));

          // Navigate to home screen
          if (mounted) {
            _navigateToHome();
          }
        } else {
          setState(() {
            _errorMessage = validationResult.message;
            _currentMessage = 'Integration validation failed';
          });
        }
      } else {
        // Check if user onboarding is required
        if (_startupService.isUserOnboardingRequired()) {
          setState(() {
            _currentMessage = 'Setup required';
          });

          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted) {
            _navigateToOnboarding();
          }
        } else {
          // Show error and allow retry or continue
          setState(() {
            _errorMessage = result.message;
            _currentMessage = 'Initialization failed';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _currentMessage = 'Initialization failed';
      });
    }
  }

  void _navigateToHome() {
    NavigationUtils.navigateWithFade(
      context,
      const HomeScreen(),
      replace: true,
    );
  }

  void _navigateToOnboarding() {
    if (!mounted) return;

    NavigationUtils.navigateWithSlide(
      context,
      UserOnboardingFlow(
        onInitializationComplete: () {
          // The onboarding widget should handle this navigation
          // using its own context, not the splash screen context
        },
        onSkip: () {
          // The onboarding widget should handle this navigation
          // using its own context, not the splash screen context
        },
      ),
      replace: true,
    );
  }

  void _retryInitialization() {
    setState(() {
      _errorMessage = null;
      _currentMessage = 'Retrying...';
      _initializationComplete = false;
    });

    _startInitialization();
  }

  void _continueWithoutSetup() {
    _navigateToHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo section
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _logoAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: AppConstants.primaryBlue
                                          .withValues(alpha: 0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Background gradient circle
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppConstants.primaryBlue.withValues(
                                              alpha: 0.1,
                                            ),
                                            AppConstants.lightBlue.withValues(
                                              alpha: 0.1,
                                            ),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                    ),
                                    // Main icon
                                    const Icon(
                                      Icons.account_balance,
                                      size: 64,
                                      color: AppConstants.primaryBlue,
                                    ),
                                    // Blockchain indicator
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppConstants.successColor,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.link,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                AppConstants.bankName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Blockchain-Powered Banking',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Progress section
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_showProgress) ...[
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _progressAnimation,
                            child: Column(
                              children: [
                                // Progress indicator or error icon
                                if (_errorMessage == null &&
                                    !_initializationComplete) ...[
                                  const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ] else if (_initializationComplete) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppConstants.successColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ] else if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppConstants.errorColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // Status message
                                Text(
                                  _currentMessage,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  textAlign: TextAlign.center,
                                ),

                                // Error message
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // Action buttons (only show if there's an error)
              if (_errorMessage != null) ...[
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _retryInitialization,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppConstants.primaryBlue,
                        ),
                        child: const Text('Retry Setup'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _continueWithoutSetup,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Continue Without Setup'),
                      ),
                    ),
                  ],
                ),
              ],

              // Version info
              const SizedBox(height: 24),
              Text(
                'Version ${AppConstants.appVersion}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
