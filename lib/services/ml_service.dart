import 'dart:math';
import '../models/nutrient.dart';
import '../models/scan_result.dart';

/// ML Service that handles model inference.
///
/// Currently operates in simulation mode with realistic mock predictions.
/// To integrate a real TFLite model:
///   1. Place your .tflite model in assets/models/
///   2. Set [useSimulation] to false
///   3. Implement [_runRealInference]
class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  /// Toggle between simulation and real model inference.
  final bool useSimulation = true;

  bool _isModelLoaded = false;

  /// Initialize the ML model.
  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    if (useSimulation) {
      // Simulate model loading delay
      await Future.delayed(const Duration(milliseconds: 500));
      _isModelLoaded = true;
      return;
    }

    // TODO: Real TFLite model loading
    // final interpreter = await Interpreter.fromAsset('assets/models/nutrileaf_model.tflite');
    _isModelLoaded = true;
  }

  /// Run inference on the given image path.
  /// Returns a [ScanResult] with detected nutrient and confidence scores.
  Future<ScanResult> analyzeImage(String imagePath, {CropType? cropType}) async {
    if (!_isModelLoaded) await loadModel();

    if (useSimulation) {
      return _runSimulatedInference(imagePath, cropType: cropType);
    } else {
      return _runRealInference(imagePath);
    }
  }

  /// Simulated inference that generates realistic predictions.
  Future<ScanResult> _runSimulatedInference(String imagePath, {CropType? cropType}) async {
    // Simulate processing time (1.5 - 3 seconds)
    final random = Random();
    final processingTime = 1500 + random.nextInt(1500);
    await Future.delayed(Duration(milliseconds: processingTime));

    // Generate realistic prediction distribution
    final predictions = _generateRealisticPredictions(random);

    // Find the top prediction
    NutrientType topNutrient = NutrientType.healthy;
    double topConfidence = 0;
    predictions.forEach((nutrient, confidence) {
      if (confidence > topConfidence) {
        topConfidence = confidence;
        topNutrient = nutrient;
      }
    });

    // Assign crop type: use provided or random
    final assignedCrop = cropType ?? CropType.values[random.nextInt(CropType.values.length)];

    return ScanResult(
      imagePath: imagePath,
      detectedNutrient: topNutrient,
      confidence: topConfidence,
      allPredictions: predictions,
      cropType: assignedCrop,
    );
  }

  /// Generate a realistic probability distribution across all nutrient types.
  Map<NutrientType, double> _generateRealisticPredictions(Random random) {
    // Pick a dominant class randomly (weighted toward deficiencies for demo)
    final nutrientTypes = NutrientType.values;
    final dominantIndex = random.nextInt(nutrientTypes.length);
    final dominant = nutrientTypes[dominantIndex];

    // Generate raw scores with dominant class having high probability
    final rawScores = <NutrientType, double>{};
    double sum = 0;

    for (final nutrient in nutrientTypes) {
      double score;
      if (nutrient == dominant) {
        // Dominant class: 60-95% raw score
        score = 0.6 + random.nextDouble() * 0.35;
      } else {
        // Other classes: 1-15% raw score
        score = 0.01 + random.nextDouble() * 0.14;
      }
      rawScores[nutrient] = score;
      sum += score;
    }

    // Normalize to sum to 1.0 (softmax-like)
    final predictions = <NutrientType, double>{};
    rawScores.forEach((nutrient, score) {
      predictions[nutrient] = double.parse((score / sum).toStringAsFixed(4));
    });

    return predictions;
  }

  /// Real TFLite model inference — implement when model is available.
  Future<ScanResult> _runRealInference(String imagePath) async {
    // TODO: Implement real inference
    // 1. Load and preprocess image (resize to 224x224, normalize)
    // 2. Run interpreter.run(input, output)
    // 3. Parse output tensor into predictions map
    // 4. Return ScanResult

    throw UnimplementedError(
      'Real model inference not yet implemented. '
      'Set useSimulation = true or implement this method.',
    );
  }

  /// Dispose resources.
  void dispose() {
    _isModelLoaded = false;
    // TODO: interpreter?.close();
  }
}
