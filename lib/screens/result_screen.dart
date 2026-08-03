import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../utils/fertilizer_data.dart';
import '../models/scan_result.dart';
import '../models/nutrient.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../widgets/soft_card.dart';
import '../widgets/nutrient_card.dart';
import '../widgets/recommendation_card.dart';
import 'comparison_screen.dart';

/// Results page showing detected deficiency, confidence, and recommendations.
class ResultScreen extends StatefulWidget {
  final ScanResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _ringAnimation = Tween<double>(begin: 0.0, end: widget.result.confidence)
        .animate(CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ringController.forward();
    });

    // Auto-save to history
    _autoSave();
  }

  Future<void> _autoSave() async {
    await HistoryService().saveScan(widget.result);
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final nutrient = result.detectedNutrient;
    final recommendation = FertilizerData.getRecommendation(nutrient);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.softBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button + title
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
                                'Scan Results',
                                style: AppTextStyles.headline2.copyWith(
                                  color: isDark
                                      ? AppColors.darkHeadingText
                                      : null,
                                ),
                              ),
                              Text(
                                '${result.cropType.displayName} • ${result.severityLabel}',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark ? AppColors.darkCaption : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Auto-saved badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen
                                .withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusXL),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.successGreen, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Saved',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Image preview card
                    _buildImageCard(result, isDark),

                    const SizedBox(height: 20),

                    // Detection badge
                    _buildDetectionBadge(nutrient, isDark),

                    // Low confidence warning
                    if (result.confidence < 0.6) ...[
                      const SizedBox(height: 12),
                      _buildLowConfidenceWarning(isDark, lang),
                    ],

                    const SizedBox(height: 24),

                    // Confidence ring
                    _buildConfidenceSection(result, isDark, lang),

                    const SizedBox(height: 28),

                    // All predictions
                    _buildAllPredictions(result, isDark, lang),

                    const SizedBox(height: 28),

                    // Description
                    _buildDescriptionSection(nutrient, isDark),

                    const SizedBox(height: 28),

                    // Fertilizer recommendations
                    Text(
                      AppStrings.get('treatment_plan', lang),
                      style: AppTextStyles.headline3.copyWith(
                        color: isDark ? AppColors.darkHeadingText : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RecommendationCard(recommendation: recommendation),

                    const SizedBox(height: 28),

                    // Symptoms
                    _buildSymptomsSection(recommendation, isDark, lang),

                    const SizedBox(height: 28),

                    // Action buttons
                    _buildActionButtons(isDark, lang, nutrient),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(ScanResult result, bool isDark) {
    return SoftCard(
      padding: EdgeInsets.zero,
      borderRadius: AppDimens.radiusMD,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: _buildHeaderImage(result.imagePath, isDark),
        ),
      ),
    );
  }

  Widget _buildHeaderImage(String imagePath, bool isDark) {
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      decoration: const BoxDecoration(color: AppColors.primaryGreen),
      child: const Icon(Icons.eco_rounded, size: 80, color: AppColors.white),
    );
  }

  Widget _buildDetectionBadge(NutrientType nutrient, bool isDark) {
    return SoftCard(
      color: nutrient.color.withValues(alpha: isDark ? 0.15 : 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: nutrient.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(nutrient.icon, color: nutrient.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nutrient == NutrientType.healthy
                      ? 'Healthy Plant ✨'
                      : '${nutrient.displayName} Deficiency',
                  style: AppTextStyles.subtitle.copyWith(color: nutrient.color),
                ),
                const SizedBox(height: 2),
                Text(
                  nutrient.description,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkCaption : null,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowConfidenceWarning(bool isDark, String lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusSM),
        border: Border.all(
          color: AppColors.warningAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warningAmber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.get('low_confidence', lang),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warningAmber,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceSection(ScanResult result, bool isDark, String lang) {
    return Center(
      child: Column(
        children: [
          Text(
            AppStrings.get('confidence_level', lang),
            style: AppTextStyles.headline3.copyWith(
              color: isDark ? AppColors.darkHeadingText : null,
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 150,
              height: 150,
              child: AnimatedBuilder(
                animation: _ringAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfidenceRingPainter(
                      progress: _ringAnimation.value,
                      color: result.detectedNutrient.color,
                      isDark: isDark,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_ringAnimation.value * 100).toStringAsFixed(1)}%',
                            style: AppTextStyles.percentageLarge.copyWith(
                              color: result.detectedNutrient.color,
                            ),
                          ),
                          Text(
                            'confidence',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkCaption : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPredictions(ScanResult result, bool isDark, String lang) {
    final sorted = result.sortedPredictions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('all_predictions', lang),
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : null,
          ),
        ),
        const SizedBox(height: 12),
        ...sorted.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NutrientCard(
                nutrient: entry.key,
                confidence: entry.value,
                isDetected: entry.key == result.detectedNutrient,
              ),
            )),
      ],
    );
  }

  Widget _buildDescriptionSection(NutrientType nutrient, bool isDark) {
    return SoftCard(
      color: nutrient.color.withValues(alpha: isDark ? 0.1 : 0.04),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: nutrient.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About ${nutrient.displayName}',
                  style: AppTextStyles.bodyBold.copyWith(color: nutrient.color),
                ),
                const SizedBox(height: 4),
                Text(
                  nutrient.description,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: isDark ? AppColors.darkBodyText : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsSection(
      FertilizerRecommendation recommendation, bool isDark, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('common_symptoms', lang),
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : null,
          ),
        ),
        const SizedBox(height: 12),
        ...recommendation.symptoms.map((symptom) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: recommendation.nutrient.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      symptom,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: isDark ? AppColors.darkBodyText : null,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, String lang, NutrientType nutrient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compare with healthy
        if (nutrient != NutrientType.healthy)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ComparisonScreen(nutrient: nutrient),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                  boxShadow: SoftShadows.colorGlow(AppColors.primaryGreen),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.compare_rounded,
                        color: AppColors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppStrings.get('compare_healthy', lang),
                        style: AppTextStyles.button,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Scan again
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusLG),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.primaryGreen,
              ),
              boxShadow: isDark ? SoftShadows.darkSubtle : SoftShadows.lightSubtle,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppStrings.get('scan_again', lang),
                    style: AppTextStyles.button.copyWith(
                      color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Custom Painter ──────────────────────────────────────────────────────────

class _ConfidenceRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _ConfidenceRingPainter({
    required this.progress,
    required this.color,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.15 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConfidenceRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
