import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? errorText;

  final String? Function(String?)? validator;
  final int maxLines; // Added

  const InputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.errorText,

    this.validator,
    this.maxLines = 1, // Default to 1
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ),
        TextFormField(
          validator: widget.validator,
          controller: widget.controller,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,

          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: widget.maxLines, // Pass it here
          decoration: InputDecoration(
            contentPadding: widget.maxLines == 1 
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12) 
                : const EdgeInsets.all(16),
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: Theme.of(context).iconTheme.color?.withOpacity(0.6))
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 20,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            errorText: widget.errorText,
          ),
        ),
      ],
    );
  }
}
