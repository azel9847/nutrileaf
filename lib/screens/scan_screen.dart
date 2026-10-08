import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';


import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/settings_service.dart';
import '../utils/app_strings.dart';
import '../utils/constants.dart';
import '../widgets/scan_tips_modal.dart';
import '../widgets/soft_card.dart';
import 'image_preview_screen.dart';
import 'result_screen.dart';

/// Scan screen — allows the user to pick or capture a leaf image,
/// submit it to the HHC-VNDC backend, and navigate to [ResultScreen].
class ScanScreen extends StatefulWidget {
  final bool initialUpload;

  const ScanScreen({super.key, this.initialUpload = false});

  @override
  State<ScanScreen> createState() => ScanScreenState();
}

class ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  // ── Image state ─────────────────────────────────────────────────────────────
  PickedImage? _selectedImage;
  Uint8List? _selectedImageBytes;

  // ── Analysis state ───────────────────────────────────────────────────────────
  bool _isAnalyzing = false;
  String _analysisStage = '';
  bool _hasError = false;
  String _errorMessage = '';

  // ── Camera state ─────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  FlashMode _flashMode = FlashMode.off;
  bool _isTakingPicture = false;

  // ── Animation ────────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

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

    _initCamera();

    if (widget.initialUpload) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pickImage());
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeShowTipsModal());
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('[NutriLeaf] Camera init error: $e');
    }
  }

  Future<void> _maybeShowTipsModal() async {
    if (!mounted) return;
    final settings = context.read<SettingsService>();
    if (settings.showScanTips) {
      await showScanTipsModal(context);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Public reset — called by MainShell when the Scan tab is re-focused
  // ---------------------------------------------------------------------------

  /// Clears any captured/frozen image and resumes the live camera stream.
  ///
  /// Call this whenever the user returns to the Scan tab so they are never
  /// left staring at a frozen frame.
  Future<void> resetForFocus() async {
    if (!mounted) return;
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _hasError = false;
      _errorMessage = '';
    });
    await _safeResumePreview();
  }

  /// Safely calls resumePreview, guarding against disposed/uninitialised state.
  Future<void> _safeResumePreview() async {
    try {
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_cameraController!.value.isPreviewPaused) {
        // Already streaming — nothing to do.
        return;
      }
      if (_cameraController != null &&
          _cameraController!.value.isInitialized) {
        await _cameraController!.resumePreview();
      }
    } catch (e) {
      debugPrint('[NutriLeaf] resumePreview error (ignored): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Flash
  // ---------------------------------------------------------------------------

  /// Toggles between Off and Torch only (simpler than 3-way cycle, per request).
  Future<void> _toggleFlash() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }
    final next =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _cameraController!.setFlashMode(next);
    if (mounted) setState(() => _flashMode = next);
  }

  IconData get _flashIcon =>
      _flashMode == FlashMode.torch
          ? Icons.flashlight_on_rounded
          : Icons.flash_off_rounded;

  // ---------------------------------------------------------------------------
  // Image capture / gallery
  // ---------------------------------------------------------------------------

  Future<void> _captureImage() async {
    if (_isTakingPicture) return;

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      // Fallback: delegate to system camera intent
      PickedImage? picked;
      try {
        picked = await CameraService().captureFromCamera();
      } on CameraServiceException catch (e) {
        if (mounted) _showSnackError(e.message);
        return;
      }
      if (picked != null && mounted) {
        await _openPreview(picked, fromCamera: true);
      }
      return;
    }

    setState(() => _isTakingPicture = true);
    try {
      final xFile = await _cameraController!.takePicture();

      // Center-square crop to match the viewfinder reticle.
      final bytes = await xFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null) {
        final size = image.width < image.height ? image.width : image.height;
        final x = (image.width - size) ~/ 2;
        final y = (image.height - size) ~/ 2;

        final cropped =
            img.copyCrop(image, x: x, y: y, width: size, height: size);
        final croppedBytes = img.encodeJpg(cropped, quality: 90);

        final croppedXFile = XFile.fromData(
          Uint8List.fromList(croppedBytes),
          name: 'crop_${xFile.name}',
          path: xFile.path,
        );
        final picked = PickedImage(xFile: croppedXFile);

        if (mounted) await _openPreview(picked, fromCamera: true);
      }
    } catch (e) {
      if (mounted) _showSnackError('Failed to capture photo: $e');
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  Future<void> pickImage() async {
    PickedImage? picked;
    try {
      picked = await CameraService().pickFromGallery();
    } on CameraServiceException catch (e) {
      if (mounted) _showSnackError(e.message);
      return;
    }
    if (picked != null && mounted) {
      await _openPreview(picked, fromCamera: false);
    }
  }

  void _showSnackError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dangerRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPreview(PickedImage picked,
      {required bool fromCamera}) async {
    if (!mounted) return;

    final String imagePath = picked.path;
    final Uint8List bytes =
        Uint8List.fromList(await picked.readAsBytes());

    if (!mounted) return;

    final result = await Navigator.of(context).push<PreviewResult>(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => ImagePreviewScreen(
          imagePath: imagePath,
          imageBytes: bytes,
          fromCamera: fromCamera,
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );

    if (!mounted) return;

    switch (result?.action) {
      case PreviewAction.scan:
        // Clear any prior error state before a fresh attempt.
        setState(() {
          _selectedImage = picked;
          _selectedImageBytes = bytes;
          _hasError = false;
          _errorMessage = '';
        });
        await _analyzeImage();
        break;

      case PreviewAction.retake:
        // Clear stale image + resume live stream before re-capturing.
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
          _hasError = false;
          _errorMessage = '';
        });
        await _safeResumePreview();
        if (fromCamera) {
          await _captureImage();
        } else {
          await pickImage();
        }
        break;

      case PreviewAction.cancel:
      case null:
        // Clear stale image + resume live stream.
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
          _hasError = false;
          _errorMessage = '';
        });
        await _safeResumePreview();
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // HHC inference
  // ---------------------------------------------------------------------------

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || _selectedImageBytes == null) return;

    setState(() {
      _isAnalyzing = true;
      _hasError = false;
      _errorMessage = '';
      _analysisStage = 'Uploading image to AI server…';
    });
    _pulseController.repeat(reverse: true);

    try {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _isAnalyzing) {
          setState(() => _analysisStage = 'Stage 1 — Identifying vegetable…');
        }
      });
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && _isAnalyzing) {
          setState(
              () => _analysisStage = 'Stage 2 — Diagnosing deficiency…');
        }
      });

      final result = await MLService().analyzeImage(
        _selectedImage!.path,
        imageBytes: _selectedImageBytes,
      );

      if (mounted) {
        _pulseController.stop();
        setState(() {
          _isAnalyzing = false;
          _analysisStage = '';
        });
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
        );
      }
    } catch (e) {
      debugPrint('[NutriLeaf] HHC inference failed: $e');
      if (mounted) {
        _pulseController.stop();
        setState(() {
          _isAnalyzing = false;
          _analysisStage = '';
          _hasError = true;
          _errorMessage = _friendlyError(e.toString());
          // Clear the frozen captured image so the live feed shows again.
          _selectedImage = null;
          _selectedImageBytes = null;
        });
        await _safeResumePreview();
      }
    }
  }

  /// "Try Again" from the error banner — clears error and restarts capture.
  Future<void> _retryCapture() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _selectedImage = null;
      _selectedImageBytes = null;
    });
    await _safeResumePreview();
  }

  String _friendlyError(String raw) {
    if (raw.contains('Could not reach') || raw.contains('SocketException')) {
      return 'Cannot connect to the server. Check your internet and try again.';
    }
    if (raw.contains('503') || raw.contains('not ready')) {
      return 'The AI model is still warming up. Please wait a moment and retry.';
    }
    return 'Analysis failed. Please try again with a clearer leaf photo.';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.softBackground,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Text(
                    AppStrings.get('scan_title', lang),
                    style: AppTextStyles.headline2.copyWith(
                      color: isDark ? AppColors.darkHeadingText : null,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Powered by HHC-VNDC — Two-Stage AI Diagnosis',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.darkCaption
                          : AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Stage info banner ───────────────────────────────────
                  _buildStageInfoBanner(isDark),

                  const SizedBox(height: 16),

                  // ── Error recovery banner ───────────────────────────────
                  if (_hasError) _buildErrorBanner(isDark),
                  if (_hasError) const SizedBox(height: 12),

                  // ── Camera / image viewfinder ───────────────────────────
                  _buildViewfinder(isDark, lang),

                  const SizedBox(height: 16),

                  // ── Capture / shutter row ───────────────────────────────
                  _buildActionRow(isDark, lang),

                  const SizedBox(height: 20),

                  // ── Tips ────────────────────────────────────────────────
                  _buildInstructions(isDark, lang),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ── Scanning overlay ────────────────────────────────────────────
          if (_isAnalyzing) _buildScanningOverlay(isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets
  // ---------------------------------------------------------------------------

  Widget _buildStageInfoBanner(bool isDark) {
    return SoftCard(
      color: isDark
          ? AppColors.darkCard
          : AppColors.paleGreen.withValues(alpha: 0.6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _stagePill('1', 'Vegetable ID', AppColors.primaryGreen, isDark),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: AppColors.softGreen),
          const SizedBox(width: 8),
          _stagePill(
              '2', 'Deficiency Diagnosis', AppColors.terracotta, isDark),
        ],
      ),
    );
  }

  Widget _stagePill(String number, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.18 : 0.09),
          borderRadius: BorderRadius.circular(AppDimens.radiusSM),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: color,
              child: Text(number,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  /// Inline error recovery banner shown when analysis fails.
  Widget _buildErrorBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(
            color: AppColors.dangerRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.dangerRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: AppTextStyles.caption.copyWith(
                color: isDark
                    ? AppColors.dangerRed.withValues(alpha: 0.9)
                    : AppColors.dangerRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _retryCapture,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.dangerRed,
                borderRadius: BorderRadius.circular(AppDimens.radiusSM),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The main viewfinder widget — shows live camera, captured image, or placeholder.
  Widget _buildViewfinder(bool isDark, String lang) {
    return SoftCard(
      padding: EdgeInsets.zero,
      borderRadius: AppDimens.radiusMD,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        child: SizedBox(
          height: 300,
          child: _selectedImage != null
              ? _buildCapturedPreview()
              : _isCameraInitialized
                  ? _buildLiveCameraPreview()
                  : _buildPlaceholder(isDark, lang),
        ),
      ),
    );
  }

  /// Displays the most recently captured/selected image with the frame overlay.
  Widget _buildCapturedPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _selectedImageBytes != null
            ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
            : const Center(child: Icon(Icons.image, size: 48)),
        CustomPaint(painter: _FramePainter()),
      ],
    );
  }

  /// Live camera feed with correct aspect ratio, flash button, and NO shutter button.
  /// The shutter is placed BELOW the viewfinder in [_buildActionRow] to avoid
  /// obscuring the leaf preview.
  Widget _buildLiveCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale the CameraPreview to fill the box while preserving aspect ratio.
        final camAspect = _cameraController!.value.aspectRatio;
        final boxAspect = constraints.maxWidth / constraints.maxHeight;

        double previewW, previewH;
        if (camAspect > boxAspect) {
          // Camera is wider — fit by height, overflow sides
          previewH = constraints.maxHeight;
          previewW = previewH * camAspect;
        } else {
          // Camera is taller — fit by width, overflow top/bottom
          previewW = constraints.maxWidth;
          previewH = previewW / camAspect;
        }

        return ClipRect(
          child: OverflowBox(
            maxWidth: previewW,
            maxHeight: previewH,
            child: Stack(
              children: [
                // Live feed
                SizedBox(
                  width: previewW,
                  height: previewH,
                  child: CameraPreview(_cameraController!),
                ),
                // Corner-frame reticle
                Positioned.fill(
                  child: CustomPaint(painter: _FramePainter()),
                ),
                // Flash toggle — top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildFlashButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Empty state shown while the camera is initialising or unavailable.
  Widget _buildPlaceholder(bool isDark, String lang) {
    return Column(
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
            color:
                isDark ? AppColors.darkHeadingText : AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.get('ensure_light', lang),
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppColors.darkCaption : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Supports: Ampalaya · Kalabasa · Okra · Sitaw · Talong',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Glassmorphic flash toggle button overlaid inside the live viewfinder.
  Widget _buildFlashButton() {
    final isOn = _flashMode == FlashMode.torch;
    return GestureDetector(
      onTap: _toggleFlash,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
          border: Border.all(
            color: isOn ? Colors.amberAccent : Colors.white38,
            width: 1.5,
          ),
        ),
        child: Icon(
          _flashIcon,
          size: 20,
          color: isOn ? Colors.amberAccent : Colors.white70,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action row — shutter button lives HERE, below the viewfinder
  // ---------------------------------------------------------------------------

  /// Row containing the shutter button (centre) and gallery button (right).
  /// When the live camera is active, the shutter is the primary CTA.
  /// When the camera is unavailable, only the gallery button is shown.
  Widget _buildActionRow(bool isDark, String lang) {
    if (_isCameraInitialized) {
      // Live camera mode: prominent centred shutter + gallery on the right.
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gallery button — left side
          _buildGalleryButton(isDark, lang, compact: true),

          const SizedBox(width: 24),

          // Shutter — centred, prominent
          _buildShutterButton(),

          const SizedBox(width: 24),

          // Spacer mirror so the shutter stays visually centred
          const SizedBox(width: 56, height: 56),
        ],
      );
    }

    // No live camera: show full-width gallery button only.
    return _buildGalleryButton(isDark, lang, compact: false);
  }

  /// Prominent circular shutter button positioned BELOW the viewfinder.
  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _captureImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: _isTakingPicture ? 66 : 74,
        height: _isTakingPicture ? 66 : 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.5),
            width: 4,
          ),
          boxShadow: SoftShadows.colorGlow(AppColors.primaryGreen),
        ),
        child: _isTakingPicture
            ? Padding(
                padding: const EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen),
                ),
              )
            : const Icon(
                Icons.camera_rounded,
                size: 36,
                color: AppColors.primaryGreen,
              ),
      ),
    );
  }

  Widget _buildGalleryButton(bool isDark, String lang,
      {required bool compact}) {
    if (compact) {
      // Circular icon-only button to mirror the shutter layout.
      return GestureDetector(
        onTap: pickImage,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppColors.darkCard
                : AppColors.paleGreen.withValues(alpha: 0.8),
            border: Border.all(
                color: AppColors.terracotta.withValues(alpha: 0.4),
                width: 1.5),
          ),
          child: const Icon(
            Icons.photo_library_rounded,
            color: AppColors.terracotta,
            size: 24,
          ),
        ),
      );
    }

    // Full-width card when camera is unavailable.
    return SoftCard(
      onTap: pickImage,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          const Icon(Icons.photo_library_rounded,
              color: AppColors.terracotta, size: 28),
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
                color:
                    isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.get('tips_title', lang),
                style: AppTextStyles.bodyBold.copyWith(
                  color: isDark
                      ? AppColors.leafGreen
                      : AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.leafGreen,
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
            ),
          ),
        ],
      ),
    );
  }

  /// Full-screen overlay shown while the HHC pipeline is running.
  Widget _buildScanningOverlay(bool isDark) {
    final lang = 'en';
    return Container(
      color:
          (isDark ? Colors.black : AppColors.darkText).withValues(alpha: 0.65),
      child: Center(
        child: SoftCard(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) =>
                    Transform.scale(scale: _pulseAnimation.value, child: child),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.primaryGreen, width: 3),
                    boxShadow: SoftShadows.colorGlow(AppColors.primaryGreen),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: AppColors.primaryGreen, size: 36),
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _analysisStage,
                  key: ValueKey(_analysisStage),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'HHC-VNDC is identifying your crop\nand diagnosing nutrient deficiencies',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.darkBodyText : null,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.paleGreen,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGreen),
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Corner-frame painter for the viewfinder overlay.
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

    canvas.drawLine(
        const Offset(pad, pad), const Offset(pad + len, pad), paint);
    canvas.drawLine(
        const Offset(pad, pad), const Offset(pad, pad + len), paint);
    canvas.drawLine(Offset(size.width - pad, pad),
        Offset(size.width - pad - len, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad),
        Offset(size.width - pad, pad + len), paint);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(pad + len, size.height - pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(pad, size.height - pad - len), paint);
    canvas.drawLine(
        Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad - len, size.height - pad),
        paint);
    canvas.drawLine(
        Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad, size.height - pad - len),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
