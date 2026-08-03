import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Represents the types of nutrient deficiencies the app can detect.
enum NutrientType {
  nitrogen,
  phosphorus,
  potassium,
  calcium,
  magnesium,
  healthy,
}

/// Extension providing display properties for each nutrient type.
extension NutrientTypeExtension on NutrientType {
  String get displayName {
    switch (this) {
      case NutrientType.nitrogen:
        return 'Nitrogen (N)';
      case NutrientType.phosphorus:
        return 'Phosphorus (P)';
      case NutrientType.potassium:
        return 'Potassium (K)';
      case NutrientType.calcium:
        return 'Calcium (Ca)';
      case NutrientType.magnesium:
        return 'Magnesium (Mg)';
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
      case NutrientType.calcium:
        return 'Ca';
      case NutrientType.magnesium:
        return 'Mg';
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
      case NutrientType.calcium:
        return AppColors.calcium;
      case NutrientType.magnesium:
        return AppColors.magnesium;
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
      case NutrientType.calcium:
        return Icons.shield_outlined;
      case NutrientType.magnesium:
        return Icons.wb_sunny_outlined;
      case NutrientType.healthy:
        return Icons.check_circle_outlined;
    }
  }

  String get description {
    switch (this) {
      case NutrientType.nitrogen:
        return 'Essential for leaf growth and chlorophyll production. Deficiency causes yellowing of older leaves.';
      case NutrientType.phosphorus:
        return 'Vital for root development and flowering. Deficiency causes purple/dark leaves and stunted growth.';
      case NutrientType.potassium:
        return 'Important for disease resistance and fruit quality. Deficiency causes brown leaf edges.';
      case NutrientType.calcium:
        return 'Needed for cell wall structure and new growth. Deficiency causes distorted new leaves.';
      case NutrientType.magnesium:
        return 'Central to chlorophyll molecule. Deficiency causes interveinal chlorosis on older leaves.';
      case NutrientType.healthy:
        return 'No nutrient deficiency detected. The plant appears to be in good health.';
    }
  }

  /// Description of what a healthy leaf looks like for this nutrient context.
  String get healthyDescription {
    switch (this) {
      case NutrientType.nitrogen:
        return 'Leaves are vibrant, dark green with uniform coloring. Older leaves remain healthy and attached.';
      case NutrientType.phosphorus:
        return 'Leaves show normal green color without purplish tint. Root system is strong with good branching.';
      case NutrientType.potassium:
        return 'Leaf margins are clean and intact. Stems are sturdy and fruits develop to full size.';
      case NutrientType.calcium:
        return 'New growth emerges straight and undistorted. No blossom end rot on fruits.';
      case NutrientType.magnesium:
        return 'Leaves are uniformly green between veins. No yellowing or reddish-purple coloring visible.';
      case NutrientType.healthy:
        return 'The plant shows vibrant green foliage, strong stems, and normal growth patterns throughout.';
    }
  }

  /// Description of what an affected leaf looks like.
  String get affectedDescription {
    switch (this) {
      case NutrientType.nitrogen:
        return 'Older/lower leaves turn yellow (chlorosis). Plant growth is stunted with pale, light green foliage.';
      case NutrientType.phosphorus:
        return 'Leaves develop dark green or purplish coloring. Root growth is poor and maturity is delayed.';
      case NutrientType.potassium:
        return 'Brown scorching appears on leaf edges. Stems are weak and fruits are small or misshapen.';
      case NutrientType.calcium:
        return 'New growth is curled or distorted. Tip burn on young leaves and blossom end rot on fruits.';
      case NutrientType.magnesium:
        return 'Yellowing between veins on older leaves (interveinal chlorosis). Leaves may curl upward.';
      case NutrientType.healthy:
        return 'No visible deficiency symptoms.';
    }
  }

  /// Short symptom highlights for comparison badges.
  List<String> get symptomHighlights {
    switch (this) {
      case NutrientType.nitrogen:
        return ['Yellow older leaves', 'Stunted growth', 'Pale foliage', 'Early leaf drop'];
      case NutrientType.phosphorus:
        return ['Purple leaves', 'Poor roots', 'Delayed flowering', 'Stunted plant'];
      case NutrientType.potassium:
        return ['Brown leaf edges', 'Weak stems', 'Small fruits', 'Disease prone'];
      case NutrientType.calcium:
        return ['Curled new leaves', 'Tip burn', 'Blossom end rot', 'Poor roots'];
      case NutrientType.magnesium:
        return ['Yellow between veins', 'Red-purple color', 'Curling leaves', 'Leaf drop'];
      case NutrientType.healthy:
        return ['Vibrant green', 'Strong stems', 'Normal growth'];
    }
  }

  String toJsonString() => name;

  static NutrientType fromJsonString(String value) {
    return NutrientType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NutrientType.healthy,
    );
  }
}
