import '../models/nutrient.dart';

/// Fertilizer recommendation database keyed by nutrient type.
class FertilizerData {
  FertilizerData._();

  static FertilizerRecommendation getRecommendation(NutrientType type) {
    return _recommendations[type] ?? _healthyRecommendation;
  }

  static final Map<NutrientType, FertilizerRecommendation> _recommendations = {
    NutrientType.nitrogen: FertilizerRecommendation(
      nutrient: NutrientType.nitrogen,
      fertilizerName: 'Urea (46-0-0)',
      alternativeName: 'Ammonium Sulfate (21-0-0)',
      applicationRate: '30–50 kg per hectare',
      applicationMethod: 'Side-dressing or top-dressing',
      timing: 'Apply during active vegetative growth stage',
      symptoms: [
        'Yellowing of older/lower leaves (chlorosis)',
        'Stunted plant growth',
        'Light green foliage overall',
        'Premature leaf drop',
      ],
      tips: [
        'Split application into 2–3 doses for better absorption',
        'Apply early morning or late afternoon to reduce volatilization',
        'Water the field after application for better uptake',
        'Avoid applying before heavy rain to prevent runoff',
        'Consider foliar spray (2% urea solution) for quick correction',
      ],
      safetyNotes: [
        'Wear gloves when handling fertilizer',
        'Avoid direct skin contact — wash immediately if exposed',
        'Store in a cool, dry place away from children',
        'Do not mix with lime or alkaline materials',
      ],
      severity: 'Common in most crops; address within 1–2 weeks',
    ),
    NutrientType.phosphorus: FertilizerRecommendation(
      nutrient: NutrientType.phosphorus,
      fertilizerName: 'DAP (18-46-0)',
      alternativeName: 'Single Super Phosphate (SSP)',
      applicationRate: '40–60 kg per hectare',
      applicationMethod: 'Basal application or band placement',
      timing: 'Apply before planting or at early growth stage',
      symptoms: [
        'Dark green or purplish leaves',
        'Poor root development',
        'Delayed maturity and flowering',
        'Reduced fruit/seed production',
      ],
      tips: [
        'Apply phosphorus close to the root zone for best uptake',
        'Maintain soil pH between 6.0–7.0 for optimal availability',
        'Bone meal is an excellent organic alternative',
        'Phosphorus is immobile in soil — place it, don\'t broadcast',
        'Mycorrhizal fungi can improve phosphorus uptake naturally',
      ],
      safetyNotes: [
        'Handle DAP in a well-ventilated area',
        'Avoid inhaling dust — wear a mask if needed',
        'Wash hands thoroughly after handling',
        'Keep away from water sources to prevent contamination',
      ],
      severity: 'Moderate severity; address before flowering stage',
    ),
    NutrientType.potassium: FertilizerRecommendation(
      nutrient: NutrientType.potassium,
      fertilizerName: 'MOP – Muriate of Potash (0-0-60)',
      alternativeName: 'Sulfate of Potash (SOP)',
      applicationRate: '40–80 kg per hectare',
      applicationMethod: 'Broadcasting or side-dressing',
      timing: 'Apply at planting or during fruiting stage',
      symptoms: [
        'Brown scorching on leaf edges (leaf margin burn)',
        'Weak stems that lodge easily',
        'Poor fruit quality and size',
        'Increased susceptibility to diseases',
      ],
      tips: [
        'Potassium improves drought resistance and disease tolerance',
        'Use SOP for chloride-sensitive crops (tobacco, fruits)',
        'Wood ash is a natural potassium source for small plots',
        'Avoid excess — it can interfere with Mg and Ca uptake',
        'Apply in split doses for sandy soils to reduce leaching',
      ],
      safetyNotes: [
        'MOP can be irritating to skin — use protective gloves',
        'Avoid excessive application — can increase soil salinity',
        'Store in a dry location to prevent clumping',
        'Keep away from chloride-sensitive crops',
      ],
      severity: 'High importance during fruiting; address promptly',
    ),
    NutrientType.calcium: FertilizerRecommendation(
      nutrient: NutrientType.calcium,
      fertilizerName: 'Gypsum (Calcium Sulfate)',
      alternativeName: 'Agricultural Lime (CaCO₃)',
      applicationRate: '200–500 kg per hectare',
      applicationMethod: 'Broadcasting and incorporation into soil',
      timing: 'Apply 2–4 weeks before planting',
      symptoms: [
        'Distorted or curled new growth',
        'Blossom end rot in tomatoes/peppers',
        'Tip burn on young leaves',
        'Poor root development',
      ],
      tips: [
        'Calcium is immobile in the plant — new growth shows symptoms first',
        'Foliar calcium sprays (CaCl₂) provide quick relief',
        'Maintain consistent watering — drought worsens Ca deficiency',
        'Lime also raises soil pH; use gypsum if pH is already optimal',
        'Eggshell compost provides slow-release calcium for gardens',
      ],
      safetyNotes: [
        'Lime dust can irritate eyes — wear eye protection',
        'Gypsum is generally safe but avoid inhalation',
        'Test soil pH before applying lime to avoid over-correction',
        'Apply lime well before planting for best results',
      ],
      severity: 'Address immediately if blossom end rot is visible',
    ),
    NutrientType.magnesium: FertilizerRecommendation(
      nutrient: NutrientType.magnesium,
      fertilizerName: 'Epsom Salt (MgSO₄)',
      alternativeName: 'Dolomite Lime (CaMg(CO₃)₂)',
      applicationRate: '10–25 kg per hectare (foliar: 2% solution)',
      applicationMethod: 'Foliar spray or soil application',
      timing: 'Apply when interveinal chlorosis appears',
      symptoms: [
        'Interveinal chlorosis on older leaves (yellowing between green veins)',
        'Reddish-purple leaf coloring',
        'Leaves curling upward',
        'Early leaf drop',
      ],
      tips: [
        'Epsom salt foliar spray gives fastest results (dissolve 20g/L)',
        'Dolomite lime provides both Ca and Mg and raises pH',
        'High potassium can block magnesium uptake — check K:Mg ratio',
        'Sandy and acidic soils are most prone to Mg deficiency',
        'Magnesium is central to chlorophyll — essential for photosynthesis',
      ],
      safetyNotes: [
        'Epsom salt is generally safe for handling',
        'Avoid applying foliar sprays in direct strong sunlight',
        'Dolomite lime can raise soil pH — test before applying',
        'Keep fertilizers out of reach of children and animals',
      ],
      severity: 'Moderate; affects photosynthesis if left untreated',
    ),
  };

