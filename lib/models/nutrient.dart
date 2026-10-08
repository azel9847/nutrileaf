import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Nutrient deficiency types diagnosed by HHC-VNDC Stage-2 expert models.
///
/// All five vegetable experts share the same four output classes:
///   healthy | nitrogen | phosphorus | potassium
enum NutrientType {
  nitrogen,
  phosphorus,
  potassium,
  healthy,
}

/// Extension providing display properties for each [NutrientType].
extension NutrientTypeExtension on NutrientType {
  String get displayName {
    switch (this) {
      case NutrientType.nitrogen:
        return 'Nitrogen (N)';
      case NutrientType.phosphorus:
        return 'Phosphorus (P)';
      case NutrientType.potassium:
        return 'Potassium (K)';
      case NutrientType.healthy:
        return 'Healthy';
    }
  }

  String get shortName {
    switch (this) {
      case NutrientType.nitrogen:
        return 'N';
      case NutrientType.phosphorus:
        return 'P';
      case NutrientType.potassium:
        return 'K';
      case NutrientType.healthy:
        return '✓';
    }
  }

  Color get color {
    switch (this) {
      case NutrientType.nitrogen:
        return AppColors.nitrogen;
      case NutrientType.phosphorus:
        return AppColors.phosphorus;
      case NutrientType.potassium:
        return AppColors.potassium;
      case NutrientType.healthy:
        return AppColors.healthy;
    }
  }

  IconData get icon {
    switch (this) {
      case NutrientType.nitrogen:
        return Icons.water_drop_outlined;
      case NutrientType.phosphorus:
        return Icons.local_florist_outlined;
      case NutrientType.potassium:
        return Icons.bolt_outlined;
      case NutrientType.healthy:
        return Icons.check_circle_outlined;
    }
  }

  String get description {
    switch (this) {
      case NutrientType.nitrogen:
        return 'Essential for leaf growth and chlorophyll production. '
            'Deficiency causes yellowing of older leaves (chlorosis) and stunted growth.';
      case NutrientType.phosphorus:
        return 'Vital for root development, flowering, and energy transfer. '
            'Deficiency causes dark green or purplish leaves and delayed maturity.';
      case NutrientType.potassium:
        return 'Important for disease resistance, water regulation, and fruit quality. '
            'Deficiency causes brown scorching on leaf margins.';
      case NutrientType.healthy:
        return 'No nutrient deficiency detected. The plant appears to be in good health.';
    }
  }

  /// Describes what a healthy leaf looks like for context.
  String get healthyDescription {
    switch (this) {
      case NutrientType.nitrogen:
        return 'Leaves are vibrant, dark green with uniform coloring. '
            'Older leaves remain healthy and attached.';
      case NutrientType.phosphorus:
        return 'Leaves show normal green color without purplish tint. '
            'Root system is strong with good branching.';
      case NutrientType.potassium:
        return 'Leaf margins are clean and intact. '
            'Stems are sturdy and fruits develop to full size.';
      case NutrientType.healthy:
        return 'The plant shows vibrant green foliage, strong stems, '
            'and normal growth patterns throughout.';
    }
  }

  /// Describes symptoms when this deficiency is present.
  String get affectedDescription {
    switch (this) {
      case NutrientType.nitrogen:
        return 'Older/lower leaves turn yellow (chlorosis). Plant growth is stunted '
            'with pale, light-green foliage and early leaf drop.';
      case NutrientType.phosphorus:
        return 'Leaves develop dark green or purplish coloring. Root growth is poor '
            'and flowering / maturity is delayed.';
      case NutrientType.potassium:
        return 'Brown scorching appears on leaf edges (marginal necrosis). '
            'Stems are weak and fruits are small or misshapen.';
      case NutrientType.healthy:
        return 'No visible deficiency symptoms.';
    }
  }

  /// Short symptom highlights for comparison badges and summary cards.
  List<String> get symptomHighlights {
    switch (this) {
      case NutrientType.nitrogen:
        return ['Yellow older leaves', 'Stunted growth', 'Pale foliage', 'Early leaf drop'];
      case NutrientType.phosphorus:
        return ['Purple/dark leaves', 'Poor roots', 'Delayed flowering', 'Stunted plant'];
      case NutrientType.potassium:
        return ['Brown leaf edges', 'Weak stems', 'Small fruits', 'Disease prone'];
      case NutrientType.healthy:
        return ['Vibrant green', 'Strong stems', 'Normal growth'];
    }
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  String toJsonString() => name;

  static NutrientType fromJsonString(String value) {
    // Exact match
    for (final type in NutrientType.values) {
      if (type.name == value.toLowerCase()) return type;
    }
    // Legacy labels that may exist in stored history
    const legacyMap = <String, NutrientType>{
      'calcium': NutrientType.potassium,   // closest substitute
      'magnesium': NutrientType.nitrogen,  // closest substitute
    };
    return legacyMap[value.toLowerCase()] ?? NutrientType.healthy;
  }
}
