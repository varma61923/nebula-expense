import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Futuristic button widget with glassmorphic and neon effects
class FuturisticButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final FuturisticButtonVariant variant;
  final FuturisticButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final Color? customColor;
  final Widget? child;

  const FuturisticButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.variant = FuturisticButtonVariant.filled,
    this.size = FuturisticButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.customColor,
    this.child,
  });

  @override
  State<FuturisticButton> createState() => _FuturisticButtonState();
}

class _FuturisticButtonState extends State<FuturisticButton>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late AnimationController _loadingController;
  
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(FuturisticButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
      }
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  void _onHoverEnter(PointerEvent event) {
    setState(() {
      _isHovered = true;
    });
    _hoverController.forward();
  }

  void _onHoverExit(PointerEvent event) {
    setState(() {
      _isHovered = false;
    });
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    // Get button dimensions based on size
    final dimensions = _getButtonDimensions();
    
    // Get colors based on variant and theme
    final colors = _getButtonColors(theme);
    
    Widget buttonContent = widget.child ?? _buildButtonContent(theme);
    
    return MouseRegion(
      onEnter: isEnabled ? _onHoverEnter : null,
      onExit: isEnabled ? _onHoverExit : null,
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverController,
            _pressController,
            _loadingController,
          ]),
          builder: (context, child) {
            final hoverValue = _hoverController.value;
            final pressValue = _pressController.value;
            final scale = 1.0 - (pressValue * 0.05);
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.isExpanded ? double.infinity : dimensions.width,
                height: dimensions.height,
                decoration: _buildButtonDecoration(colors, hoverValue),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isEnabled ? widget.onPressed : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: dimensions.horizontalPadding,
                        vertical: dimensions.verticalPadding,
                      ),
                      child: buttonContent,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (widget.isLoading) {
      return _buildLoadingContent(theme);
    }
    
    final textStyle = _getTextStyle(theme);
    
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            size: _getIconSize(),
            color: textStyle.color,
          ),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: textStyle,
          ),
        ],
      );
    }
    
    return Text(
      widget.text,
      style: textStyle,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingContent(ThemeData theme) {
    final textStyle = _getTextStyle(theme);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              textStyle.color ?? theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.text,
          style: textStyle,
        ),
      ],
    );
  }

  BoxDecoration _buildButtonDecoration(ButtonColors colors, double hoverValue) {
    switch (widget.variant) {
      case FuturisticButtonVariant.filled:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(colors.primary, colors.primaryHover, hoverValue)!,
              Color.lerp(colors.secondary, colors.secondaryHover, hoverValue)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.3 + (hoverValue * 0.2)),
              blurRadius: 8 + (hoverValue * 4),
              spreadRadius: hoverValue * 2,
              offset: const Offset(0, 4),
            ),
          ],
        );
        
      case FuturisticButtonVariant.outlined:
        return BoxDecoration(
          color: colors.background.withOpacity(0.1 + (hoverValue * 0.1)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color.lerp(colors.primary, colors.primaryHover, hoverValue)!,
            width: 2,
          ),
          boxShadow: [
            if (hoverValue > 0)
              BoxShadow(
                color: colors.primary.withOpacity(hoverValue * 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        );
        
      case FuturisticButtonVariant.glass:
        return BoxDecoration(
          color: colors.background.withOpacity(0.1 + (hoverValue * 0.1)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2 + (hoverValue * 0.1)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (hoverValue > 0)
              BoxShadow(
                color: colors.primary.withOpacity(hoverValue * 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        );
        
      case FuturisticButtonVariant.neon:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color.lerp(colors.primary, colors.primaryHover, hoverValue)!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.5 + (hoverValue * 0.3)),
              blurRadius: 10 + (hoverValue * 10),
              spreadRadius: hoverValue * 3,
            ),
            BoxShadow(
              color: colors.primary.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        );
    }
  }

  ButtonDimensions _getButtonDimensions() {
    switch (widget.size) {
      case FuturisticButtonSize.small:
        return const ButtonDimensions(
          width: null,
          height: 36,
          horizontalPadding: 16,
          verticalPadding: 8,
        );
      case FuturisticButtonSize.medium:
        return const ButtonDimensions(
          width: null,
          height: 48,
          horizontalPadding: 24,
          verticalPadding: 12,
        );
      case FuturisticButtonSize.large:
        return const ButtonDimensions(
          width: null,
          height: 56,
          horizontalPadding: 32,
          verticalPadding: 16,
        );
    }
  }

  ButtonColors _getButtonColors(ThemeData theme) {
    final primary = widget.customColor ?? theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    
    return ButtonColors(
      primary: primary,
      secondary: secondary,
      primaryHover: _lightenColor(primary, 0.1),
      secondaryHover: _lightenColor(secondary, 0.1),
      background: theme.colorScheme.surface,
      onPrimary: theme.colorScheme.onPrimary,
      onSurface: theme.colorScheme.onSurface,
    );
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final colors = _getButtonColors(theme);
    
    Color textColor;
    switch (widget.variant) {
      case FuturisticButtonVariant.filled:
        textColor = colors.onPrimary;
        break;
      case FuturisticButtonVariant.outlined:
      case FuturisticButtonVariant.glass:
      case FuturisticButtonVariant.neon:
        textColor = colors.primary;
        break;
    }
    
    TextStyle baseStyle;
    switch (widget.size) {
      case FuturisticButtonSize.small:
        baseStyle = theme.textTheme.labelMedium!;
        break;
      case FuturisticButtonSize.medium:
        baseStyle = theme.textTheme.labelLarge!;
        break;
      case FuturisticButtonSize.large:
        baseStyle = theme.textTheme.titleMedium!;
        break;
    }
    
    return baseStyle.copyWith(
      color: textColor,
      fontWeight: FontWeight.w600,
    );
  }

  double _getIconSize() {
    switch (widget.size) {
      case FuturisticButtonSize.small:
        return 16;
      case FuturisticButtonSize.medium:
        return 20;
      case FuturisticButtonSize.large:
        return 24;
    }
  }

  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}

enum FuturisticButtonVariant {
  filled,
  outlined,
  glass,
  neon,
}

enum FuturisticButtonSize {
  small,
  medium,
  large,
}

class ButtonDimensions {
  final double? width;
  final double height;
  final double horizontalPadding;
  final double verticalPadding;

  const ButtonDimensions({
    required this.width,
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
  });
}

class ButtonColors {
  final Color primary;
  final Color secondary;
  final Color primaryHover;
  final Color secondaryHover;
  final Color background;
  final Color onPrimary;
  final Color onSurface;

  const ButtonColors({
    required this.primary,
    required this.secondary,
    required this.primaryHover,
    required this.secondaryHover,
    required this.background,
    required this.onPrimary,
    required this.onSurface,
  });
}
