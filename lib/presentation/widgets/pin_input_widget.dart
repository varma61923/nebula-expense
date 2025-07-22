import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Futuristic PIN input widget with neon effects
class PinInputWidget extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final String value;
  final bool isObscured;
  final String? errorMessage;
  final bool isEnabled;

  const PinInputWidget({
    super.key,
    required this.length,
    required this.onChanged,
    this.value = '',
    this.isObscured = false,
    this.errorMessage,
    this.isEnabled = true,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late List<AnimationController> _dotControllers;
  
  String _currentValue = '';

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _dotControllers = List.generate(
      widget.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(PinInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.value != oldWidget.value) {
      _currentValue = widget.value;
      _updateDotAnimations();
    }
    
    if (widget.errorMessage != null && oldWidget.errorMessage == null) {
      _triggerShakeAnimation();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    for (final controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateDotAnimations() {
    for (int i = 0; i < widget.length; i++) {
      if (i < _currentValue.length) {
        _dotControllers[i].forward();
      } else {
        _dotControllers[i].reverse();
      }
    }
  }

  void _triggerShakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
    HapticFeedback.heavyImpact();
  }

  void _onKeypadPressed(String value) {
    if (!widget.isEnabled) return;
    
    if (value == 'backspace') {
      if (_currentValue.isNotEmpty) {
        _currentValue = _currentValue.substring(0, _currentValue.length - 1);
        widget.onChanged(_currentValue);
        HapticFeedback.lightImpact();
      }
    } else if (_currentValue.length < widget.length) {
      _currentValue += value;
      widget.onChanged(_currentValue);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN dots display
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final shakeValue = _shakeController.value;
            final shakeOffset = Tween<double>(
              begin: 0,
              end: 10,
            ).animate(CurvedAnimation(
              parent: _shakeController,
              curve: Curves.elasticIn,
            )).value * (1 - shakeValue);
            
            return Transform.translate(
              offset: Offset(shakeOffset * (shakeValue > 0.5 ? -1 : 1), 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.length, (index) {
                  return AnimatedBuilder(
                    animation: _dotControllers[index],
                    builder: (context, child) {
                      final isActive = index < _currentValue.length;
                      final isCurrent = index == _currentValue.length;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildPinDot(
                          theme,
                          isActive,
                          isCurrent,
                          _dotControllers[index].value,
                        ),
                      );
                    },
                  );
                }),
              ),
            );
          },
        ),
        
        const SizedBox(height: 48),
        
        // Custom keypad
        _buildKeypad(theme),
      ],
    );
  }

  Widget _buildPinDot(ThemeData theme, bool isActive, bool isCurrent, double animationValue) {
    final size = 16.0 + (animationValue * 4);
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = isCurrent ? _pulseController.value : 0.0;
        
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.2),
            boxShadow: isActive || isCurrent
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4 + (pulseValue * 0.3)),
                      blurRadius: 8 + (pulseValue * 4),
                      spreadRadius: pulseValue * 2,
                    ),
                  ]
                : null,
          ),
          child: widget.isObscured && isActive
              ? Icon(
                  Icons.circle,
                  size: size * 0.6,
                  color: theme.colorScheme.onPrimary,
                )
              : null,
        );
      },
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    final keypadButtons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'backspace'],
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: keypadButtons.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 64, height: 64);
                }
                
                return _buildKeypadButton(theme, key);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeypadButton(ThemeData theme, String key) {
    final isBackspace = key == 'backspace';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () => _onKeypadPressed(key),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface.withOpacity(0.1),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: isBackspace
                ? Icon(
                    Icons.backspace_outlined,
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  )
                : Text(
                    key,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
