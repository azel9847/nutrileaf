import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// Pill-shaped chip for crop type selection with soft styling.
class CropChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const CropChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? SoftShadows.colorGlow(color)
              : (isDark ? SoftShadows.darkSubtle : SoftShadows.lightSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? color
                  : (isDark ? AppColors.darkCaption : AppColors.caption),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? color
                    : (isDark ? AppColors.darkBodyText : AppColors.bodyText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
