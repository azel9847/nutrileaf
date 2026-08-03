import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_result.dart';
import '../models/nutrient.dart';

/// Service for persisting scan history using SharedPreferences.
class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const String _historyKey = 'nutrileaf_scan_history';

  /// Save a scan result to history.
  Future<void> saveScan(ScanResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, result); // Most recent first
    final jsonList = history.map((e) => e.toJsonString()).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  /// Load all scan results from history.
  Future<List<ScanResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey) ?? [];
    return jsonList.map((e) => ScanResult.fromJsonString(e)).toList();
  }

  /// Get history filtered by crop type.
  Future<List<ScanResult>> getHistoryByCrop(CropType cropType) async {
    final history = await getHistory();
    return history.where((scan) => scan.cropType == cropType).toList();
  }

  /// Delete a single scan from history by ID.
  Future<void> deleteScan(String scanId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.removeWhere((scan) => scan.id == scanId);
    final jsonList = history.map((e) => e.toJsonString()).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  /// Clear all scan history.
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Get the total number of scans.
  Future<int> getScanCount() async {
    final history = await getHistory();
    return history.length;
  }

  /// Get analytics summary data.
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final history = await getHistory();

    // Scan count per crop
    final scansByCrop = <CropType, int>{};
    for (final crop in CropType.values) {
      scansByCrop[crop] = history.where((s) => s.cropType == crop).length;
    }

    // Scan count per nutrient (deficiencies only)
    final scansByNutrient = <NutrientType, int>{};
    for (final nutrient in NutrientType.values) {
      scansByNutrient[nutrient] =
          history.where((s) => s.detectedNutrient == nutrient).length;
    }

    // Most common deficiency (excluding healthy)
    NutrientType? mostCommon;
    int mostCommonCount = 0;
    scansByNutrient.forEach((nutrient, count) {
      if (nutrient != NutrientType.healthy && count > mostCommonCount) {
        mostCommonCount = count;
        mostCommon = nutrient;
      }
    });

    return AnalyticsSummary(
      totalScans: history.length,
      scansByCrop: scansByCrop,
      scansByNutrient: scansByNutrient,
      mostCommonDeficiency: mostCommon,
      mostCommonCount: mostCommonCount,
    );
  }
}

/// Summary data for the analytics dashboard.
class AnalyticsSummary {
  final int totalScans;
  final Map<CropType, int> scansByCrop;
  final Map<NutrientType, int> scansByNutrient;
  final NutrientType? mostCommonDeficiency;
  final int mostCommonCount;

  const AnalyticsSummary({
    required this.totalScans,
    required this.scansByCrop,
    required this.scansByNutrient,
    this.mostCommonDeficiency,
    this.mostCommonCount = 0,
  });
}
