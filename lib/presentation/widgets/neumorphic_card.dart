import 'package:flutter/material.dart';
import '../../core/theme.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.shadowDark.withOpacity(0.7),
                    offset: const Offset(8, 8),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    color: AppColors.shadowLight,
                    offset: const Offset(-8, -8),
                    blurRadius: 16,
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

