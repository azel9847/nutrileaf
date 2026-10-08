import 'dart:convert';

/// Represents user feedback on a scan diagnosis.
///
/// Stored in Supabase `feedback` table and used for validation analysis.
class UserFeedback {
  final String scanId;
  final String? userId;
  final bool isCorrect;
  final String? userCorrection;
  final String? comments;
  final String originalPrediction;
  final double confidence;
  final String cropType;
  final DateTime createdAt;

  UserFeedback({
    required this.scanId,
    this.userId,
    required this.isCorrect,
    this.userCorrection,
    this.comments,
    required this.originalPrediction,
    required this.confidence,
    required this.cropType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Serialize to JSON map for Supabase insertion.
  Map<String, dynamic> toJson() => {
        'scan_id': scanId,
        'user_id': userId,
        'is_correct': isCorrect,
        'user_correction': userCorrection,
        'comments': comments,
        'original_prediction': originalPrediction,
        'confidence': confidence,
        'crop_type': cropType,
        'created_at': createdAt.toIso8601String(),
      };

  /// Deserialize from JSON map.
  factory UserFeedback.fromJson(Map<String, dynamic> json) => UserFeedback(
        scanId: json['scan_id'] as String,
        userId: json['user_id'] as String?,
        isCorrect: json['is_correct'] as bool,
        userCorrection: json['user_correction'] as String?,
        comments: json['comments'] as String?,
        originalPrediction: json['original_prediction'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        cropType: json['crop_type'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  /// Serialize to JSON string (for SharedPreferences offline queue).
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string.
  factory UserFeedback.fromJsonString(String jsonString) =>
      UserFeedback.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

/// Result of a feedback submission attempt.
class FeedbackResult {
  final bool success;
  final String? errorMessage;

  const FeedbackResult({required this.success, this.errorMessage});

  const FeedbackResult.ok() : success = true, errorMessage = null;

  const FeedbackResult.error(String message)
      : success = false,
        errorMessage = message;
}
