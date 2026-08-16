import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class InputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? errorText;
  final String? helperText;

  final String? Function(String?)? validator;
  final int maxLines;

  const InputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.errorText,
    this.helperText,
    this.validator,
    this.maxLines = 1,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscureText = true;
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
          child: Text(
            widget.label,
            style: AppTypography.label.copyWith(color: inkMuted),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _focused ? sunken : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? AppColors.negative : (_focused ? ink : line),
              width: hasError || _focused ? 1.4 : 1,
            ),
          ),
          child: TextFormField(
            focusNode: _focusNode,
            validator: widget.validator,
            controller: widget.controller,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            cursorColor: ink,
            style: AppTypography.body.copyWith(color: ink, fontWeight: FontWeight.w500),
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: widget.maxLines == 1
                  ? const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md)
                  : const EdgeInsets.all(AppSpacing.lg),
              hintText: widget.hint,
              hintStyle: AppTypography.body.copyWith(color: inkFaint),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, size: 20, color: inkFaint)
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: inkFaint,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    )
                  : null,
              // Error text is rendered below via AnimatedSwitcher instead —
              // the field's own border already communicates error state.
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          child: hasError
              ? Padding(
                  key: const ValueKey('error'),
                  padding: const EdgeInsets.only(left: 2, top: AppSpacing.xs),
                  child: Text(widget.errorText!, style: AppTypography.errorText.copyWith(color: AppColors.negative)),
                )
              : widget.helperText != null
                  ? Padding(
                      key: const ValueKey('helper'),
                      padding: const EdgeInsets.only(left: 2, top: AppSpacing.xs),
                      child: Text(widget.helperText!, style: AppTypography.helper.copyWith(color: inkFaint)),
                    )
                  : const SizedBox.shrink(key: ValueKey('none')),
        ),
      ],
    );
  }
}
