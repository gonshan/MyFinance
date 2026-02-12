import 'package:flutter/material.dart';
import '../../core/theme.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isPressed; // Для анимации нажатия (в будущем)

  const NeumorphicCard({
    Key? key,
    required this.child,
    this.borderRadius = 20.0,
    this.padding,
    this.onTap,
    this.isPressed = false,
  }) : super(key: key);

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
              ? [] // Если нажата — убираем тени (эффект вдавливания реализуем позже)
              : [
                  // Тень справа-снизу (темная)
                  BoxShadow(
                    color: AppColors.shadowDark.withOpacity(0.7),
                    offset: const Offset(8, 8),
                    blurRadius: 16,
                  ),
                  // Тень слева-сверху (светлая - блик)
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

//Один из самых важных файлов, это дизайн. Он создает Soft UI с двумя тенями