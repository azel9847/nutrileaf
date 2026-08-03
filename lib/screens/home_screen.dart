import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../models/scan_result.dart';
import '../models/nutrient.dart';
import '../widgets/soft_card.dart';
import '../widgets/crop_chip.dart';
import 'main_shell.dart';

/// Home dashboard with soft UI welcome card, quick actions, and recent scans.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  List<ScanResult> _recentScans = [];
  int _totalScans = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final history = await HistoryService().getHistory();
    if (mounted) {
      setState(() {
        _totalScans = history.length;
        _recentScans = history.take(5).toList();
      });
    }
  }

  /// Public method so the parent [MainShell] can refresh home data
  /// when the user switches back to the home tab.
  void refreshData() => _loadData();

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Welcome card
            _buildWelcomeCard(isDark, lang),

            const SizedBox(height: 24),

            // Quick action buttons
            _buildQuickActions(isDark, lang),

            const SizedBox(height: 28),

            // Stats cards
            _buildStatsSection(isDark, lang),

            const SizedBox(height: 28),

            // How it works
            _buildHowItWorks(isDark, lang),

            const SizedBox(height: 28),

            // Crop categories
            _buildCropCategories(isDark, lang),

            const SizedBox(height: 28),

            // Recent scans
            if (_recentScans.isNotEmpty) ...[
              _buildRecentScans(isDark, lang),
              const SizedBox(height: 28),
            ],

            // Detectable nutrients
            _buildDetectableNutrients(isDark),

            const SizedBox(height: AppDimens.paddingLG),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark, String lang) {
    return SoftCard(
      color: isDark ? AppColors.darkCard : AppColors.primaryGreen,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // ── Decorative background elements ──

            // Large soft circle — top-right
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.08),
                ),
              ),
            ),

            // Medium circle — bottom-left
            Positioned(
              bottom: -20,
              left: -15,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.06),
                ),
              ),
            ),

            // Small accent circle — mid-right
            Positioned(
              top: 50,
              right: 60,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.05),
                ),
              ),
            ),

            // Decorative arc — top-left
            Positioned(
              top: -40,
              left: 30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.07),
                    width: 2,
                  ),
                ),
              ),
            ),

            // Small leaf icon — decorative, top-right area
            Positioned(
              top: 16,
              right: 24,
              child: Icon(
                Icons.spa_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.12),
              ),
            ),

            // Tiny dot accent — bottom-right
            Positioned(
              bottom: 18,
              right: 40,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.12),
                ),
              ),
            ),

            // ── Foreground content ──
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingLG),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'NutriLeaf',
                              style: GoogleFonts.alata(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.get('welcome_title', lang),
                          style: GoogleFonts.alata(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.get('welcome_subtitle', lang),
                          style: GoogleFonts.alata(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, String lang) {
    return Row(
      children: [
        Expanded(
          child: SoftCard(
            onTap: () {
              context.findAncestorStateOfType<MainShellState>()?.switchTab(2);
            },
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                    boxShadow: SoftShadows.colorGlow(AppColors.primaryGreen),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.get('scan_leaf', lang),
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SoftCard(
            onTap: () {
              context.findAncestorStateOfType<MainShellState>()?.switchTab(2, triggerUpload: true);
            },
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.terracotta.withValues(alpha: 0.15)
                        : AppColors.terracotta.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.terracotta,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.get('upload_image', lang),
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isDark, String lang) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.document_scanner_rounded,
            label: AppStrings.get('total_scans', lang),
            value: '$_totalScans',
            color: AppColors.primaryGreen,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.eco_rounded,
            label: AppStrings.get('nutrients', lang),
            value: '5',
            color: AppColors.leafGreen,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.speed_rounded,
            label: AppStrings.get('ai_accuracy', lang),
            value: '95%',
            color: AppColors.nitrogen,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks(bool isDark, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('how_it_works', lang),
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : null,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StepCard(
                step: '1',
                icon: Icons.camera_alt_rounded,
                title: AppStrings.get('step1_title', lang),
                subtitle: AppStrings.get('step1_desc', lang),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StepCard(
                step: '2',
                icon: Icons.psychology_rounded,
                title: AppStrings.get('step2_title', lang),
                subtitle: AppStrings.get('step2_desc', lang),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StepCard(
                step: '3',
                icon: Icons.checklist_rounded,
                title: AppStrings.get('step3_title', lang),
                subtitle: AppStrings.get('step3_desc', lang),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCropCategories(bool isDark, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('crop_categories', lang),
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : null,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: CropType.values.map((crop) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CropChip(
                  label: crop.displayName,
                  icon: crop.icon,
                  color: crop.color,
                  isSelected: false,
                  onTap: () {
                    context
                        .findAncestorStateOfType<MainShellState>()
                        ?.switchTab(1, initialCropFilter: crop);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScans(bool isDark, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.get('recent_scans', lang),
              style: AppTextStyles.headline3.copyWith(
                color: isDark ? AppColors.darkHeadingText : null,
              ),
            ),
            TextButton(
              onPressed: () {
                context.findAncestorStateOfType<MainShellState>()?.switchTab(1);
              },
              child: Text(
                AppStrings.get('view_all', lang),
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentScans.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _RecentScanCard(scan: _recentScans[index], isDark: isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetectableNutrients(bool isDark) {
    final nutrients = NutrientType.values
        .where((n) => n != NutrientType.healthy)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detectable Deficiencies',
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : null,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: nutrients.map((nutrient) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: nutrient.color.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                border: Border.all(
                  color: nutrient.color.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(nutrient.icon, size: 16, color: nutrient.color),
                  const SizedBox(width: 6),
                  Text(
                    nutrient.displayName,
                    style: AppTextStyles.caption.copyWith(
                      color: nutrient.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCardSubtle(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headline3.copyWith(
              color: color,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: isDark ? AppColors.darkCaption : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCardSubtle(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.terracotta,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.white, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.bodyBold.copyWith(
              fontSize: 12,
              color: isDark ? AppColors.darkHeadingText : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: isDark ? AppColors.darkCaption : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  final ScanResult scan;
  final bool isDark;

  const _RecentScanCard({required this.scan, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final percentage = (scan.confidence * 100).toStringAsFixed(0);

    return SoftCardSubtle(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scan.detectedNutrient.color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              scan.detectedNutrient.icon,
              size: 22,
              color: scan.detectedNutrient.color,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                scan.detectedNutrient == NutrientType.healthy
                    ? 'Healthy'
                    : scan.detectedNutrient.shortName,
                style: AppTextStyles.bodyBold.copyWith(
                  color: isDark ? AppColors.darkHeadingText : null,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$percentage% • ${scan.cropType.displayName}',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: isDark ? AppColors.darkCaption : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
