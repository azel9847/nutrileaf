import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../models/scan_result.dart';
import '../models/nutrient.dart';

/// Compact crop card used by the horizontal selector on the scan screen.
///
/// Displays:
///   - Material botanical icon
///   - Filipino crop name (bold)
///   - English name (caption)
///   - Nutrient hint (which nutrients are checked)
///
/// Animated selection state: colored border glow + subtle scale.
class CropSelectionCard extends StatelessWidget {
  final CropType crop;
  final bool isSelected;
  final VoidCallback onTap;

  const CropSelectionCard({
    super.key,
    required this.crop,
    required this.isSelected,
    required this.onTap,
  });

  /// Build a short nutrient hint string, e.g. "N · P · K · Ca · Mg"
  String _buildNutrientHint() {
    return crop.relevantNutrients
        .where((n) => n != NutrientType.healthy)
        .map((n) => n.shortName)
        .join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cropColor = crop.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? cropColor.withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          border: Border.all(
            color: isSelected
                ? cropColor.withValues(alpha: 0.7)
                : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cropColor.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : (isDark ? SoftShadows.darkSubtle : SoftShadows.lightSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(crop.icon, size: 21, color: cropColor),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _buildNutrientHint(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: isDark ? AppColors.darkCaption : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                crop.displayName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xFF1B5E20)
                      : (isDark ? AppColors.darkHeadingText : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                crop.englishName,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isDark ? AppColors.darkCaption : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
