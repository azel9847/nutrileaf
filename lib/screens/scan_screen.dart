import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/settings_service.dart';
import '../models/scan_result.dart';
import '../widgets/soft_card.dart';
import '../widgets/crop_chip.dart';
import 'result_screen.dart';

/// Scan page with crop selector, camera/gallery options, and analysis animation.
class ScanScreen extends StatefulWidget {
  final bool initialUpload;

  const ScanScreen({super.key, this.initialUpload = false});

  @override
  State<ScanScreen> createState() => ScanScreenState();
}

class ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  File? _selectedImage;
  bool _isAnalyzing = false;
  CropType _selectedCrop = CropType.rice;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.initialUpload) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pickImage());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    final file = await CameraService().captureFromCamera();
    if (file != null && mounted) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> pickImage() async {
    final file = await CameraService().pickFromGallery();
    if (file != null && mounted) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);
    _pulseController.repeat(reverse: true);

    try {
      final result = await MLService().analyzeImage(
        _selectedImage!.path,
        cropType: _selectedCrop,
      );
      if (mounted) {
        _pulseController.stop();
        setState(() => _isAnalyzing = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _pulseController.stop();
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.softBackground,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        AppStrings.get('scan_title', lang),
                        style: AppTextStyles.headline2.copyWith(
                          color: isDark ? AppColors.darkHeadingText : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Crop selector
                  Text(
                    AppStrings.get('select_crop', lang),
                    style: AppTextStyles.bodyBold.copyWith(
                      color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: CropType.values.map((crop) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: CropChip(
                            label: crop.displayName,
                            icon: crop.icon,
                            color: crop.color,
                            isSelected: _selectedCrop == crop,
                            onTap: () => setState(() => _selectedCrop = crop),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Image preview area
                  _buildImagePreview(isDark, lang),

                  const SizedBox(height: 20),

                  // Action buttons (Camera & Gallery)
                  if (_selectedImage == null) _buildCaptureButtons(isDark, lang),

                  // Retake / Confirm buttons
                  if (_selectedImage != null && !_isAnalyzing)
                    _buildConfirmButtons(isDark, lang),

                  const SizedBox(height: 20),

                  // Instructions
                  _buildInstructions(isDark, lang),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Scanning overlay
          if (_isAnalyzing) _buildScanningOverlay(isDark, lang),
        ],
      ),
    );
  }

  Widget _buildImagePreview(bool isDark, String lang) {
    return SoftCard(
      padding: EdgeInsets.zero,
      borderRadius: AppDimens.radiusMD,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          color: isDark
              ? AppColors.darkSurface
              : AppColors.paleGreen.withValues(alpha: 0.4),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImage!, fit: BoxFit.cover),
                    // Subtle corner markers
                    CustomPaint(painter: _FramePainter()),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.leafGreen : AppColors.lightGreen)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      size: 44,
                      color: isDark ? AppColors.leafGreen : AppColors.lightGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get('place_leaf', lang),
                    style: AppTextStyles.subtitle.copyWith(
                      color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.get('ensure_light', lang),
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkCaption : null,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCaptureButtons(bool isDark, String lang) {
    return Row(
      children: [
        Expanded(
          child: SoftCard(
            onTap: _captureImage,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('take_photo', lang),
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SoftCard(
            onTap: pickImage,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.terracotta,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('from_gallery', lang),
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.terracotta,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButtons(bool isDark, String lang) {
    return Row(
      children: [
        // Retake
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedImage = null),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
                boxShadow: isDark ? SoftShadows.darkSubtle : SoftShadows.lightSubtle,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppStrings.get('retake', lang),
                      style: AppTextStyles.bodyBold.copyWith(
                        color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Analyze
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _analyzeImage,
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
                  const Icon(
                    Icons.psychology_rounded,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppStrings.get('analyze_ai', lang),
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
      ],
    );
  }

  Widget _buildInstructions(bool isDark, String lang) {
    final tips = [
      'Use good natural lighting',
      'Focus on a single leaf',
      'Capture both sides if possible',
      'Avoid shadows on the leaf',
      'Include the full leaf in frame',
    ];

    return SoftCard(
      color: isDark
          ? AppColors.darkCard
          : AppColors.paleGreen.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.get('tips_title', lang),
                style: AppTextStyles.bodyBold.copyWith(
                  color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.leafGreen : AppColors.leafGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tip,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: isDark ? AppColors.darkBodyText : null,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay(bool isDark, String lang) {
    return Container(
      color: (isDark ? Colors.black : AppColors.darkText).withValues(alpha: 0.6),
      child: Center(
        child: SoftCard(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing ring
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen,
                      width: 3,
                    ),
                    boxShadow: SoftShadows.colorGlow(AppColors.primaryGreen),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primaryGreen,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.get('analyzing', lang),
                style: AppTextStyles.headline3.copyWith(
                  color: isDark ? AppColors.darkHeadingText : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Our AI is scanning for nutrient\ndeficiencies in your leaf image',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.darkBodyText : null,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.paleGreen,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for subtle corner frame markers on the image preview.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const len = 30.0;
    const pad = 16.0;

    // Top-left
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + len, pad), paint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad, pad + len), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad - len, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad, pad + len), paint);

    // Bottom-left
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad + len, size.height - pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad, size.height - pad - len), paint);

    // Bottom-right
    canvas.drawLine(
        Offset(size.width - pad, size.height - pad), Offset(size.width - pad - len, size.height - pad), paint);
    canvas.drawLine(
        Offset(size.width - pad, size.height - pad), Offset(size.width - pad, size.height - pad - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
