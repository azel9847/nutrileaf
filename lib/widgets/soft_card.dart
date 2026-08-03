import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Reusable Soft UI / neumorphic-inspired card with double shadow effect.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final Border? border;

  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.color,
    this.gradient,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? AppColors.darkCard : AppColors.white);
    final shadows = isDark ? SoftShadows.darkRaised : SoftShadows.lightRaised;

    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(AppDimens.paddingMD),
      decoration: BoxDecoration(
        color: gradient == null ? bgColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}

/// A smaller, subtler version of SoftCard for list items.
class SoftCardSubtle extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  const SoftCardSubtle({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ?? (isDark ? AppColors.darkCard : AppColors.white);
    final shadows = isDark ? SoftShadows.darkSubtle : SoftShadows.lightSubtle;

    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(AppDimens.paddingMD),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}
