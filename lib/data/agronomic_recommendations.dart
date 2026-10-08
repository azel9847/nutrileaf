import '../models/nutrient.dart';
import '../models/scan_result.dart';

/// Plain-language, crop-specific recommendations backed by agricultural references.
class AgronomicRecommendation {
  final String title;
  final List<String> actionSteps;
  final String citation;

  const AgronomicRecommendation({
    required this.title,
    required this.actionSteps,
    required this.citation,
  });
}

class AgronomicRecommendations {
  AgronomicRecommendations._();

  static AgronomicRecommendation forCondition(
    CropType crop,
    NutrientType condition,
  ) {
    return _treatmentPlans[condition] ??
        const AgronomicRecommendation(
          title: 'Agronomic guidance unavailable',
          actionSteps: ['Consult your local agricultural technician.'],
          citation: 'Local agricultural extension guidance',
        );
  }

  static const Map<NutrientType, AgronomicRecommendation> _treatmentPlans = {
    NutrientType.healthy: AgronomicRecommendation(
      title: 'Maintain Care',
      actionSteps: [
        'Water the plant regularly at the base of the soil in the morning.',
        'Apply a balanced fertilizer (like 14-14-14) every 2 weeks to keep it healthy.'
      ],
      citation: 'DA-BPI Crop Production Guides',
    ),
    NutrientType.nitrogen: AgronomicRecommendation(
      title: 'Add Nitrogen (N)',
      actionSteps: [
        'Apply Urea (46-0-0) fertilizer to help the leaves turn green again.',
        'Mix compost or animal manure into the soil for a natural nitrogen boost.',
        'Water the soil well after adding fertilizer so the roots can absorb it.'
      ],
      citation: 'DA-BPI Soil and Fertilizer Guidelines',
    ),
    NutrientType.potassium: AgronomicRecommendation(
      title: 'Add Potassium (K)',
      actionSteps: [
        'Apply Muriate of Potash (0-0-60) fertilizer to strengthen the plant stems.',
        'For a natural fix, mix wood ash or composted banana peels into the soil.',
        'Avoid overwatering the plant, as too much water washes potassium away.'
      ],
      citation: 'DA-BPI Soil and Fertilizer Guidelines',
    ),
    NutrientType.phosphorus: AgronomicRecommendation(
      title: 'Add Phosphorus (P)',
      actionSteps: [
        'Apply Superphosphate fertilizer to help the roots and flowers grow stronger.',
        'Mix bone meal into the soil as a natural source of phosphorus.',
        'Make sure the soil drains well; very wet soil traps phosphorus.'
      ],
      citation: 'DA-BPI Soil and Fertilizer Guidelines',
    ),
  };
}