  static final FertilizerRecommendation _healthyRecommendation =
      FertilizerRecommendation(
    nutrient: NutrientType.healthy,
    fertilizerName: 'No fertilizer needed',
    alternativeName: 'Balanced NPK maintenance',
    applicationRate: 'Standard maintenance schedule',
    applicationMethod: 'Regular balanced fertilization',
    timing: 'Follow crop-specific schedules',
    symptoms: [
      'Leaves appear healthy and vibrant green',
      'Good overall plant vigor',
      'Normal growth patterns',
    ],
    tips: [
      'Continue regular monitoring for early detection',
      'Maintain balanced soil nutrition with periodic soil testing',
      'Rotate crops to preserve soil health',
      'Use organic mulch to maintain soil moisture and nutrients',
      'Great job keeping your plants healthy! 🌱',
    ],
    safetyNotes: [
      'Always wear gloves when handling any fertilizer',
      'Store fertilizers properly to maintain effectiveness',
    ],
    severity: 'No action required — plant looks healthy!',
  );
}

/// Data class for a fertilizer recommendation.
class FertilizerRecommendation {
  final NutrientType nutrient;
  final String fertilizerName;
  final String alternativeName;
  final String applicationRate;
  final String applicationMethod;
  final String timing;
  final List<String> symptoms;
  final List<String> tips;
  final List<String> safetyNotes;
  final String severity;

  const FertilizerRecommendation({
    required this.nutrient,
    required this.fertilizerName,
    required this.alternativeName,
    required this.applicationRate,
    required this.applicationMethod,
    required this.timing,
    required this.symptoms,
    required this.tips,
    this.safetyNotes = const [],
    required this.severity,
  });
}
