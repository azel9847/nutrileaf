import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../services/settings_service.dart';

/// Pre-Scan Guidance modal — shown before the user scans to educate them
/// on capturing an optimal leaf image.
///
/// Display via:
/// ```dart
/// await showScanTipsModal(context);
/// ```
Future<void> showScanTipsModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _ScanTipsSheet(),
  );
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class _ScanTipsSheet extends StatefulWidget {
  const _ScanTipsSheet();

  @override
  State<_ScanTipsSheet> createState() => _ScanTipsSheetState();
}

class _ScanTipsSheetState extends State<_ScanTipsSheet>
    with SingleTickerProviderStateMixin {
  bool _dontShowAgain = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onGotIt() async {
    if (_dontShowAgain) {
      await context.read<SettingsService>().setShowScanTips(false);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _buildSheet(isDark, lang),
      ),
    );
  }

  Widget _buildSheet(bool isDark, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusMD + 8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            _DragHandle(isDark: isDark),

            // Header
            _buildHeader(isDark, lang),

            // Tips list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
              child: Column(
                children: [
                  _TipRow(
                    icon: Icons.center_focus_strong_rounded,
                    iconColor: AppColors.primaryGreen,
                    title: AppStrings.get('tip_clear_focus_title', lang),
                    description: AppStrings.get('tip_clear_focus_desc', lang),
                    isDark: isDark,
                  ),
                  _TipRow(
                    icon: Icons.eco_rounded,
                    iconColor: AppColors.leafGreen,
                    title: AppStrings.get('tip_one_leaf_title', lang),
                    description: AppStrings.get('tip_one_leaf_desc', lang),
                    isDark: isDark,
                  ),
                  _TipRow(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: AppColors.warningAmber,
                    title: AppStrings.get('tip_good_lighting_title', lang),
                    description: AppStrings.get('tip_good_lighting_desc', lang),
                    isDark: isDark,
                  ),
                  _TipRow(
                    icon: Icons.grass_rounded,
                    iconColor: AppColors.terracotta,
                    title: AppStrings.get('tip_correct_crop_title', lang),
                    description: AppStrings.get('tip_correct_crop_desc', lang),
                    isDark: isDark,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Don't show again row
            _buildDontShowRow(isDark, lang),

            const SizedBox(height: 16),

            // CTA button
            _buildCTAButton(isDark, lang),

            const SizedBox(height: AppDimens.paddingMD),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, String lang) {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Decorative icon badge
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.18 : 0.10),
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.25 : 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tips_and_updates_rounded,
              color: AppColors.primaryGreen,
              size: 32,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          AppStrings.get('scan_tips_modal_title', lang),
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            AppStrings.get('scan_tips_modal_subtitle', lang),
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkCaption : AppColors.caption,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        Divider(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
          height: 1,
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDontShowRow(bool isDark, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      child: GestureDetector(
        onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _dontShowAgain
                    ? AppColors.primaryGreen
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _dontShowAgain
                      ? AppColors.primaryGreen
                      : (isDark ? AppColors.darkDivider : AppColors.divider),
                  width: 2,
                ),
              ),
              child: _dontShowAgain
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.get('tips_dont_show', lang),
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton(bool isDark, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      child: GestureDetector(
        onTap: _onGotIt,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(AppDimens.radiusLG),
            boxShadow: SoftShadows.colorGlow(AppColors.primaryGreen),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_rounded,
                  color: AppColors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                AppStrings.get('tips_got_it', lang),
                style: AppTextStyles.button,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Drag Handle ──────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  final bool isDark;
  const _DragHandle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkDivider
              : AppColors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ─── Tip Row ──────────────────────────────────────────────────────────────────

class _TipRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isDark;
  final bool isLast;

  const _TipRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(AppDimens.radiusSM),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: isDark
                          ? AppColors.darkHeadingText
                          : AppColors.darkText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.darkCaption
                          : AppColors.caption,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Divider(
            color: (isDark ? AppColors.darkDivider : AppColors.divider)
                .withValues(alpha: 0.5),
            height: 20,
            indent: 62,
          ),
        if (isLast) const SizedBox(height: 4),
      ],
    );
  }
}
