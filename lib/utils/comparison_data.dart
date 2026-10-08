import '../models/nutrient.dart';

/// Static comparison data for the side-by-side comparison view.
class ComparisonData {
  ComparisonData._();

  /// Get comparison info for a given nutrient type.
  static LeafComparison getComparison(NutrientType nutrient) {
    return _comparisons[nutrient] ?? _defaultComparison;
  }

  static final Map<NutrientType, LeafComparison> _comparisons = {
    NutrientType.nitrogen: const LeafComparison(
      nutrient: NutrientType.nitrogen,
      healthyTraits: [
        'Rich, dark green color throughout',
        'Uniform coloring from tip to base',
        'Older leaves remain attached and green',
        'Strong, upright growth pattern',
      ],
      affectedTraits: [
        'Pale yellow-green color (chlorosis)',
        'Yellowing starts from older/lower leaves',
        'Premature leaf drop',
        'Stunted, weak growth',
      ],
      keyDifferences: [
        'Color: Dark green → Yellow-green',
        'Pattern: Uniform → Lower leaves first',
        'Growth: Vigorous → Stunted',
      ],
    ),
    NutrientType.phosphorus: const LeafComparison(
      nutrient: NutrientType.phosphorus,
      healthyTraits: [
        'Normal green leaf color',
        'Strong root system visible at base',
        'Flowers and fruits develop on schedule',
        'Good overall plant size',
      ],
      affectedTraits: [
        'Dark green to purplish leaf color',
        'Weak, underdeveloped roots',
        'Delayed flowering and maturity',
        'Stunted overall plant size',
      ],
      keyDifferences: [
        'Color: Green → Purple/dark',
        'Roots: Strong → Weak',
        'Maturity: On time → Delayed',
      ],
    ),
    NutrientType.potassium: const LeafComparison(
      nutrient: NutrientType.potassium,
      healthyTraits: [
        'Clean, intact leaf margins',
        'Strong, sturdy stems',
        'Full-sized, quality fruits',
        'Good disease resistance',
      ],
      affectedTraits: [
        'Brown scorching on leaf edges',
        'Weak stems that bend or break',
        'Small, misshapen fruits',
        'Increased disease susceptibility',
      ],
      keyDifferences: [
        'Edges: Clean → Brown/scorched',
        'Stems: Sturdy → Weak',
        'Fruits: Full-size → Small',
      ],
    ),

  };

  static const LeafComparison _defaultComparison = LeafComparison(
    nutrient: NutrientType.healthy,
    healthyTraits: [
      'Vibrant green foliage',
      'Strong stems and good structure',
      'Normal growth patterns',
      'No visible deficiency symptoms',
    ],
    affectedTraits: [
      'No symptoms detected',
    ],
    keyDifferences: [
      'Plant appears healthy — no comparison needed',
    ],
  );
}

/// Data class for leaf comparison between healthy and affected states.
class LeafComparison {
  final NutrientType nutrient;
  final List<String> healthyTraits;
  final List<String> affectedTraits;
  final List<String> keyDifferences;

  const LeafComparison({
    required this.nutrient,
    required this.healthyTraits,
    required this.affectedTraits,
    required this.keyDifferences,
  });
}
