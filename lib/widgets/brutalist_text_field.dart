import 'package:flutter/material.dart';
import '../config/theme.dart';

class BrutalistTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;

  const BrutalistTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
  });

  @override
  State<BrutalistTextField> createState() => _BrutalistTextFieldState();
}

class _BrutalistTextFieldState extends State<BrutalistTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _isFocused ? AppTheme.neonGreen : AppTheme.secondaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Text Field Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _errorText != null
                  ? AppTheme.errorColor
                  : _isFocused
                      ? AppTheme.neonGreen
                      : AppTheme.darkBorder,
              width: 2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: _errorText != null
                          ? AppTheme.errorColor
                          : AppTheme.neonGreen,
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: AppTheme.primaryBlack,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: widget.enabled ? AppTheme.primaryText : AppTheme.mutedText,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? widget.label,
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mutedText,
                fontFamily: 'Inter',
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              errorStyle: const TextStyle(height: 0), // Hide default error text
            ),
            validator: (value) {
              final error = widget.validator?.call(value);
              setState(() {
                _errorText = error;
              });
              return error;
            },
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
          ),
        ),
        
        // Error Text
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}