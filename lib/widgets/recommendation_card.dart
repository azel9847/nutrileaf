import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/fertilizer_data.dart';
import '../models/nutrient.dart';

/// Expandable soft card showing fertilizer recommendation details.
class RecommendationCard extends StatefulWidget {
  final FertilizerRecommendation recommendation;

  const RecommendationCard({
    super.key,
    required this.recommendation,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final color = rec.nutrient.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        boxShadow: isDark ? SoftShadows.darkRaised : SoftShadows.lightRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.paddingMD),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppDimens.radiusMD),
                  topRight: const Radius.circular(AppDimens.radiusMD),
                  bottomLeft:
                      Radius.circular(_isExpanded ? 0 : AppDimens.radiusMD),
                  bottomRight:
                      Radius.circular(_isExpanded ? 0 : AppDimens.radiusMD),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_florist_rounded, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fertilizer Recommendation',
                          style: AppTextStyles.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rec.fertilizerName,
                          style: AppTextStyles.subtitle.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.all(AppDimens.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Details grid
                  _DetailRow(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Alternative',
                    value: rec.alternativeName,
                    color: color,
                  ),
                  _DetailRow(
                    icon: Icons.scale_rounded,
                    label: 'Rate',
                    value: rec.applicationRate,
                    color: color,
                  ),
                  _DetailRow(
                    icon: Icons.agriculture_rounded,
                    label: 'Method',
                    value: rec.applicationMethod,
                    color: color,
                  ),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Timing',
                    value: rec.timing,
                    color: color,
                  ),
                  _DetailRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Severity',
                    value: rec.severity,
                    color: color,
                  ),

                  const SizedBox(height: AppDimens.paddingMD),

                  // Tips section
                  Text(
                    '💡 Tips for Farmers',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...rec.tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tip,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDark ? AppColors.darkBodyText : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                  // Safety notes section
                  if (rec.safetyNotes.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.paddingMD),
                    Text(
                      '🛡️ Safety Notes',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...rec.safetyNotes.map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: AppColors.warningAmber,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  note,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: isDark ? AppColors.darkBodyText : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkCaption : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: isDark ? AppColors.darkBodyText : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
