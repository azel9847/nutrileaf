import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../utils/constants.dart';
import 'nutrient.dart';

// =============================================================================
// CropType — aligned with HHC-VNDC Stage-1 classes
// =============================================================================

/// The five vegetable crops supported by the HHC-VNDC Stage-1 classifier.
///
/// Labels match the backend constants exactly (lowercase):
///   ampalaya | kalabasa | okra | sitaw | talong
enum CropType {
  ampalaya,
  kalabasa,
  okra,
  sitaw,
  talong,
}

/// Extension providing display properties for each [CropType].
extension CropTypeExtension on CropType {
  /// Filipino/common display name shown in the UI.
  String get displayName {
    switch (this) {
      case CropType.ampalaya:
        return 'Ampalaya';
      case CropType.kalabasa:
        return 'Kalabasa';
      case CropType.okra:
        return 'Okra';
      case CropType.sitaw:
        return 'Sitaw';
      case CropType.talong:
        return 'Talong';
    }
  }

  /// English / scientific name of the crop.
  String get englishName {
    switch (this) {
      case CropType.ampalaya:
        return 'Bitter Gourd';
      case CropType.kalabasa:
        return 'Squash';
      case CropType.okra:
        return 'Okra';
      case CropType.sitaw:
        return 'String Beans';
      case CropType.talong:
        return 'Eggplant';
    }
  }

  /// Emoji for quick visual identification.
  String get emoji {
    switch (this) {
      case CropType.ampalaya:
        return '🥒';
      case CropType.kalabasa:
        return '🎃';
      case CropType.okra:
        return '🌿';
      case CropType.sitaw:
        return '🫘';
      case CropType.talong:
        return '🍆';
    }
  }

  IconData get icon {
    switch (this) {
      case CropType.ampalaya:
        return Icons.eco_rounded;
      case CropType.kalabasa:
        return Icons.circle_rounded;
      case CropType.okra:
        return Icons.grass_rounded;
      case CropType.sitaw:
        return Icons.spa_rounded;
      case CropType.talong:
        return Icons.local_florist_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CropType.ampalaya:
        return AppColors.ampalaya;
      case CropType.kalabasa:
        return AppColors.kalabasa;
      case CropType.okra:
        return AppColors.okra;
      case CropType.sitaw:
        return AppColors.sitaw;
      case CropType.talong:
        return AppColors.talong;
    }
  }

  /// The HHC-VNDC Stage-2 deficiency classes for this crop.
  ///
  /// All five vegetables share the same four-class output in HHC-VNDC:
  ///   healthy | nitrogen | phosphorus | potassium
  List<NutrientType> get relevantNutrients => const [
        NutrientType.healthy,
        NutrientType.nitrogen,
        NutrientType.phosphorus,
        NutrientType.potassium,
      ];

  // ---------------------------------------------------------------------------
  // Serialization helpers
  // ---------------------------------------------------------------------------

  /// Returns the backend label string (lowercase enum name).
  String toJsonString() => name;

  /// Deserialize from a backend/JSON label string.
  ///
  /// Gracefully maps any legacy crop names that may be stored in local history.
  static CropType fromJsonString(String value) {
    // Exact match first
    for (final crop in CropType.values) {
      if (crop.name == value.toLowerCase()) return crop;
    }
    // Legacy mapping for old history entries (pre-HHC-VNDC)
    const legacyMap = <String, CropType>{
      'eggplant': CropType.talong,
      'ashgourd': CropType.kalabasa,
      'ashgourd_': CropType.kalabasa,
      'ash_gourd': CropType.kalabasa,
      'snakegourd': CropType.sitaw,
      'snake_gourd': CropType.sitaw,
      'tomato': CropType.okra,
    };
    return legacyMap[value.toLowerCase()] ?? CropType.ampalaya;
  }
}

// =============================================================================
// ScanResult
// =============================================================================

