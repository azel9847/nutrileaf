import 'package:flutter/material.dart';
import '../models/nutrient.dart';
import '../utils/constants.dart';

/// Soft UI card displaying a nutrient type and detection status.
class NutrientCard extends StatelessWidget {
  final NutrientType nutrient;
  final bool isDetected;

  const NutrientCard({
    super.key,
    required this.nutrient,
    this.isDetected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppDimens.paddingMD),
      decoration: BoxDecoration(
        color: isDetected
            ? nutrient.color.withValues(alpha: isDark ? 0.12 : 0.06)
            : (isDark ? AppColors.darkCard : AppColors.white),
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        boxShadow: isDetected
            ? SoftShadows.colorGlow(nutrient.color)
            : (isDark ? SoftShadows.darkSubtle : SoftShadows.lightSubtle),
      ),
      child: Row(
        children: [
          // Nutrient icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: nutrient.color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusSM),
            ),
            child: Center(
              child: Text(
                nutrient.shortName,
                style: AppTextStyles.subtitle.copyWith(
                  color: nutrient.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.paddingMD),

          // Name and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nutrient.displayName,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isDetected
                        ? nutrient.color
                        : (isDark ? AppColors.darkHeadingText : AppColors.bodyText),
                  ),
                ),
                if (isDetected) ...[
                  const SizedBox(height: 2),
                  Text(
                    nutrient.name.toLowerCase() == 'healthy' 
                        ? 'Plant is in good condition' 
                        : 'Deficiency detected',
                    style: AppTextStyles.caption.copyWith(
                      color: nutrient.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

        ],
      ),
    );
  }
}
