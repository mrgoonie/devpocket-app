import 'package:flutter/material.dart';
import '../config/theme.dart';

class BrutalistButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? shadowOffset;
  final bool isLoading;
  final EdgeInsets? padding;
  final double? borderRadius;

  const BrutalistButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.shadowOffset,
    this.isLoading = false,
    this.padding,
    this.borderRadius,
  });

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppTheme.neonGreen;
    final foregroundColor = widget.foregroundColor ?? AppTheme.primaryBlack;
    final borderColor = widget.borderColor ?? AppTheme.primaryBlack;
    final borderWidth = widget.borderWidth ?? 3.0;
    final shadowOffset = widget.shadowOffset ?? 4.0;
    final padding = widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    final borderRadius = widget.borderRadius ?? 8.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(
                _isPressed ? shadowOffset / 2 : 0,
                _isPressed ? shadowOffset / 2 : 0,
                0,
              ),
              decoration: BoxDecoration(
                color: widget.onPressed == null || widget.isLoading
                    ? backgroundColor.withValues(alpha: 0.5)
                    : backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: borderColor,
                    offset: Offset(
                      _isPressed ? shadowOffset / 2 : shadowOffset,
                      _isPressed ? shadowOffset / 2 : shadowOffset,
                    ),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: padding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isLoading) ...[
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}