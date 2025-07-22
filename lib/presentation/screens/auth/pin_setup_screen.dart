import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/security/authentication_service.dart';
import '../../app/app_providers.dart';
import '../../widgets/futuristic_button.dart';
import '../../widgets/pin_input_widget.dart';

/// PIN setup screen for first-time users
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPinChanged(String pin) {
    setState(() {
      _errorMessage = null;
      
      if (_isConfirming) {
        _confirmPin = pin;
        if (pin.length == 6) {
          _validateAndSetupPin();
        }
      } else {
        _pin = pin;
        if (pin.length == 6) {
          _proceedToConfirmation();
        }
      }
    });
  }

  void _proceedToConfirmation() {
    setState(() {
      _isConfirming = true;
    });
    
    _slideController.forward();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _goBackToSetup() {
    setState(() {
      _isConfirming = false;
      _confirmPin = '';
      _errorMessage = null;
    });
    
    _slideController.reverse();
  }

  Future<void> _validateAndSetupPin() async {
    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _confirmPin = '';
      });
      
      // Haptic feedback for error
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.setupPin(_pin);
      
      // Update authentication state
      ref.read(isAuthenticatedProvider.notifier).state = true;
      
      // Haptic feedback for success
      HapticFeedback.mediumImpact();
      
      // Navigate to biometric setup or home
      if (mounted) {
        context.goNamed('biometric_setup');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to setup PIN: ${e.toString()}';
        _isLoading = false;
      });
      
      // Haptic feedback for error
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeController,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.security,
                            size: 40,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          _isConfirming ? 'Confirm Your PIN' : 'Setup Your PIN',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onBackground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          _isConfirming
                              ? 'Please enter your PIN again to confirm'
                              : 'Create a 6-digit PIN to secure your expense tracker',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // PIN Input
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: PinInputWidget(
                            key: ValueKey(_isConfirming),
                            length: 6,
                            onChanged: _onPinChanged,
                            value: _isConfirming ? _confirmPin : _pin,
                            isObscured: true,
                            errorMessage: _errorMessage,
                          ),
                        ),
                        
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Actions
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_isConfirming) ...[
                          FuturisticButton(
                            onPressed: _goBackToSetup,
                            text: 'Back',
                            variant: FuturisticButtonVariant.outlined,
                            isLoading: false,
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        if (_isLoading)
                          FuturisticButton(
                            onPressed: null,
                            text: 'Setting up...',
                            isLoading: true,
                          )
                        else if (_isConfirming && _confirmPin.length == 6)
                          FuturisticButton(
                            onPressed: _validateAndSetupPin,
                            text: 'Complete Setup',
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Security info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Your PIN is encrypted and stored locally',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onBackground.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
