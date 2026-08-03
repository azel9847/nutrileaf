/// Lightweight English / Filipino string maps for key UI text.
/// Toggle via SettingsService.language ('en' or 'fil').
class AppStrings {
  AppStrings._();

  static const String en = 'en';
  static const String fil = 'fil';

  static final Map<String, Map<String, String>> _strings = {
    // ── Navigation ──
    'nav_home': {en: 'Home', fil: 'Home'},
    'nav_scan': {en: 'Scan', fil: 'I-scan'},
    'nav_history': {en: 'History', fil: 'Kasaysayan'},
    'nav_analytics': {en: 'Analytics', fil: 'Analytics'},
    'nav_settings': {en: 'Settings', fil: 'Settings'},

    // ── Home ──
    'welcome_title': {en: 'Welcome back! 🌿', fil: 'Maligayang pagbabalik! 🌿'},
    'welcome_subtitle': {
      en: 'Scan a leaf to detect nutrient deficiencies',
      fil: 'Mag-scan ng dahon para ma-detect ang kakulangan sa sustansya',
    },
    'scan_leaf': {en: 'Scan Leaf', fil: 'I-scan ang Dahon'},
    'upload_image': {en: 'Upload Image', fil: 'Mag-upload ng Larawan'},
    'recent_scans': {en: 'Recent Scans', fil: 'Mga Kamakailang Scan'},
    'view_all': {en: 'View All', fil: 'Tingnan Lahat'},
    'how_it_works': {en: 'How It Works', fil: 'Paano Gumagana'},
    'total_scans': {en: 'Total Scans', fil: 'Kabuuang Scan'},
    'nutrients': {en: 'Nutrients', fil: 'Sustansya'},
    'ai_accuracy': {en: 'AI Accuracy', fil: 'AI Accuracy'},
    'crop_categories': {en: 'Crop Categories', fil: 'Uri ng Pananim'},

    // ── Scan ──
    'scan_title': {en: 'Scan Leaf', fil: 'I-scan ang Dahon'},
    'take_photo': {en: 'Take Photo', fil: 'Kumuha ng Litrato'},
    'from_gallery': {en: 'Upload Image', fil: 'Mula sa Gallery'},
    'analyze_ai': {en: 'Analyze with AI', fil: 'Suriin gamit ang AI'},
    'analyzing': {en: 'Analyzing...', fil: 'Sinusuri...'},
    'place_leaf': {en: 'Place leaf inside the frame', fil: 'Ilagay ang dahon sa frame'},
    'ensure_light': {en: 'Ensure good lighting', fil: 'Siguraduhing maliwanag'},
    'retake': {en: 'Retake', fil: 'Kumuha Ulit'},
    'confirm': {en: 'Confirm', fil: 'Kumpirmahin'},
    'select_crop': {en: 'Select crop type', fil: 'Pumili ng uri ng pananim'},
    'tips_title': {en: 'Tips for Best Results', fil: 'Mga Tip para sa Magandang Resulta'},

    // ── Results ──
    'confidence_level': {en: 'Confidence Level', fil: 'Antas ng Kumpiyansa'},
    'all_predictions': {en: 'All Predictions', fil: 'Lahat ng Prediksiyon'},
    'treatment_plan': {en: 'Treatment Plan', fil: 'Plano ng Paggamot'},
    'common_symptoms': {en: 'Common Symptoms', fil: 'Mga Karaniwang Sintomas'},
    'scan_again': {en: 'Scan Again', fil: 'Mag-scan Muli'},
    'compare_healthy': {en: 'Compare with Healthy', fil: 'Ihambing sa Malusog'},
    'low_confidence': {
      en: 'Low confidence — consider rescanning with better lighting',
      fil: 'Mababang kumpiyansa — subukang mag-scan muli nang may maliwanag',
    },
    'saved_history': {en: 'Scan saved to history!', fil: 'Na-save sa kasaysayan!'},
    'healthy_plant': {en: 'Healthy Plant', fil: 'Malusog na Halaman'},
    'deficiency': {en: 'Deficiency', fil: 'Kakulangan'},

    // ── History ──
    'scan_history': {en: 'Scan History', fil: 'Kasaysayan ng Scan'},
    'no_scans': {en: 'No Scans Yet', fil: 'Wala Pang Scan'},
    'no_scans_desc': {
      en: 'Your scan history will appear here\nafter you analyze your first leaf.',
      fil: 'Makikita dito ang mga na-scan\npagkatapos ng unang pagsusuri.',
    },
    'start_scanning': {en: 'Start Scanning', fil: 'Magsimulang Mag-scan'},
    'clear_all': {en: 'Clear All', fil: 'Burahin Lahat'},
    'clear_confirm': {
      en: 'Are you sure you want to delete all scan history? This action cannot be undone.',
      fil: 'Sigurado ka bang gusto mong burahin lahat? Hindi na ito maibabalik.',
    },
    'cancel': {en: 'Cancel', fil: 'Kanselahin'},
    'all_crops': {en: 'All', fil: 'Lahat'},

    // ── Comparison ──
    'comparison_title': {en: 'Leaf Comparison', fil: 'Paghahambing ng Dahon'},
    'healthy_leaf': {en: 'Healthy Leaf', fil: 'Malusog na Dahon'},
    'affected_leaf': {en: 'Affected Leaf', fil: 'Apektadong Dahon'},
    'key_differences': {en: 'Key Differences', fil: 'Mahahalagang Pagkakaiba'},

    // ── Analytics ──
    'analytics_title': {en: 'Analytics', fil: 'Analytics'},
    'most_common': {en: 'Most Common Deficiency', fil: 'Pinakakaraniwang Kakulangan'},
    'scans_by_crop': {en: 'Scans by Crop', fil: 'Scan ayon sa Pananim'},
    'deficiency_dist': {en: 'Deficiency Distribution', fil: 'Distribusyon ng Kakulangan'},
    'no_data': {en: 'No data yet', fil: 'Wala pang datos'},

    // ── Settings ──
    'settings_title': {en: 'Settings', fil: 'Settings'},
    'how_to_use': {en: 'How to Use', fil: 'Paano Gamitin'},
    'appearance': {en: 'Appearance', fil: 'Hitsura'},
    'dark_mode': {en: 'Dark Mode', fil: 'Dark Mode'},
    'language': {en: 'Language', fil: 'Wika'},
    'english': {en: 'English', fil: 'English'},
    'filipino': {en: 'Filipino', fil: 'Filipino'},
    'about': {en: 'About', fil: 'Tungkol'},
    'app_tagline': {
      en: 'Smart Nutrient Detection for Smarter Farming',
      fil: 'Matalinong Pagtukoy ng Sustansya para sa Mas Matalinong Pagsasaka',
    },
    'step1_title': {en: 'Capture', fil: 'Kumuha'},
    'step1_desc': {en: 'Take a photo or upload a leaf image', fil: 'Kumuha ng litrato o mag-upload ng dahon'},
    'step2_title': {en: 'Analyze', fil: 'Suriin'},
    'step2_desc': {en: 'AI scans for nutrient deficiencies', fil: 'Sinusuri ng AI ang kakulangan sa sustansya'},
    'step3_title': {en: 'Results', fil: 'Resulta'},
    'step3_desc': {en: 'Get detailed results and recommendations', fil: 'Kumuha ng detalyadong resulta at rekomendasyon'},
  };

  /// Get a localized string. Falls back to English if key or language not found.
  static String get(String key, [String language = en]) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[language] ?? entry[en] ?? key;
  }
}
