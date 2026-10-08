import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feedback_model.dart';
import '../utils/api_config.dart';

/// Service for submitting user feedback to Supabase.
///
/// Includes an offline fallback queue that persists pending submissions
/// in SharedPreferences and retries them when connectivity returns.
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  static const String _pendingKey = 'nutrileaf_pending_feedback';

  /// Submit feedback to Supabase.
  ///
  /// Falls back to local queue if Supabase is unavailable.
  Future<FeedbackResult> submitFeedback(UserFeedback feedback) async {
    if (!ApiConfig.isSupabaseConfigured) {
      // Supabase not configured — queue locally
      await _queueLocally(feedback);
      return const FeedbackResult.ok();
    }

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('feedback').insert(feedback.toJson());
      return const FeedbackResult.ok();
    } catch (e) {
      // Network or Supabase error — queue locally for retry
      await _queueLocally(feedback);
      if (e.toString().contains('connection') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('timeout')) {
        return const FeedbackResult.error(
          'No internet connection. Feedback saved and will sync later.',
        );
      }
      return FeedbackResult.error('Failed to submit feedback: $e');
    }
  }

  /// Retry all pending feedback submissions from the local queue.
  ///
  /// Call this on app startup or when connectivity is restored.
  Future<void> syncPendingFeedback() async {
    if (!ApiConfig.isSupabaseConfigured) return;

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey) ?? [];
    if (pending.isEmpty) return;

    final stillPending = <String>[];

    for (final jsonString in pending) {
      try {
        final feedback = UserFeedback.fromJsonString(jsonString);
        final supabase = Supabase.instance.client;
        await supabase.from('feedback').insert(feedback.toJson());
        // Success — don't re-add to queue
      } catch (_) {
        // Still failing — keep in queue
        stillPending.add(jsonString);
      }
    }

    await prefs.setStringList(_pendingKey, stillPending);
  }

  /// Check if there are pending feedback items in the local queue.
  Future<bool> hasPendingFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey) ?? [];
    return pending.isNotEmpty;
  }

  /// Check if feedback has already been submitted for a given scan.
  Future<bool> hasSubmittedFeedback(String scanId) async {
    final prefs = await SharedPreferences.getInstance();
    final submitted = prefs.getStringList('nutrileaf_submitted_feedback') ?? [];
    return submitted.contains(scanId);
  }

  /// Mark a scan as having received feedback (locally).
  Future<void> markFeedbackSubmitted(String scanId) async {
    final prefs = await SharedPreferences.getInstance();
    final submitted = prefs.getStringList('nutrileaf_submitted_feedback') ?? [];
    if (!submitted.contains(scanId)) {
      submitted.add(scanId);
      await prefs.setStringList('nutrileaf_submitted_feedback', submitted);
    }
  }

  /// Add feedback to the local offline queue.
  Future<void> _queueLocally(UserFeedback feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey) ?? [];
    pending.add(feedback.toJsonString());
    await prefs.setStringList(_pendingKey, pending);
  }
}
