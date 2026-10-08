import 'dart:convert';

import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // added for debugPrint
import '../utils/api_config.dart';

// ---------------------------------------------------------------------------
// Data Model
// ---------------------------------------------------------------------------

/// Strongly-typed response from the HHC-VNDC backend /predict endpoint.
///
/// Represents a complete two-stage diagnosis:
///   Stage 1 — Vegetable identification (5 classes)
///   Stage 2 — Nutrient deficiency classification (4 classes)
class HhcPrediction {
  /// Detected vegetable (Ampalaya | Kalabasa | Okra | Sitaw | Talong).
  final String vegetable;

  /// Stage-1 top-class softmax confidence [0.0 – 1.0].
  final double vegetableConfidence;

  /// Full softmax distribution over all 5 vegetable classes.
  final Map<String, double> vegetableProbabilities;

  /// Diagnosed condition (healthy | nitrogen | phosphorus | potassium).
  final String diagnosedDeficiency;

  /// Stage-2 top-class softmax confidence [0.0 – 1.0].
  final double deficiencyConfidence;

  /// Full softmax distribution over all 4 deficiency classes.
  final Map<String, double> deficiencyProbabilities;

  /// Public URL of the uploaded image in Supabase Storage.
  /// Null when the backend is not configured with Supabase credentials.
  final String? imageUrl;

  const HhcPrediction({
    required this.vegetable,
    required this.vegetableConfidence,
    required this.vegetableProbabilities,
    required this.diagnosedDeficiency,
    required this.deficiencyConfidence,
    required this.deficiencyProbabilities,
    this.imageUrl,
  });

  factory HhcPrediction.fromJson(Map<String, dynamic> json) {
    // Backend response:
    // {"crop": "Ampalaya", "crop_confidence": 0.969,
    //  "deficiency": "Potassium", "deficiency_confidence": 0.925,
    //  "image_url": null}
    // The probability maps are no longer returned; they default to {}.
    return HhcPrediction(
      vegetable: json['crop'] as String,
      vegetableConfidence: (json['crop_confidence'] as num).toDouble(),
      vegetableProbabilities: _parseProbs(json['vegetable_probabilities']),
      diagnosedDeficiency: json['deficiency'] as String,
      deficiencyConfidence: (json['deficiency_confidence'] as num).toDouble(),
      deficiencyProbabilities: _parseProbs(json['deficiency_probabilities']),
      imageUrl: json['image_url'] as String?,
    );
  }

  static Map<String, double> _parseProbs(dynamic raw) {
    if (raw == null) return {};
    return (raw as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  /// Confidence as a percentage string, e.g. "94.2%".
  String get vegetableConfidencePct =>
      '${(vegetableConfidence * 100).toStringAsFixed(1)}%';

  /// Deficiency confidence as a percentage string, e.g. "87.6%".
  String get deficiencyConfidencePct =>
      '${(deficiencyConfidence * 100).toStringAsFixed(1)}%';

  @override
  String toString() =>
      'HhcPrediction(vegetable: $vegetable $vegetableConfidencePct, '
      'deficiency: $diagnosedDeficiency $deficiencyConfidencePct)';
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

/// Thrown by [HhcApiService] when a request fails.
class HhcApiException implements Exception {
  final String message;
  final int? statusCode;

  const HhcApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      statusCode != null ? 'HhcApiException($statusCode): $message' : 'HhcApiException: $message';
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

/// HTTP client for the NutriLeaf HHC-VNDC FastAPI backend.
///
/// Submits images to the /predict endpoint and returns structured
/// two-stage diagnosis results (vegetable + nutrient deficiency).
///
/// Configuration
/// -------------
/// Update [baseUrl] to point at your FastAPI server:
///   - Android emulator: 'http://10.0.2.2:8000'
///   - Physical device (LAN): 'http://192.168.x.x:8000'
///   - Production: 'https://your-domain.com'
///
/// Usage
/// -----
/// ```dart
/// final service = HhcApiService();
/// try {
///   final prediction = await service.predict(imageBytes, filename: 'leaf.jpg');
///   print(prediction.vegetable);           // "ampalaya"
///   print(prediction.diagnosedDeficiency); // "nitrogen"
/// } on HhcApiException catch (e) {
///   print(e.message);
/// }
/// ```
class HhcApiService {
  static final HhcApiService _instance = HhcApiService._internal();
  factory HhcApiService() => _instance;
  HhcApiService._internal();

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Base URL of the FastAPI backend.
  ///
  /// 10.0.2.2 maps to the host machine from an Android emulator.
  /// Change this to a LAN IP (e.g., 192.168.1.100) for a physical device.
  static String get baseUrl => ApiConfig.apiBaseUrl;

  static const Duration _timeout = Duration(seconds: 60);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Submit [imageBytes] to the /predict endpoint and return an [HhcPrediction].
  ///
  /// The image is sent as a multipart/form-data upload with field name "image".
  ///
  /// [filename] must include the correct extension (.jpg / .png / .webp)
  /// so the server can determine the MIME type.
  Future<HhcPrediction> predict(
    Uint8List imageBytes, {
    String filename = 'leaf.jpg',
  }) async {
    final uri = Uri.parse('$baseUrl/predict');
    final mime = _mimeFromFilename(filename);

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
          contentType: MediaType.parse(mime),
        ),
      );

    late http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(_timeout);
    } on Exception catch (e) {
      throw HhcApiException(
        'Could not reach the NutriLeaf server at $baseUrl. '
        'Make sure the server is running and the device is on the same network.\n'
        'Details: $e',
      );
    }

    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      debugPrint('[HhcApiService] Error: HTTP ${streamed.statusCode}');
      debugPrint('[HhcApiService] Response Body: $body');
    }

    if (streamed.statusCode == 200) {
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return HhcPrediction.fromJson(json);
      } catch (e) {
        throw HhcApiException(
          'The server returned an unexpected response format. '
          'Please update your app and server to matching versions.\nDetails: $e',
          statusCode: streamed.statusCode,
        );
      }
    }

    // Non-200: extract "detail" from FastAPI's standard error envelope.
    String detail = 'Unknown server error (HTTP ${streamed.statusCode}).';
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      detail = json['detail']?.toString() ?? detail;
    } catch (_) {
      if (body.isNotEmpty) detail = body;
    }

    if (streamed.statusCode == 503) {
      throw HhcApiException(
        'The AI model is not ready on the server. $detail',
        statusCode: 503,
      );
    }

    throw HhcApiException(detail, statusCode: streamed.statusCode);
  }

  /// Ping the /api/health endpoint to check model and Supabase readiness.
  ///
  /// Returns the raw JSON response map from the server.
  Future<Map<String, dynamic>> checkHealth() async {
    final uri = Uri.parse('$baseUrl/api/health');
    try {
      final response = await http.get(uri).timeout(_timeout);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on Exception catch (e) {
      throw HhcApiException('Health check failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _mimeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}