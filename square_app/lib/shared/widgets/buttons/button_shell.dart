import 'package:flutter/material.dart';

/// Shared press-feedback wrapper for the button system: scales down slightly
/// on touch-down and back up on release/cancel. Used by every button variant
/// so press feedback is consistent and driven by real touch state (not a
/// build-time entrance animation).
class ButtonShell extends StatefulWidget {
  const ButtonShell({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 12,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool enabled;

  @override
  State<ButtonShell> createState() => _ButtonShellState();
}

class _ButtonShellState extends State<ButtonShell> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && widget.onTap != null;
    return AnimatedScale(
      scale: _pressed && canTap ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canTap ? widget.onTap : null,
          onTapDown: canTap ? (_) => _setPressed(true) : null,
          onTapUp: canTap ? (_) => _setPressed(false) : null,
          onTapCancel: canTap ? () => _setPressed(false) : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: widget.child,
        ),
      ),
    );
  }
}
