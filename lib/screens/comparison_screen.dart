import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../utils/comparison_data.dart';
import '../models/nutrient.dart';
import '../services/settings_service.dart';
import '../widgets/soft_card.dart';

/// Side-by-side comparison screen: Healthy Leaf vs Affected Leaf.
class ComparisonScreen extends StatelessWidget {
  final NutrientType nutrient;

  const ComparisonScreen({super.key, required this.nutrient});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;
    final comparison = ComparisonData.getComparison(nutrient);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.softBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: isDark
                            ? SoftShadows.darkSubtle
                            : SoftShadows.lightSubtle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.darkHeadingText
                            : AppColors.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('comparison_title', lang),
                          style: AppTextStyles.headline2.copyWith(
                            color: isDark
                                ? AppColors.darkHeadingText
                                : null,
                          ),
                        ),
                        Text(
                          nutrient.displayName,
                          style: AppTextStyles.caption.copyWith(
                            color: nutrient.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Side-by-side comparison cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Healthy side
                  Expanded(
                    child: _ComparisonCard(
                      title: AppStrings.get('healthy_leaf', lang),
                      icon: Icons.check_circle_rounded,
                      color: AppColors.successGreen,
                      traits: comparison.healthyTraits,
                      iconBg: AppColors.successGreen,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Affected side
                  Expanded(
                    child: _ComparisonCard(
                      title: AppStrings.get('affected_leaf', lang),
                      icon: Icons.warning_rounded,
                      color: nutrient.color,
                      traits: comparison.affectedTraits,
                      iconBg: nutrient.color,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Key differences
              Text(
                AppStrings.get('key_differences', lang),
                style: AppTextStyles.headline3.copyWith(
                  color: isDark ? AppColors.darkHeadingText : null,
                ),
              ),
              const SizedBox(height: 12),

              ...comparison.keyDifferences.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftCardSubtle(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: nutrient.color
                                  .withValues(alpha: isDark ? 0.15 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.compare_arrows_rounded,
                              size: 16,
                              color: nutrient.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              diff,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkBodyText
                                    : AppColors.darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 28),

              // Symptom highlights
              Text(
                'Symptom Highlights',
                style: AppTextStyles.headline3.copyWith(
                  color: isDark ? AppColors.darkHeadingText : null,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nutrient.symptomHighlights.map((symptom) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: nutrient.color
                          .withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusXL),
                      border: Border.all(
                        color: nutrient.color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      symptom,
                      style: AppTextStyles.caption.copyWith(
                        color: nutrient.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // Detailed descriptions
              Text(
                'Detailed Comparison',
                style: AppTextStyles.headline3.copyWith(
                  color: isDark ? AppColors.darkHeadingText : null,
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outlined,
                            color: AppColors.successGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'When Healthy',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nutrient.healthyDescription,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: isDark ? AppColors.darkBodyText : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.warning_outlined,
                            color: nutrient.color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'When Affected',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: nutrient.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nutrient.affectedDescription,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: isDark ? AppColors.darkBodyText : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> traits;
  final Color iconBg;
  final bool isDark;

  const _ComparisonCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.traits,
    required this.iconBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: color.withValues(alpha: isDark ? 0.08 : 0.04),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Header icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.bodyBold.copyWith(
              color: color,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Traits list
          ...traits.map((trait) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trait,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkBodyText
                              : AppColors.bodyText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