/// Represents a single completed HHC-VNDC scan.
///
/// Produced by [HhcApiService.predict] and stored in local history.
class ScanResult {
  final String id;
  final String imagePath;
  final DateTime dateTime;

  /// The HHC Stage-1 result: which crop was detected.
  final CropType cropType;

  /// The HHC Stage-2 result: which deficiency was detected.
  final NutrientType detectedNutrient;

  /// Stage-2 deficiency confidence [0.0 – 1.0].
  final double confidence;

  /// Stage-1 vegetable confidence [0.0 – 1.0].
  final double vegetableConfidence;

  /// Whether the diagnosis is considered reliable.
  ///
  /// Exposed as [true] for all server-side results (the server does not
  /// apply an ExG foliage check). Kept for API compatibility with screens
  /// that show a different UI for invalid scans.
  final bool isValidLeaf;

  /// Optional human-readable error / low-confidence message.
  final String? errorMessage;

  /// Full probability distribution from Stage-2 (deficiency expert).
  final Map<NutrientType, double> allPredictions;

  /// Full probability distribution from Stage-1 (vegetable classifier).
  final Map<String, double> vegetableProbabilities;

  /// Public URL of the image stored in Supabase (may be null).
  final String? imageUrl;

  /// In-memory image bytes from a live scan (not persisted to disk).
  final Uint8List? imageBytes;

  ScanResult({
    String? id,
    required this.imagePath,
    DateTime? dateTime,
    required this.cropType,
    required this.detectedNutrient,
    required this.confidence,
    this.vegetableConfidence = 0.0,
    this.isValidLeaf = true,
    this.errorMessage,
    required this.allPredictions,
    this.vegetableProbabilities = const {},
    this.imageUrl,
    this.imageBytes,
  })  : id = id ?? const Uuid().v4(),
        dateTime = dateTime ?? DateTime.now();

  /// Severity label based on confidence and deficiency class.
  String get severityLabel {
    if (detectedNutrient == NutrientType.healthy) return 'Healthy';
    if (confidence >= 0.85) return 'Severe';
    if (confidence >= 0.60) return 'Moderate';
    return 'Mild';
  }

  /// Deficiency probabilities sorted highest-first.
  List<MapEntry<NutrientType, double>> get sortedPredictions {
    final entries = allPredictions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'dateTime': dateTime.toIso8601String(),
        'cropType': cropType.toJsonString(),
        'detectedNutrient': detectedNutrient.toJsonString(),
        'confidence': confidence,
        'vegetableConfidence': vegetableConfidence,
        'isValidLeaf': isValidLeaf,
        'errorMessage': errorMessage,
        'allPredictions': allPredictions.map(
          (k, v) => MapEntry(k.toJsonString(), v),
        ),
        'vegetableProbabilities': vegetableProbabilities,
        'imageUrl': imageUrl,
        // imageBytes intentionally excluded — too large to store in prefs
      };

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final predictionsMap = <NutrientType, double>{};
    final rawPredictions =
        (json['allPredictions'] as Map<String, dynamic>? ?? {});
    rawPredictions.forEach((key, value) {
      predictionsMap[NutrientTypeExtension.fromJsonString(key)] =
          (value as num).toDouble();
    });

    final rawVegProbs =
        (json['vegetableProbabilities'] as Map<String, dynamic>? ?? {});

    return ScanResult(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      cropType: json['cropType'] != null
          ? CropTypeExtension.fromJsonString(json['cropType'] as String)
          : CropType.ampalaya,
      detectedNutrient: NutrientTypeExtension.fromJsonString(
        json['detectedNutrient'] as String,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      vegetableConfidence:
          (json['vegetableConfidence'] as num? ?? 0).toDouble(),
      isValidLeaf: json['isValidLeaf'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
      allPredictions: predictionsMap,
      vegetableProbabilities: rawVegProbs
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ScanResult.fromJsonString(String jsonString) =>
      ScanResult.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
