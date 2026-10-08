import 'dart:typed_data';

import '../models/nutrient.dart';
import '../models/scan_result.dart';
import 'hhc_api_service.dart';

/// Orchestration layer between the UI and [HhcApiService].
///
/// Provides the [analyzeImage] API consumed by [ScanScreen] and
/// [ImagePreviewScreen]. All inference is performed server-side by the
/// FastAPI HHC-VNDC backend via [HhcApiService].
class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  final HhcApiService _api = HhcApiService();

  /// No-op: kept for call-site compatibility.
  Future<void> loadModel() async {}

  /// No-op: no local resources to release; kept for call-site compatibility.
  Future<void> dispose() async {}

  /// Send [imageBytes] to the HHC-VNDC backend and return a [ScanResult].
  ///
  /// Parameters
  /// ----------
  /// [imagePath]  — local path or identifier used to label the result.
  /// [imageBytes] — raw image bytes to upload.
  /// [cropType]   — ignored: Stage-1 auto-detects the vegetable.
  ///                Kept for call-site compatibility.
  ///
  /// Throws [HhcApiException] on network or server errors.
  Future<ScanResult> analyzeImage(
    String imagePath, {
    CropType? cropType,
    Uint8List? imageBytes,
  }) async {
    if (imageBytes == null || imageBytes.isEmpty) {
      throw HhcApiException('No image bytes provided to MLService.analyzeImage.');
    }

    // Derive a filename with a sensible extension from the path.
    final filename = _filenameFromPath(imagePath);

    final prediction = await _api.predict(imageBytes, filename: filename);

    // Map backend string labels to CropType and NutrientType enums.
    final detectedCrop = CropTypeExtension.fromJsonString(prediction.vegetable);
    final detectedNutrient =
        NutrientTypeExtension.fromJsonString(prediction.diagnosedDeficiency);

    // Build a NutrientType -> double map from the server's probability dict.
    // The backend now returns only the top class, so when no distribution is
    // supplied, seed the detected class with its confidence.
    final allPredictions = <NutrientType, double>{};
    for (final nt in NutrientType.values) {
      final key = nt.toJsonString();
      allPredictions[nt] = prediction.deficiencyProbabilities[key] ??
          (nt == detectedNutrient ? prediction.deficiencyConfidence : 0.0);
    }

    return ScanResult(
      imagePath: imagePath,
      cropType: detectedCrop,
      detectedNutrient: detectedNutrient,
      confidence: prediction.deficiencyConfidence,
      vegetableConfidence: prediction.vegetableConfidence,
      vegetableProbabilities: prediction.vegetableProbabilities,
      allPredictions: allPredictions,
      imageUrl: prediction.imageUrl,
      imageBytes: imageBytes,
      isValidLeaf: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _filenameFromPath(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    if (name.contains('.')) return name;
    return '$name.jpg';
  }
}
