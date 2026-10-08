import '../models/nutrient.dart';
import '../models/scan_result.dart';

/// Fertilizer recommendation database keyed by nutrient type.
/// Crop-specific variants override the generic recommendations for key pairings.
class FertilizerData {
  FertilizerData._();

  /// Get a recommendation. If a crop-specific variant exists for the
  /// [type] + [crop] pairing, it is returned; otherwise falls back to generic.
  static FertilizerRecommendation getRecommendation(
    NutrientType type, {
    CropType? crop,
  }) {
    if (crop != null) {
      final cropMap = _cropSpecificRecommendations[crop];
      if (cropMap != null && cropMap.containsKey(type)) {
        return cropMap[type]!;
      }
    }
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

  // ─── Crop-Specific Recommendations ────────────────────────────────────────
  // Overrides the generic recommendations for specific crop + nutrient pairings.
  static final Map<CropType, Map<NutrientType, FertilizerRecommendation>>
      _cropSpecificRecommendations = {
    // ─── Talong (Eggplant) ─────────────────────────────────────────────────
    CropType.talong: {
      NutrientType.nitrogen: FertilizerRecommendation(
        nutrient: NutrientType.nitrogen,
        fertilizerName: 'Urea (46-0-0)',
        alternativeName: 'Ammonium Sulfate (21-0-0)',
        applicationRate: '30–50 kg N/ha split into 2–3 applications',
        applicationMethod: 'Side-dressing near the root zone; avoid crown contact',
        timing: 'At transplanting, 3 weeks after, and at first flower bud appearance',
        symptoms: [
          'Uniform yellowing of older/lower leaves (general chlorosis)',
          'Stunted plant with thin, pale-green stems',
          'Reduced branching and slow fruit set',
          'Small, dull-colored fruits',
        ],
        tips: [
          'Eggplant is a heavy nitrogen feeder — split applications reduce losses',
          'Apply early morning or late afternoon to minimize ammonia volatilization',
          'Water after granular urea application to move N into the root zone',
          'Foliar spray of 2% urea solution for rapid correction in severe cases',
          'Compost incorporation provides slow-release N and improves soil structure',
        ],
        safetyNotes: [
          'Wear gloves when handling urea granules',
          'Store urea in a cool, dry, sealed container',
          'Do not apply before heavy rain — risk of runoff and nitrogen loss',
        ],
        severity: 'High — limits leaf area, fruit number, and overall yield',
      ),
      NutrientType.potassium: FertilizerRecommendation(
        nutrient: NutrientType.potassium,
        fertilizerName: 'Muriate of Potash – MOP (0-0-60)',
        alternativeName: 'Sulfate of Potash – SOP (0-0-50)',
        applicationRate: '40–60 kg K₂O/ha split over 2 applications',
        applicationMethod: 'Side-dressing or banded near the root zone',
        timing: 'At transplanting and again at fruit development stage',
        symptoms: [
          'Marginal leaf scorch (brown, burnt edges on older leaves)',
          'Fruit skin bronzing or dull coloration',
          'Weak stems prone to lodging',
          'Increased disease susceptibility (especially Phytophthora)',
        ],
        tips: [
          'Potassium improves eggplant fruit skin quality and shelf life',
          'Use SOP if chloride-sensitive soil conditions are suspected',
          'Avoid over-application — excess K blocks Mg and Ca uptake',
          'Wood ash provides organic K for small-scale plots (2–3 kg/plant area)',
          'Split into 2 doses for better efficiency on sandy soils',
        ],
        safetyNotes: [
          'MOP can irritate skin — wear protective gloves',
          'Store in a dry location to prevent clumping',
          'Avoid excessive rates — can increase soil salinity',
        ],
        severity: 'Moderate-High — affects fruit quality, disease resistance, and yield',
      ),
    },
    // ─── Ampalaya (Bitter Melon) ────────────────────────────────────────────
    CropType.ampalaya: {
      NutrientType.potassium: FertilizerRecommendation(
        nutrient: NutrientType.potassium,
        fertilizerName: 'Muriate of Potash – MOP (0-0-60)',
        alternativeName: 'Sulfate of Potash – SOP (0-0-50)',
        applicationRate: '40–60 kg K₂O/ha split over 2 applications',
        applicationMethod: 'Side-dressing along vine row or banded near roots',
        timing: 'First dose at vine training (2–3 weeks after transplant); second at flowering',
        symptoms: [
          'Brown or necrotic scorching along leaf margins (leaf edge burn)',
          'Bitter ampalaya fruit with irregular shape or poor fill',
          'Weak, thin vines prone to breakage',
          'Increased susceptibility to powdery mildew and other diseases',
        ],
        tips: [
          'Potassium regulates bitterness compounds in ampalaya fruit — K deficiency alters flavor',
          'Strong vines need K for climbing and trellis support — prioritize at vine training',
          'Use SOP if soil Cl levels are already high',
          'Wood ash is a traditional organic K source — 2–3 kg/plant area',
          'Avoid excessive K which can interfere with Mg uptake',
        ],
        safetyNotes: [
          'Wear gloves when handling MOP granules',
          'MOP can increase soil salinity — avoid over-application',
          'Keep away from water sources — soluble and can contaminate irrigation water',
        ],
        severity: 'High — affects vine vigour, disease resistance, and fruit quality',
      ),
      NutrientType.nitrogen: FertilizerRecommendation(
        nutrient: NutrientType.nitrogen,
        fertilizerName: 'Urea (46-0-0)',
        alternativeName: 'Ammonium Sulfate (21-0-0)',
        applicationRate: '30–50 kg N/ha split into 2–3 applications',
        applicationMethod: 'Side-dressing along vine row; avoid placing near crown',
        timing: 'At transplanting, at vine training (2–3 wks), and at flowering',
        symptoms: [
          'Pale yellow-green leaves especially on older vines and lower canopy',
          'Slow vine extension and reduced internode length',
          'Few female flowers and poor fruit set',
          'Thin vines with weak tendrils',
        ],
        tips: [
          'Ampalaya vines require steady N supply during rapid growth phase',
          'Split applications reduce volatilization loss and over-vegetative growth',
          'Water after granular application to move N into the root zone',
          'Reduce N at heavy fruiting to avoid excessive vine growth over fruit',
          'Compost mulch provides slow-release N and conserves soil moisture',
        ],
        safetyNotes: [
          'Wear gloves when applying urea',
          'Do not apply before heavy rain — runoff waste and pollution risk',
          'Store in a dry, sealed container away from children',
        ],
        severity: 'High — limits vine growth, flower production, and fruit number',
      ),
    },
  };
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
