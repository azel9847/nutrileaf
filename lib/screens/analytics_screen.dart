import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../models/scan_result.dart';
import '../models/nutrient.dart';
import '../widgets/soft_card.dart';

/// Analytics dashboard with charts showing scan trends and deficiency distribution.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final summary = await HistoryService().getAnalyticsSummary();
    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.softBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          AppStrings.get('analytics_title', lang),
                          style: AppTextStyles.headline2.copyWith(
                            color: isDark ? AppColors.darkHeadingText : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (_summary!.totalScans == 0)
                      _buildEmptyState(isDark, lang)
                    else ...[
                      // Most common deficiency card
                      _buildMostCommonCard(isDark, lang),

                      const SizedBox(height: 20),

                      // Stats row
                      _buildQuickStats(isDark),

                      const SizedBox(height: 28),

                      // Deficiency distribution (Donut chart)
                      _buildDeficiencyChart(isDark, lang),

                      const SizedBox(height: 28),

                      // Scans by crop (Bar chart)
                      _buildCropChart(isDark, lang),

                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCard : AppColors.paleGreen)
                    .withValues(alpha: isDark ? 1 : 0.5),
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? SoftShadows.darkRaised
                    : SoftShadows.lightRaised,
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 56,
                color: isDark ? AppColors.leafGreen : AppColors.lightGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.get('no_data', lang),
              style: AppTextStyles.headline3.copyWith(
                color: isDark ? AppColors.darkCaption : AppColors.caption,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan your first leaf to see analytics here.',
              style: AppTextStyles.body.copyWith(
                color: isDark ? AppColors.darkCaption : AppColors.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostCommonCard(bool isDark, String lang) {
    final deficiency = _summary!.mostCommonDeficiency;
    if (deficiency == null) return const SizedBox.shrink();

    return SoftCard(
      color: isDark ? AppColors.darkCard : AppColors.softBackground,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: deficiency.color.withValues(alpha: isDark ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(deficiency.icon, color: deficiency.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('most_common', lang),
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkCaption : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deficiency.displayName,
                  style: AppTextStyles.subtitle.copyWith(
                    color: deficiency.color,
                  ),
                ),
                Text(
                  '${_summary!.mostCommonCount} occurrences',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkCaption : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: SoftCardSubtle(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${_summary!.totalScans}',
                  style: AppTextStyles.headline2.copyWith(
                    color:
                        isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                  ),
                ),
                Text(
                  'Total Scans',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkCaption : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SoftCardSubtle(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${_summary!.scansByNutrient.entries.where((e) => e.key != NutrientType.healthy && e.value > 0).length}',
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.phosphorus,
                  ),
                ),
                Text(
                  'Deficiencies',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkCaption : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SoftCardSubtle(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${_summary!.scansByNutrient[NutrientType.healthy] ?? 0}',
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.successGreen,
                  ),
                ),
                Text(
                  'Healthy',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkCaption : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeficiencyChart(bool isDark, String lang) {
    final nutrientData = _summary!.scansByNutrient.entries
        .where((e) => e.value > 0)
        .toList();

    if (nutrientData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('deficiency_dist', lang),
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : null,
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: nutrientData.map((entry) {
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          color: entry.key.color,
                          radius: 50,
                          title:
                              '${entry.value}',
                          titleStyle: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: nutrientData.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: entry.key.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key.shortName,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkBodyText
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropChart(bool isDark, String lang) {
    final cropData = _summary!.scansByCrop.entries
        .where((e) => e.value > 0)
        .toList();

    if (cropData.isEmpty) return const SizedBox.shrink();

    final maxVal = cropData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('scans_by_crop', lang),
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : null,
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxVal + 1,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < cropData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              cropData[value.toInt()].key.displayName,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.darkCaption
                                    : null,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble()) {
                          return Text(
                            '${value.toInt()}',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkCaption
                                  : null,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups:
                    cropData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.value.toDouble(),
                        color: data.key.color,
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
