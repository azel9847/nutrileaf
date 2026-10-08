import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Result of image validation checks.
class ImageValidationResult {
  final bool isValid;
  final List<ValidationIssue> errors;
  final List<ValidationIssue> warnings;

  const ImageValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  /// Convenience — true when there are zero errors.
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// A single validation issue (error or warning).
class ValidationIssue {
  final String code;
  final String message;

  const ValidationIssue({required this.code, required this.message});
}

/// Image quality and context verification service.
///
/// Validates uploaded images before ML processing:
/// - File format (jpg, jpeg, png, webp)
/// - File size (5 KB – 20 MB)
/// - Resolution (≥ 224×224 px)
/// - Leaf content heuristic (green-pixel ratio)
class ImageValidator {
  static final ImageValidator _instance = ImageValidator._internal();
  factory ImageValidator() => _instance;
  ImageValidator._internal();

  /// Accepted file extensions.
  static const _validExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  /// Minimum resolution in pixels.
  static const int _minWidth = 224;
  static const int _minHeight = 224;

  /// File size bounds.
  static const int _minFileSize = 5 * 1024; // 5 KB
  static const int _maxFileSize = 20 * 1024 * 1024; // 20 MB

  /// Minimum ratio of green-dominant pixels to flag as "contains leaf".
  static const double _leafGreenThreshold = 0.08; // 8%

  /// Maximum number of pixels to sample for the green heuristic.
  static const int _samplePixelCount = 2000;

