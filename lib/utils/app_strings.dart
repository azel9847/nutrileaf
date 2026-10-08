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
    'select_crop_heading': {en: 'Which crop are you scanning?', fil: 'Anong pananim ang iyong sini-scan?'},
    'select_crop_hint': {en: 'Select your crop for accurate detection', fil: 'Pumili ng pananim para sa tumpak na pagtukoy'},
    'tips_title': {en: 'Tips for Best Results', fil: 'Mga Tip para sa Magandang Resulta'},

    // ── Pre-Scan Guidance Modal ──
    'scan_tips_modal_title': {en: 'Before You Scan', fil: 'Bago Mag-scan'},
    'scan_tips_modal_subtitle': {
      en: 'Follow these tips for the most accurate results',
      fil: 'Sundin ang mga tip na ito para sa pinaka-tumpak na resulta',
    },
    'tip_clear_focus_title': {en: 'Clear & Focused', fil: 'Malinaw at Nakatuon'},
    'tip_clear_focus_desc': {
      en: 'Ensure the leaf is sharp and in focus',
      fil: 'Siguraduhing malinaw at nakatuon ang dahon',
    },
    'tip_one_leaf_title': {en: 'One Leaf Only', fil: 'Isang Dahon Lamang'},
    'tip_one_leaf_desc': {
      en: 'Capture a single, isolated leaf',
      fil: 'Kumuha ng iisang dahon na nakahiwalay',
    },
    'tip_good_lighting_title': {en: 'Good Lighting', fil: 'Magandang Ilaw'},
    'tip_good_lighting_desc': {
      en: 'Use natural daylight and avoid shadows',
      fil: 'Gumamit ng natural na liwanag, iwasan ang anino',
    },
    'tip_correct_crop_title': {en: 'Correct Crop Selected', fil: 'Tamang Pananim ang Pinili'},
    'tip_correct_crop_desc': {
      en: 'Select your crop type before scanning',
      fil: 'Piliin ang uri ng pananim bago mag-scan',
    },
    'tips_dont_show': {en: 'Don\'t show again', fil: 'Huwag nang ipakita'},
    'tips_got_it': {en: 'Got it, Let\'s Scan!', fil: 'Naintindihan, Mag-scan Na!'},

    // ── Crop Names ──
    'crop_ampalaya':  {en: 'Ampalaya',    fil: 'Ampalaya'},
    'crop_eggplant':  {en: 'Eggplant',    fil: 'Talong'},
    'crop_ashGourd':  {en: 'Ash Gourd',   fil: 'Kundol'},
    'crop_snakeGourd':{en: 'Snake Gourd', fil: 'Patola'},
    'crop_tomato':    {en: 'Tomato',      fil: 'Kamatis'},

    // ── Results ──
    'detected_condition': {en: 'Detected Condition', fil: 'Natukoy na Kondisyon'},
    'treatment_plan': {en: 'Treatment Plan', fil: 'Plano ng Paggamot'},
    'common_symptoms': {en: 'Common Symptoms', fil: 'Mga Karaniwang Sintomas'},
    'scan_again': {en: 'Scan Again', fil: 'Mag-scan Muli'},
    'low_confidence': {
      en: 'Low confidence — consider rescanning with better lighting',
      fil: 'Mababang kumpiyansa — subukang mag-scan muli nang may maliwanag',
    },
    'retake_low_confidence': {
      en: 'Confidence is low. For best results, retake the image with better lighting.',
      fil: 'Mababang kumpiyansa. Para sa mas tumpak na resulta, kumuha muli ng larawan.',
    },
    'retake_action': {en: 'Retake Image', fil: 'Kumuha Muli'},
    'continue_anyway': {en: 'Continue', fil: 'Magpatuloy'},
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

    // ── Image Preview ──
    'preview_title': {en: 'Preview', fil: 'Preview'},
    'preview_subtitle': {
      en: 'Review your image before scanning',
      fil: 'Suriin ang larawan bago mag-scan',
    },
    'scan_now': {en: 'Scan Now', fil: 'I-scan Na'},
    'change_image': {en: 'Change Image', fil: 'Palitan ang Larawan'},
    'preview_error_title': {en: 'Image Unavailable', fil: 'Hindi Available ang Larawan'},
    'preview_error_desc': {
      en: 'The selected image could not be loaded. Please choose a different file.',
      fil: 'Hindi ma-load ang larawang ito. Pumili ng ibang file.',
    },

    // ── Image Validation ──
    'img_validating': {en: 'Validating image...', fil: 'Sinusuri ang larawan...'},
    'img_verified': {en: 'Image verified', fil: 'Na-verify ang larawan'},
    'img_invalid_format': {
      en: 'Invalid image format. Please use JPG or PNG.',
      fil: 'Hindi wastong format. Gumamit ng JPG o PNG.',
    },
    'img_too_small': {
      en: 'Image file is too small or may be corrupted.',
      fil: 'Masyadong maliit ang file o maaaring sira.',
    },
    'img_too_large': {
      en: 'Image file exceeds 20 MB. Please use a smaller image.',
      fil: 'Lumampas sa 20 MB ang file. Gumamit ng mas maliit na larawan.',
    },
    'img_low_resolution': {
      en: 'Image resolution too low. Minimum 224×224 required.',
      fil: 'Masyadong mababa ang resolusyon. Kailangan ng minimum 224×224.',
    },
    'img_not_leaf': {
      en: 'This image may not contain a plant leaf. Proceed with caution.',
      fil: 'Maaaring walang dahon sa larawang ito. Mag-ingat sa pagpapatuloy.',
    },
    'img_validation_failed': {
      en: 'Image validation failed',
      fil: 'Hindi pumasa ang pag-verify ng larawan',
    },
    'img_decode_failed': {
      en: 'Unable to read image. The file may be corrupted.',
      fil: 'Hindi mabasa ang larawan. Maaaring sira ang file.',
    },

    // ── Registration / Login ──
    'create_account': {en: 'Create Account', fil: 'Gumawa ng Account'},
    'skip_for_now': {en: 'Skip for now', fil: 'Laktawan muna'},
    'email_available': {en: 'Email available', fil: 'Available ang email'},
    'email_taken': {en: 'Email already registered', fil: 'Nakarehistrong email na'},
    'login': {en: 'Login', fil: 'Mag-login'},
    'log_in': {en: 'Log In', fil: 'Mag-log In'},
    'welcome_back_login': {en: 'Welcome back', fil: 'Maligayang pagbabalik'},
    'continue_with_google': {en: 'Continue with Google', fil: 'Magpatuloy gamit ang Google'},
    'dont_have_account': {en: 'Don\'t have an account? ', fil: 'Walang account? '},
    'sign_up': {en: 'Sign up', fil: 'Mag-sign up'},
    'already_have_account': {en: 'Already have an account? ', fil: 'May account na? '},
    'passwords_do_not_match': {en: 'Passwords do not match', fil: 'Hindi magkatugma ang password'},

    // ── Feedback ──
    'help_improve': {en: 'Help Us Improve', fil: 'Tulungan Kaming Mag-improve'},
    'was_accurate': {en: 'Was this diagnosis accurate?', fil: 'Tama ba ang diagnosis na ito?'},
    'yes_correct': {en: 'Yes, correct', fil: 'Oo, tama'},
    'no_incorrect': {en: 'No, incorrect', fil: 'Hindi, mali'},
    'correct_diagnosis': {en: 'What\'s the correct diagnosis?', fil: 'Ano ang tamang diagnosis?'},
    'additional_notes': {en: 'Any additional notes? (optional)', fil: 'May dagdag na tala? (opsyonal)'},
    'submit_feedback': {en: 'Submit Feedback', fil: 'Isumite ang Feedback'},
    'feedback_thanks': {en: 'Thank you! 🌿', fil: 'Salamat! 🌿'},
    'feedback_saved': {
      en: 'Your feedback helps improve our AI for everyone.',
      fil: 'Ang iyong feedback ay tumutulong sa pagpapabuti ng aming AI.',
    },
  };

  /// Get a localized string. Falls back to English if key or language not found.
  static String get(String key, [String language = en]) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[language] ?? entry[en] ?? key;
  }
}
