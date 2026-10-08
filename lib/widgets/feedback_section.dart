import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../models/scan_result.dart';
import '../models/nutrient.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import 'soft_card.dart';

/// Multi-step feedback widget for the results screen.
///
/// Allows users to confirm / reject the AI diagnosis and optionally provide
/// a correction and free-text comments. Submissions are persisted to
/// Supabase (or queued locally when offline).
class FeedbackSection extends StatefulWidget {
  final ScanResult result;

  const FeedbackSection({super.key, required this.result});

  @override
  State<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection>
    with TickerProviderStateMixin {
  _FeedbackStep _step = _FeedbackStep.initial;
  bool? _isCorrect;
  NutrientType? _userCorrection;
  final _commentsController = TextEditingController();
  bool _isSubmitting = false;

  late AnimationController _expandController;
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _checkAlreadySubmitted();

    // Entrance animation — delayed so it's visible after scroll
    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _entranceController.forward(); });
  }

  Future<void> _checkAlreadySubmitted() async {
    final submitted =
        await FeedbackService().hasSubmittedFeedback(widget.result.id);
    if (submitted && mounted) {
      setState(() {
        _step = _FeedbackStep.submitted;
      });
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _entranceController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> _submitFeedbackToSupabase({
    required bool isCorrect,
    String? correctedVegetable,
    String? correctedDeficiency,
    String? notes,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      await supabase.from('diagnosis_feedback').insert({
        'diagnosis_id': widget.result.id,
        'user_id': ?userId,
        'is_accurate': isCorrect,
        if (correctedVegetable != null && correctedVegetable.isNotEmpty) 
          'corrected_vegetable': correctedVegetable,
        if (correctedDeficiency != null && correctedDeficiency.isNotEmpty) 
          'corrected_deficiency': correctedDeficiency,
        if (notes != null && notes.isNotEmpty) 
          'feedback_notes': notes,
      });
      await FeedbackService().markFeedbackSubmitted(widget.result.id);
    } catch (e) {
      debugPrint('Error inserting diagnosis_feedback: $e');
    }
  }

  Future<void> _onAccuracySelected(bool isCorrect) async {
    if (isCorrect) {
      // 1. Silent insert
      await _submitFeedbackToSupabase(isCorrect: true);
      if (mounted) {
        setState(() => _step = _FeedbackStep.submitted);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } else {
      // 2. Show dialog
      String? vegetable;
      String? deficiency;
      String? notes;

      final submitted = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMD)),
            title: Text(
              'Correct Diagnosis',
              style: AppTextStyles.subtitle.copyWith(
                color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Correct Vegetable (optional)',
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkCaption : AppColors.caption,
                      ),
                    ),
                    style: AppTextStyles.body.copyWith(
                      color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
                    ),
                    onChanged: (v) => vegetable = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Correct Deficiency (optional)',
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkCaption : AppColors.caption,
                      ),
                    ),
                    style: AppTextStyles.body.copyWith(
                      color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
                    ),
                    onChanged: (v) => deficiency = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkCaption : AppColors.caption,
                      ),
                    ),
                    style: AppTextStyles.body.copyWith(
                      color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
                    ),
                    onChanged: (v) => notes = v,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel', style: AppTextStyles.bodyBold.copyWith(
                  color: isDark ? AppColors.darkCaption : AppColors.caption,
                )),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );

      if (submitted == true) {
        await _submitFeedbackToSupabase(
          isCorrect: false,
          correctedVegetable: vegetable,
          correctedDeficiency: deficiency,
          notes: notes,
        );
        if (mounted) {
          setState(() => _step = _FeedbackStep.submitted);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your feedback!')),
          );
        }
      }
    }
  }

  void _onCorrectionSelected(NutrientType nutrient) {
    setState(() {
      _userCorrection = nutrient;
      _step = _FeedbackStep.comments;
    });
  }

  Future<void> _submit() async {
    if (_isCorrect == null) return;

    setState(() => _isSubmitting = true);

    final feedback = UserFeedback(
      scanId: widget.result.id,
      userId: AuthService().currentUser?.id,
      isCorrect: _isCorrect!,
      userCorrection: _userCorrection?.name,
      comments: _commentsController.text.trim().isEmpty
          ? null
          : _commentsController.text.trim(),
      originalPrediction: widget.result.detectedNutrient.name,
      confidence: widget.result.confidence,
      cropType: widget.result.cropType.name,
    );

    final result = await FeedbackService().submitFeedback(feedback);
    await FeedbackService().markFeedbackSubmitted(widget.result.id);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _step =
            result.success ? _FeedbackStep.submitted : _FeedbackStep.error;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;

    return FadeTransition(
      opacity: _entranceFade,
      child: SlideTransition(
        position: _entranceSlide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(
                  Icons.rate_review_rounded,
                  color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.get('help_improve', lang),
                  style: AppTextStyles.headline3.copyWith(
                    color: isDark ? AppColors.darkHeadingText : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content based on step
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildCurrentStep(isDark, lang),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark, String lang) {
    switch (_step) {
      case _FeedbackStep.initial:
        return _buildAccuracyPrompt(isDark, lang);
      case _FeedbackStep.correction:
        return _buildCorrectionStep(isDark);
      case _FeedbackStep.comments:
        return _buildCommentsStep(isDark);
      case _FeedbackStep.submitted:
        return _buildSuccessState(isDark);
      case _FeedbackStep.error:
        return _buildErrorState(isDark);
    }
  }

  // ── Step 1: Accuracy prompt ────────────────────────────────────────────

  Widget _buildAccuracyPrompt(bool isDark, String lang) {
    return SoftCard(
      key: const ValueKey('accuracy'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            AppStrings.get('was_accurate', lang),
            style: AppTextStyles.subtitle.copyWith(
              color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your feedback helps improve our AI model',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkCaption : null,
            ),
          ),
          const SizedBox(height: 18),

          // Pill-shaped animated feedback buttons
          Row(
            children: [
              Expanded(
                child: _AnimatedFeedbackPill(
                  icon: Icons.thumb_up_rounded,
                  label: AppStrings.get('yes_correct', lang),
                  color: AppColors.successGreen,
                  isDark: isDark,
                  onTap: () => _onAccuracySelected(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnimatedFeedbackPill(
                  icon: Icons.thumb_down_rounded,
                  label: AppStrings.get('no_incorrect', lang),
                  color: AppColors.dangerRed,
                  isDark: isDark,
                  onTap: () => _onAccuracySelected(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 2: Correction selector ────────────────────────────────────────

  Widget _buildCorrectionStep(bool isDark) {
    return SoftCard(
      key: const ValueKey('correction'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_rounded,
                color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'What\'s the correct diagnosis?',
                  style: AppTextStyles.subtitle.copyWith(
                    color:
                        isDark ? AppColors.darkHeadingText : AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NutrientType.values.map((nutrient) {
              final isSelected = _userCorrection == nutrient;
              return GestureDetector(
                onTap: () => _onCorrectionSelected(nutrient),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? nutrient.color.withValues(alpha: isDark ? 0.25 : 0.12)
                        : (isDark
                            ? AppColors.darkSurface
                            : AppColors.paleGreen.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                    border: Border.all(
                      color: isSelected
                          ? nutrient.color
                          : (isDark
                              ? AppColors.darkDivider
                              : AppColors.divider),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(nutrient.icon,
                          size: 16,
                          color: isSelected
                              ? nutrient.color
                              : (isDark
                                  ? AppColors.darkBodyText
                                  : AppColors.bodyText)),
                      const SizedBox(width: 6),
                      Text(
                        nutrient.displayName,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? nutrient.color
                              : (isDark
                                  ? AppColors.darkBodyText
                                  : AppColors.bodyText),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Comments + Submit ──────────────────────────────────────────

  Widget _buildCommentsStep(bool isDark) {
    return SoftCard(
      key: const ValueKey('comments'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show selected accuracy and correction summary
          _buildSelectionSummary(isDark),
          const SizedBox(height: 14),

          // Comments field
          Text(
            'Any additional notes? (optional)',
            style: AppTextStyles.bodyBold.copyWith(
              color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.paleGreen.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppDimens.radiusSM),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
            child: TextField(
              controller: _commentsController,
              maxLines: 3,
              maxLength: 500,
              style: AppTextStyles.body.copyWith(
                color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
              ),
              decoration: InputDecoration(
                hintText: 'Share your observations...',
                hintStyle: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkCaption : AppColors.caption,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkCaption : null,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isSubmitting ? null : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isSubmitting
                      ? (isDark ? AppColors.darkSurface : AppColors.paleGreen)
                      : AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                  boxShadow: _isSubmitting
                      ? null
                      : SoftShadows.colorGlow(AppColors.primaryGreen),
                ),
                child: Center(
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? AppColors.leafGreen
                                  : AppColors.primaryGreen,
                            ),
                          ),
                        )
                      : Text('Submit Feedback', style: AppTextStyles.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (_isCorrect == true ? AppColors.successGreen : AppColors.dangerRed)
            .withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(AppDimens.radiusSM),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect == true
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color:
                _isCorrect == true ? AppColors.successGreen : AppColors.dangerRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isCorrect == true
                  ? 'Marked as correct'
                  : _userCorrection != null
                      ? 'Corrected to: ${_userCorrection!.displayName}'
                      : 'Marked as incorrect',
              style: AppTextStyles.caption.copyWith(
                color: _isCorrect == true
                    ? AppColors.successGreen
                    : AppColors.dangerRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _step = _FeedbackStep.initial;
                _isCorrect = null;
                _userCorrection = null;
                _commentsController.clear();
              });
              _expandController.reverse();
            },
            child: Text(
              'Change',
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success state ──────────────────────────────────────────────────────

  Widget _buildSuccessState(bool isDark) {
    return SoftCard(
      key: const ValueKey('success'),
      color: AppColors.successGreen.withValues(alpha: isDark ? 0.1 : 0.05),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.successGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thank you! 🌿',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.successGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your feedback helps improve our AI for everyone.',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkCaption : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────

  Widget _buildErrorState(bool isDark) {
    return SoftCard(
      key: const ValueKey('error'),
      color: AppColors.dangerRed.withValues(alpha: isDark ? 0.1 : 0.05),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.dangerRed, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Feedback saved locally. It will sync when you\'re back online.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.dangerRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                ),
                child: Center(
                  child: Text(
                    'Retry',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.dangerRed,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Feedback Pill (Step 1 accuracy prompt buttons) ─────────────────

class _AnimatedFeedbackPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedFeedbackPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedFeedbackPill> createState() => _AnimatedFeedbackPillState();
}

class _AnimatedFeedbackPillState extends State<_AnimatedFeedbackPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    setState(() => _pressed = true);
    await _pressController.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    await _pressController.reverse();
    if (mounted) setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: _pressed
                ? widget.color
                : widget.color.withValues(alpha: widget.isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(AppDimens.radiusLG),
            border: Border.all(
              color: widget.color.withValues(alpha: _pressed ? 1.0 : 0.35),
              width: 1.5,
            ),
            boxShadow: _pressed
                ? SoftShadows.colorGlow(widget.color)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: _pressed ? AppColors.white : widget.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _pressed ? AppColors.white : widget.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Internal step enum ──────────────────────────────────────────────────────

enum _FeedbackStep {
  initial,
  correction,
  comments,
  submitted,
  error,
}

