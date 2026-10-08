import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/agronomic_recommendations.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../utils/fertilizer_data.dart';
import '../models/scan_result.dart';
import '../models/nutrient.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../widgets/soft_card.dart';
import '../widgets/feedback_section.dart';

/// Results page showing detected deficiency, confidence, and recommendations.
class ResultScreen extends StatefulWidget {
  final ScanResult result;

  /// When [fromHistory] is true the screen is opened from the Scan History
  /// list and will NOT trigger an auto-save (which would inflate the counter).
  final bool fromHistory;

  const ResultScreen({
    super.key,
    required this.result,
    this.fromHistory = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    // Only auto-save (and therefore increment the scan counter) for brand-new
    // scans. History reads must NOT trigger another save.
    if (!widget.fromHistory) {
      _autoSave();
    }

    // Show low-confidence retake dialog if needed
    if (widget.result.isValidLeaf && widget.result.confidence < 0.55) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showRetakeDialog();
      });
    }
  }

  Future<void> _autoSave() async {
    await HistoryService().saveScan(widget.result);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final nutrient = result.detectedNutrient;
    final recommendation = FertilizerData.getRecommendation(
      nutrient,
      crop: result.cropType,
    );
    final agronomicRecommendation = AgronomicRecommendations.forCondition(
      result.cropType,
      nutrient,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;

    if (!result.isValidLeaf) {
      return _buildInvalidLeafScreen(result, isDark);
    }

    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
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
                              // Crop context badge
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    result.cropType.emoji,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    result.cropType.displayName,
                                    style: AppTextStyles.caption.copyWith(
                                      color: result.cropType.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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

                    const SizedBox(height: 16),

                    // Single-label diagnosis: crop + deficiency, one bar each
                    _buildDiagnosisSummary(result, isDark, lang),

                    const SizedBox(height: 20),

                    // Low confidence — show modal dialog on first render
                    if (result.confidence < 0.55) ...[
                      _buildLowConfidenceWarning(isDark, lang),
                      const SizedBox(height: 20),
                    ],

                    const SizedBox(height: 8),

                    // Description
                    _buildDescriptionSection(nutrient, isDark),

                    const SizedBox(height: 28),

                    _buildTreatmentPlan(agronomicRecommendation, isDark, lang),

                    const SizedBox(height: 28),

                    // Symptoms
                    _buildSymptomsSection(recommendation, isDark, lang),

                    const SizedBox(height: 28),

                    // User feedback
                    FeedbackSection(result: result),

                    const SizedBox(height: 28),

                    // Action buttons
                    _buildActionButtons(isDark, lang),

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

  Widget _buildInvalidLeafScreen(ScanResult result, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.softBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scan Results',
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : null,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCard(result, isDark),
              const SizedBox(height: 24),
              SoftCard(
                color: AppColors.warningAmber.withValues(alpha: isDark ? 0.14 : 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warningAmber,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Invalid Leaf Image',
                            style: AppTextStyles.headline3.copyWith(
                              color: AppColors.warningAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.errorMessage ??
                          'Low Confidence / Invalid Leaf',
                      style: AppTextStyles.body.copyWith(
                        color: isDark ? AppColors.darkBodyText : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.document_scanner_rounded),
                  label: const Text('Scan Another Leaf'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(ScanResult result, bool isDark) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(isDark),
      child: SoftCard(
        padding: EdgeInsets.zero,
        borderRadius: AppDimens.radiusMD,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          child: Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: _buildHeaderImage(result.imagePath, isDark),
              ),
              // Zoom hint overlay
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded,
                          size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Tap to zoom',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a full-screen dialog with an [InteractiveViewer] for pinch-to-zoom.
  void _openFullScreenImage(bool isDark) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Zoomable image
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: _buildHeaderImage(
                        widget.result.imagePath, isDark),
                  ),
                ),
                // Close button
                Positioned(
                  top: MediaQuery.of(ctx).padding.top + 12,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderImage(String imagePath, bool isDark) {
    // 1. In-memory bytes — fresh scan on any platform.
    final bytes = widget.result.imageBytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }

    // 2. Remote URL — image stored in Supabase/CDN (history items).
    final url = widget.result.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.primaryGreen.withValues(alpha: 0.15),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            _buildImagePlaceholder(),
      );
    }

    // 3. Local file path — written by the scan service on mobile.
    if (!kIsWeb && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    // 4. Branded placeholder for older history items without persisted media.
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen,
            AppColors.leafGreen,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.eco_rounded, size: 80, color: AppColors.white),
      ),
    );
  }

  Widget _buildLowConfidenceWarning(bool isDark, String lang) {
    return GestureDetector(
      onTap: _showRetakeDialog,
      child: Container(
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
                  fontWeight:  FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningAmber,
                borderRadius: BorderRadius.circular(AppDimens.radiusXL),
              ),
              child: Text(
                AppStrings.get('retake_action', lang),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRetakeDialog() {
    final lang = context.read<SettingsService>().language;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.warningAmber, size: 24),
            const SizedBox(width: 10),
            Text(
              'Low Confidence',
              style: AppTextStyles.subtitle.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkHeadingText
                    : AppColors.darkText,
              ),
            ),
          ],
        ),
        content: Text(
          AppStrings.get('retake_low_confidence', lang),
          style: AppTextStyles.body.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBodyText
                : AppColors.bodyText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(
              AppStrings.get('continue_anyway', lang),
              style: AppTextStyles.bodyBold.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkCaption
                    : AppColors.caption,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningAmber,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusLG),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Pop result screen back to scan
            },
            child: Text(
              AppStrings.get('retake_action', lang),
              style: AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }

  /// Primary single-label diagnosis: the identified crop and the diagnosed
  /// condition, each with exactly one confidence bar.
  Widget _buildDiagnosisSummary(ScanResult result, bool isDark, String lang) {
    final crop = result.cropType;
    final nutrient = result.detectedNutrient;
    final isHealthy = nutrient == NutrientType.healthy;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.paddingMD),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        boxShadow: SoftShadows.colorGlow(nutrient.color),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.get('detected_condition', lang),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkCaption : AppColors.caption,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),

          // Diagnosed condition (hero)
          Text(
            nutrient.displayName,
            textAlign: TextAlign.center,
            style: AppTextStyles.headline2.copyWith(color: nutrient.color),
          ),
          const SizedBox(height: 4),
          Text(
            isHealthy ? 'Plant is in good condition' : 'Deficiency detected',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: nutrient.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _singleConfidenceRow(
            label: 'Diagnosis confidence',
            value: result.confidence,
            color: nutrient.color,
            isDark: isDark,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Divider(
              height: 1,
              color: (isDark ? AppColors.darkCaption : AppColors.caption)
                  .withValues(alpha: 0.2),
            ),
          ),

          // Identified crop
          Text(
            '${crop.emoji}  ${crop.displayName} (${crop.englishName})',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold.copyWith(
              color: crop.color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _singleConfidenceRow(
            label: 'Crop confidence',
            value: result.vegetableConfidence,
            color: crop.color,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// One labelled, animated confidence bar with its percentage.
  Widget _singleConfidenceRow({
    required String label,
    required double value,
    required Color color,
    required bool isDark,
  }) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    final pct = (clamped * 100).toStringAsFixed(1);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.caption;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: captionColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$pct%',
              style: AppTextStyles.bodyBold.copyWith(color: color, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: clamped),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Container(
            height: 10,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.softBackground,
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.7), color],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentPlan(
    AgronomicRecommendation recommendation,
    bool isDark,
    String lang,
  ) {
    final Color accent = widget.result.detectedNutrient.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('treatment_plan', lang),
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : null,
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          color: accent.withValues(alpha: isDark ? 0.10 : 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.title,
                style: AppTextStyles.subtitle.copyWith(color: accent),
              ),
              const SizedBox(height: 12),
              ...recommendation.actionSteps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 18, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            color: isDark ? AppColors.darkBodyText : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reference: ${recommendation.citation}',
                style: AppTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkCaption : AppColors.caption,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildActionButtons(bool isDark, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scan again
        Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(AppDimens.radiusXL),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.leafGreen.withValues(alpha: 0.12)
                      : AppColors.primaryGreen.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                  border: Border.all(
                    color: isDark
                        ? AppColors.leafGreen.withValues(alpha: 0.5)
                        : AppColors.primaryGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.document_scanner_rounded,
                      size: 18,
                      color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      AppStrings.get('scan_again', lang),
                      style: AppTextStyles.button.copyWith(
                        fontSize: 13,
                        color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

