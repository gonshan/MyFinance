import 'package:flutter/material.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isPressed;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.padding,
    this.onTap,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    // В тёмной теме теней нет
    final List<BoxShadow> boxShadow;
    if (isDark) {
      boxShadow = <BoxShadow>[];
    } else {
      boxShadow = isPressed
          ? <BoxShadow>[]
          : [
              BoxShadow(
                color: const Color(0xFFD3DBE9).withValues(alpha: 0.7),
                offset: const Offset(8, 8),
                blurRadius: 16,
              ),
              BoxShadow(
                color: Colors.white,
                offset: const Offset(-8, -8),
                blurRadius: 16,
              ),
            ];
    }

    final border = isDark
        ? Border.all(color: Colors.white.withValues(alpha: 0.08))
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow,
          border: border,
        ),
        child: child,
      ),
    );
  }
}