  /// Run all validation checks on the given image file.
  ///
  /// Returns immediately with errors if the file doesn't exist.
  /// Expensive checks (resolution, leaf content) run sequentially.
  Future<ImageValidationResult> validate(File imageFile) async {
    final errors = <ValidationIssue>[];
    final warnings = <ValidationIssue>[];

    // ── 1. File exists ───────────────────────────────────────────────────
    if (!await imageFile.exists()) {
      errors.add(const ValidationIssue(
        code: 'file_not_found',
        message: 'Image file not found',
      ));
      return ImageValidationResult(
          isValid: false, errors: errors, warnings: warnings);
    }

    // ── 2. Format check ──────────────────────────────────────────────────
    final extension = _getExtension(imageFile.path).toLowerCase();
    if (!_validExtensions.contains(extension)) {
      errors.add(ValidationIssue(
        code: 'invalid_format',
        message: 'Invalid image format ($extension). Please use JPG or PNG.',
      ));
      // Can't proceed with further checks if format is wrong.
      return ImageValidationResult(
          isValid: false, errors: errors, warnings: warnings);
    }

    // ── 3. File size check ───────────────────────────────────────────────
    final fileSize = await imageFile.length();
    if (fileSize < _minFileSize) {
      errors.add(const ValidationIssue(
        code: 'file_too_small',
        message: 'Image file is too small or may be corrupted.',
      ));
    } else if (fileSize > _maxFileSize) {
      errors.add(const ValidationIssue(
        code: 'file_too_large',
        message: 'Image file exceeds 20 MB. Please use a smaller image.',
      ));
    }

    // ── 4. Resolution check ──────────────────────────────────────────────
    img.Image? decodedImage;
    try {
      final bytes = await imageFile.readAsBytes();
      decodedImage = img.decodeImage(bytes);
    } catch (_) {
      errors.add(const ValidationIssue(
        code: 'decode_failed',
        message: 'Unable to read image. The file may be corrupted.',
      ));
    }

    if (decodedImage != null) {
      if (decodedImage.width < _minWidth || decodedImage.height < _minHeight) {
        errors.add(ValidationIssue(
          code: 'low_resolution',
          message:
              'Image resolution too low (${decodedImage.width}×${decodedImage.height}). '
              'Minimum $_minWidth×$_minHeight required.',
        ));
      }

      // ── 5. Leaf content heuristic ────────────────────────────────────
      if (errors.isEmpty) {
        final greenRatio = _computeGreenPixelRatio(decodedImage);
        if (greenRatio < _leafGreenThreshold) {
          warnings.add(const ValidationIssue(
            code: 'not_leaf',
            message:
                'This image may not contain a plant leaf. Proceed with caution.',
          ));
        }
      }
    }

    return ImageValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate directly from raw [bytes] — used on web where dart:io is unavailable.
  ///
  /// [filePath] is used only to try to extract a file extension.
  /// On web the path is often a blob URL (e.g. `blob:https://…/uuid`) with no
  /// extension; in that case format validation is skipped and magic-byte sniffing
  /// is used instead so legitimate images are never rejected.
  Future<ImageValidationResult> validateBytes(
    List<int> bytes,
    String filePath,
  ) async {
    final errors = <ValidationIssue>[];
    final warnings = <ValidationIssue>[];

    // ── 1. Format check ──────────────────────────────────────────────────
    final extension = _getExtension(filePath).toLowerCase();
    final hasKnownExtension = _validExtensions.contains(extension);

    if (!hasKnownExtension) {
      // Fallback: check JPEG (FF D8 FF) or PNG (89 50 4E 47) magic bytes.
      final bool isJpeg = bytes.length >= 3 &&
          bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
      final bool isPng = bytes.length >= 4 &&
          bytes[0] == 0x89 && bytes[1] == 0x50 &&
          bytes[2] == 0x4E && bytes[3] == 0x47;
      final bool isWebP = bytes.length >= 4 &&
          bytes[0] == 0x52 && bytes[1] == 0x49 && // RI
          bytes[2] == 0x46 && bytes[3] == 0x46;    // FF

      if (!isJpeg && !isPng && !isWebP) {
        // Only hard-reject if there IS a recognisable but unsupported extension.
        // If there's NO extension (web blob URL), trust the image picker.
        if (extension.isNotEmpty) {
          errors.add(ValidationIssue(
            code: 'invalid_format',
            message:
                'Invalid image format ($extension). Please use JPG or PNG.',
          ));
          return ImageValidationResult(
              isValid: false, errors: errors, warnings: warnings);
        }
        // else: no extension and no magic bytes — proceed; image.dart will
        // confirm decodability in the resolution step below.
      }
    }

    // ── 2. File size check ───────────────────────────────────────────────
    final fileSize = bytes.length;
    if (fileSize < _minFileSize) {
      errors.add(const ValidationIssue(
        code: 'file_too_small',
        message: 'Image file is too small or may be corrupted.',
      ));
    } else if (fileSize > _maxFileSize) {
      errors.add(const ValidationIssue(
        code: 'file_too_large',
        message: 'Image file exceeds 20 MB. Please use a smaller image.',
      ));
    }

    // ── 3. Resolution + leaf heuristic ───────────────────────────────────
    img.Image? decodedImage;
    try {
      decodedImage = img.decodeImage(Uint8List.fromList(bytes));
    } catch (_) {
      errors.add(const ValidationIssue(
        code: 'decode_failed',
        message: 'Unable to read image. The file may be corrupted.',
      ));
    }

    if (decodedImage == null && errors.isEmpty) {
      errors.add(const ValidationIssue(
        code: 'decode_failed',
        message: 'Unable to read image. Unsupported format.',
      ));
    }

    if (decodedImage != null) {
      if (decodedImage.width < _minWidth || decodedImage.height < _minHeight) {
        errors.add(ValidationIssue(
          code: 'low_resolution',
          message:
              'Image resolution too low (${decodedImage.width}×${decodedImage.height}). '
              'Minimum $_minWidth×$_minHeight required.',
        ));
      }

      if (errors.isEmpty) {
        final greenRatio = _computeGreenPixelRatio(decodedImage);
        if (greenRatio < _leafGreenThreshold) {
          warnings.add(const ValidationIssue(
            code: 'not_leaf',
            message:
                'This image may not contain a plant leaf. Proceed with caution.',
          ));
        }
      }
    }

    return ImageValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Compute the ratio of green-dominant pixels by sampling random positions.
  ///
  /// A pixel is "green-dominant" when the green channel is the highest
  /// channel AND green exceeds a minimum absolute value (to ignore dark
  /// or gray pixels).
  double _computeGreenPixelRatio(img.Image image) {
    final random = Random(42); // Deterministic for consistency
    final totalSamples =
        min(_samplePixelCount, image.width * image.height);
    int greenCount = 0;

    for (int i = 0; i < totalSamples; i++) {
      final x = random.nextInt(image.width);
      final y = random.nextInt(image.height);
      final pixel = image.getPixel(x, y);

      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      // Green-dominant: green is the highest channel and above a minimum
      // threshold to exclude near-black or gray pixels.
      if (g > r && g > b && g > 50) {
        greenCount++;
      }
    }

    return greenCount / totalSamples;
  }

  /// Extract file extension from a path string.
  String _getExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1) return '';
    return filePath.substring(lastDot);
  }
}
