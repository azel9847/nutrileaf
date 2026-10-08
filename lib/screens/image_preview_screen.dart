import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../services/image_validator.dart';
import '../services/settings_service.dart';

// ─── Result Enum ─────────────────────────────────────────────────────────────

/// Action chosen by the user on the preview screen.
enum PreviewAction { scan, retake, cancel }

/// Return value passed back to the caller via [Navigator.pop].
class PreviewResult {
  final PreviewAction action;

  const PreviewResult({required this.action});
}

// ─── Screen ──────────────────────────────────────────────────────────────────

/// Full-screen image review page shown after the user picks or captures a photo.
///
/// Validates the image in the background and surfaces errors / warnings inline.
/// Returns a [PreviewResult] via [Navigator.pop] that tells the caller what
/// action to take next (scan, retake, or cancel).
class ImagePreviewScreen extends StatefulWidget {
  /// Raw image bytes for rendering and validation.
  final Uint8List? imageBytes;

  /// Path or URL string for the image (used as a key and for extension checks).
  final String imagePath;

  /// Whether the image was captured from the camera (affects Retake button label).
  final bool fromCamera;

  const ImagePreviewScreen({
    super.key,
    this.imageBytes,
    required this.imagePath,
    this.fromCamera = false,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  // ── Validation state ──────────────────────────────────────────────────────
  bool _isValidating = true;
  ImageValidationResult? _validationResult;
  bool _fileExists = true;

  // ── Entry animation ───────────────────────────────────────────────────────
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── Scan button press feedback ────────────────────────────────────────────
  bool _scanPressed = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    _entryController.forward();
    _startValidation();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  Future<void> _startValidation() async {
    final bytes = widget.imageBytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _fileExists = false;
        _isValidating = false;
      });
      return;
    }
    try {
      final result =
          await ImageValidator().validateBytes(bytes, widget.imagePath);
      if (mounted) {
        setState(() {
          _validationResult = result;
          _isValidating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  // ── Derived state ─────────────────────────────────────────────────────────

  /// Scan CTA is only enabled once validation completes without hard errors.
  bool get _canScan =>
      _fileExists &&
      !_isValidating &&
      (_validationResult == null || _validationResult!.isValid);

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _onCancel() =>
      Navigator.of(context).pop(const PreviewResult(action: PreviewAction.cancel));

  void _onRetake() =>
      Navigator.of(context).pop(const PreviewResult(action: PreviewAction.retake));

  void _onScan() {
    if (!_canScan) return;
    setState(() => _scanPressed = true);

    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) {
        Navigator.of(context).pop(
          const PreviewResult(action: PreviewAction.scan),
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.softBackground,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, lang),
                Expanded(
                  child: _fileExists
                      ? _buildImageArea(isDark)
                      : _buildErrorState(isDark, lang),
                ),
                _buildValidationBadge(isDark, lang),
                _buildActionBar(isDark, lang),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          // Cancel / back icon
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: _onCancel,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Icon(
                  Icons.close_rounded,
                  color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get('preview_title', lang),
                style: AppTextStyles.subtitle.copyWith(
                  color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                ),
              ),
              Text(
                AppStrings.get('preview_subtitle', lang),
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkCaption : AppColors.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Image area ────────────────────────────────────────────────────────────

  Widget _buildImageArea(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        child: Container(
          color: isDark
              ? AppColors.darkSurface
              : AppColors.paleGreen.withValues(alpha: 0.3),
          child: Stack(
            children: [
              Positioned.fill(
                child: widget.imageBytes != null
                    ? Image.memory(
                        widget.imageBytes!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _buildDecodeError(isDark),
                      )
                    : _buildDecodeError(isDark),
              ),
              Positioned.fill(
                child: CustomPaint(
                    painter: _PreviewFramePainter(isDark: isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown inside the image area when Flutter cannot decode the file.
  Widget _buildDecodeError(bool isDark) {
    return Container(
      color: isDark
          ? AppColors.darkSurface
          : AppColors.paleGreen.withValues(alpha: 0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 56,
            color: AppColors.dangerRed.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to display image',
            style: AppTextStyles.bodyBold.copyWith(
              color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The file may be corrupted.',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkCaption : AppColors.caption,
            ),
          ),
        ],
      ),
    );
  }

  // ── File-not-found error state ────────────────────────────────────────────

  Widget _buildErrorState(bool isDark, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.dangerRed.withValues(alpha: isDark ? 0.15 : 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.image_not_supported_rounded,
              size: 44,
              color: AppColors.dangerRed,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.get('preview_error_title', lang),
            style: AppTextStyles.headline3.copyWith(
              color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.get('preview_error_desc', lang),
            style: AppTextStyles.body.copyWith(
              color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Validation badge ──────────────────────────────────────────────────────

  Widget _buildValidationBadge(bool isDark, String lang) {
    if (!_fileExists) return const SizedBox.shrink();

    if (_isValidating) {
      return _BadgeRow(
        isDark: isDark,
        color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
        bgAlpha: 0.08,
        icon: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.leafGreen : AppColors.primaryGreen,
            ),
          ),
        ),
        text: AppStrings.get('img_validating', lang),
      );
    }

    if (_validationResult == null) return const SizedBox.shrink();

    final result = _validationResult!;

    // ── Hard errors ──
    if (result.hasErrors) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: result.errors.map((err) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                  border: Border.all(
                    color: AppColors.dangerRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_rounded,
                        color: AppColors.dangerRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        err.message,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.dangerRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    // ── Success + optional warnings ──
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BadgeRow(
            isDark: isDark,
            color: AppColors.successGreen,
            bgAlpha: isDark ? 0.12 : 0.06,
            icon: const Icon(Icons.check_circle_rounded,
                color: AppColors.successGreen, size: 16),
            text: AppStrings.get('img_verified', lang),
          ),
          ...result.warnings.map((warn) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber
                        .withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                    border: Border.all(
                      color: AppColors.warningAmber.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warningAmber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warn.message,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warningAmber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ── Action bar ────────────────────────────────────────────────────────────

  Widget _buildActionBar(bool isDark, String lang) {
    final retakeLabel = widget.fromCamera
        ? AppStrings.get('retake', lang)
        : AppStrings.get('change_image', lang);
    final retakeIcon = widget.fromCamera
        ? Icons.cameraswitch_rounded
        : Icons.photo_library_rounded;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.softBackground,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Cancel ── shrinks when space is tight
          Flexible(
            flex: 0,
            child: _GhostButton(
              isDark: isDark,
              icon: Icons.close_rounded,
              label: AppStrings.get('cancel', lang),
              onTap: _onCancel,
              id: 'preview_cancel_btn',
            ),
          ),
          const SizedBox(width: 8),

          // ── Retake / Change ── shrinks when space is tight
          Flexible(
            flex: 0,
            child: _SecondaryButton(
              isDark: isDark,
              icon: retakeIcon,
              label: retakeLabel,
              onTap: _onRetake,
              id: 'preview_retake_btn',
            ),
          ),
          const SizedBox(width: 8),

          // ── Scan Now ── takes all remaining space
          Expanded(
            flex: 2,
            child: _ScanButton(
              isDark: isDark,
              label: AppStrings.get('scan_now', lang),
              canScan: _canScan,
              isPressed: _scanPressed,
              onTap: _onScan,
              id: 'preview_scan_btn',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared badge row ─────────────────────────────────────────────────────────

class _BadgeRow extends StatelessWidget {
  final bool isDark;
  final Color color;
  final double bgAlpha;
  final Widget icon;
  final String text;

  const _BadgeRow({
    required this.isDark,
    required this.color,
    required this.bgAlpha,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(AppDimens.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Button sub-widgets ───────────────────────────────────────────────────────

/// Ghost / outlined Cancel button.
class _GhostButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String id;

  const _GhostButton({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: Key(id),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
          boxShadow: isDark ? SoftShadows.darkSubtle : SoftShadows.lightSubtle,
          color: isDark ? AppColors.darkCard : AppColors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? AppColors.darkCaption : AppColors.caption,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Terracotta-tinted Retake / Change button.
class _SecondaryButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String id;

  const _SecondaryButton({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: Key(id),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          color: AppColors.terracotta.withValues(alpha: isDark ? 0.15 : 0.1),
          border: Border.all(
            color: AppColors.terracotta.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.terracotta),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.terracotta,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary green Scan Now CTA with animated scale-down on press.
class _ScanButton extends StatelessWidget {
  final bool isDark;
  final String label;
  final bool canScan;
  final bool isPressed;
  final VoidCallback onTap;
  final String id;

  const _ScanButton({
    required this.isDark,
    required this.label,
    required this.canScan,
    required this.isPressed,
    required this.onTap,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canScan ? onTap : null,
      child: AnimatedScale(
        scale: isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          key: Key(id),
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusLG),
            color: canScan
                ? AppColors.primaryGreen
                : (isDark ? AppColors.darkSurface : AppColors.paleGreen),
            boxShadow: canScan
                ? SoftShadows.colorGlow(AppColors.primaryGreen)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco_rounded,
                color: canScan
                    ? AppColors.white
                    : (isDark ? AppColors.darkCaption : AppColors.caption),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.button.copyWith(
                    color: canScan
                        ? AppColors.white
                        : (isDark ? AppColors.darkCaption : AppColors.caption),
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (canScan) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.white.withValues(alpha: 0.85),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Frame painter ────────────────────────────────────────────────────────────

/// Subtle corner-bracket frame drawn over the image.
class _PreviewFramePainter extends CustomPainter {
  final bool isDark;
  const _PreviewFramePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          (isDark ? AppColors.leafGreen : AppColors.white).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const pad = 18.0;

    // Top-left
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + len, pad), paint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad, pad + len), paint);
    // Top-right
    canvas.drawLine(
        Offset(size.width - pad, pad), Offset(size.width - pad - len, pad), paint);
    canvas.drawLine(
        Offset(size.width - pad, pad), Offset(size.width - pad, pad + len), paint);
    // Bottom-left
    canvas.drawLine(
        Offset(pad, size.height - pad), Offset(pad + len, size.height - pad), paint);
    canvas.drawLine(
        Offset(pad, size.height - pad), Offset(pad, size.height - pad - len), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad - len, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad, size.height - pad - len), paint);
  }

  @override
  bool shouldRepaint(covariant _PreviewFramePainter old) => old.isDark != isDark;
}
