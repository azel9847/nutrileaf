import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import 'nutrient.dart';

// ─── Crop Type ───────────────────────────────────────────────────────────────

/// Represents the types of crops the app supports.
enum CropType {
  rice,
  corn,
  vegetable,
}

/// Extension providing display properties for each crop type.
extension CropTypeExtension on CropType {
  String get displayName {
    switch (this) {
      case CropType.rice:
        return 'Rice';
      case CropType.corn:
        return 'Corn';
      case CropType.vegetable:
        return 'Vegetables';
    }
  }

  IconData get icon {
    switch (this) {
      case CropType.rice:
        return Icons.grass_rounded;
      case CropType.corn:
        return Icons.spa_rounded;
      case CropType.vegetable:
        return Icons.eco_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CropType.rice:
        return AppColors.rice;
      case CropType.corn:
        return AppColors.corn;
      case CropType.vegetable:
        return AppColors.vegetable;
    }
  }

  String toJsonString() => name;

  static CropType fromJsonString(String value) {
    return CropType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CropType.rice,
    );
  }
}

// ─── Scan Result ─────────────────────────────────────────────────────────────

/// Represents a single scan result with detected nutrient deficiency info.
class ScanResult {
  final String id;
  final String imagePath;
  final DateTime dateTime;
  final NutrientType detectedNutrient;
  final double confidence;
  final Map<NutrientType, double> allPredictions;
  final CropType cropType;

  ScanResult({
    String? id,
    required this.imagePath,
    DateTime? dateTime,
    required this.detectedNutrient,
    required this.confidence,
    required this.allPredictions,
    this.cropType = CropType.rice,
  })  : id = id ?? const Uuid().v4(),
        dateTime = dateTime ?? DateTime.now();

  /// Returns a severity label based on confidence level.
  String get severityLabel {
    if (detectedNutrient == NutrientType.healthy) return 'Healthy';
    if (confidence >= 0.85) return 'Severe';
    if (confidence >= 0.60) return 'Moderate';
    return 'Mild';
  }

  /// Returns sorted predictions (highest first).
  List<MapEntry<NutrientType, double>> get sortedPredictions {
    final entries = allPredictions.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'dateTime': dateTime.toIso8601String(),
        'detectedNutrient': detectedNutrient.toJsonString(),
        'confidence': confidence,
        'allPredictions': allPredictions.map(
          (key, value) => MapEntry(key.toJsonString(), value),
        ),
        'cropType': cropType.toJsonString(),
      };

  /// Deserialize from JSON map.
  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final predictionsMap = <NutrientType, double>{};
    final rawPredictions = json['allPredictions'] as Map<String, dynamic>;
    rawPredictions.forEach((key, value) {
      predictionsMap[NutrientTypeExtension.fromJsonString(key)] =
          (value as num).toDouble();
    });

    return ScanResult(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      detectedNutrient:
          NutrientTypeExtension.fromJsonString(json['detectedNutrient'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      allPredictions: predictionsMap,
      cropType: json['cropType'] != null
          ? CropTypeExtension.fromJsonString(json['cropType'] as String)
          : CropType.rice,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string.
  factory ScanResult.fromJsonString(String jsonString) =>
      ScanResult.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
