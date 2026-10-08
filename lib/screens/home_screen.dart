import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../models/scan_result.dart';
import '../models/nutrient.dart';
import '../widgets/crop_chip.dart';
import 'main_shell.dart';

/// Home dashboard with soft UI welcome card, quick actions, and recent scans.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
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
      backgroundColor: AppColors.softBackground,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<SettingsService>().language;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMD, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Welcome banner card
            _buildWelcomeCard(isDark, lang),

            const SizedBox(height: 20),

            // Quick action buttons
            _buildQuickActions(isDark, lang),

            const SizedBox(height: 24),

            // Stats cards
            _buildStatsSection(isDark, lang),

            const SizedBox(height: 24),

            // How it works
            _buildHowItWorks(isDark, lang),

            const SizedBox(height: 24),

            // Crop categories
            _buildCropCategories(isDark, lang),

            const SizedBox(height: 24),

            // Recent scans
            if (_recentScans.isNotEmpty) ...[
              _buildRecentScans(isDark, lang),
              const SizedBox(height: 24),
            ],

            // Detectable nutrients
            _buildDetectableNutrients(isDark),

            const SizedBox(height: AppDimens.paddingLG),
          ],
        ),
      ),
    );
  }

  // ── Welcome banner card ─────────────────────────────────────────────────────

  Widget _buildWelcomeCard(bool isDark, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFF354024),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF354024).withValues(alpha: isDark ? 0.0 : 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Soft decorative circles
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -16,
            left: -12,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.05),
              ),
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Left: text block
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand row
                      Row(
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            color: Colors.white.withValues(alpha: 0.80),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'NutriLeaf',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppStrings.get('welcome_title', lang),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.get('welcome_subtitle', lang),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // "Scan now" hint pill
                      GestureDetector(
                        onTap: () {
                          context
                              .findAncestorStateOfType<MainShellState>()
                              ?.switchTab(2);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(500),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Scan a leaf',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right: illustration
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/auth_hero.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.eco_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick actions ───────────────────────────────────────────────────────────

  Widget _buildQuickActions(bool isDark, String lang) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.document_scanner_rounded,
            label: AppStrings.get('scan_leaf', lang),
            iconBg: const Color(0xFF354024),
            iconColor: Colors.white,
            isDark: isDark,
            onTap: () {
              context
                  .findAncestorStateOfType<MainShellState>()
                  ?.switchTab(2);
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionCard(
            icon: Icons.photo_library_rounded,
            label: AppStrings.get('upload_image', lang),
            iconBg: const Color(0xFF889063).withValues(alpha: 0.15),
            iconColor: const Color(0xFF889063),
            isDark: isDark,
            onTap: () {
              context
                  .findAncestorStateOfType<MainShellState>()
                  ?.switchTab(2, triggerUpload: true);
            },
          ),
        ),
      ],
    );
  }

  // ── Stats ───────────────────────────────────────────────────────────────────

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
      ],
    );
  }

  // ── How it works ────────────────────────────────────────────────────────────

  Widget _buildHowItWorks(bool isDark, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: AppStrings.get('how_it_works', lang),
          isDark: isDark,
        ),
        const SizedBox(height: 14),
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

  // ── Crop categories ─────────────────────────────────────────────────────────

  Widget _buildCropCategories(bool isDark, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: AppStrings.get('crop_categories', lang),
          isDark: isDark,
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

  // ── Recent scans ────────────────────────────────────────────────────────────

  Widget _buildRecentScans(bool isDark, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
              title: AppStrings.get('recent_scans', lang),
              isDark: isDark,
            ),
            GestureDetector(
              onTap: () {
                context
                    .findAncestorStateOfType<MainShellState>()
                    ?.switchTab(1);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.get('view_all', lang),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.leafGreen
                            : const Color(0xFF354024),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.leafGreen
                          : const Color(0xFF354024),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentScans.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _RecentScanCard(
                  scan: _recentScans[index], isDark: isDark);
            },
          ),
        ),
      ],
    );
  }

  // ── Detectable nutrients ────────────────────────────────────────────────────

  Widget _buildDetectableNutrients(bool isDark) {
    final nutrients = NutrientType.values
          .where((n) => n != NutrientType.healthy)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Detectable Deficiencies', isDark: isDark),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: nutrients.map((nutrient) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: nutrient.color
                    .withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius:
                    BorderRadius.circular(AppDimens.radiusXL),
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

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: isDark
            ? AppColors.darkHeadingText
            : const Color(0xFF354024),
        height: 1.2,
      ),
    );
  }
}

// ─── Action Card ─────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.darkDivider
                : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkHeadingText
                    : const Color(0xFF354024),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.darkCaption : AppColors.caption,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Step Card ────────────────────────────────────────────────────────────────

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF354024),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.white, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkHeadingText
                  : const Color(0xFF354024),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.darkCaption : AppColors.caption,
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

// ─── Recent Scan Card ─────────────────────────────────────────────────────────

class _RecentScanCard extends StatelessWidget {
  final ScanResult scan;
  final bool isDark;

  const _RecentScanCard({required this.scan, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final percentage = (scan.confidence * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scan.detectedNutrient.color
                  .withValues(alpha: isDark ? 0.2 : 0.09),
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
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkHeadingText
                      : const Color(0xFF354024),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$percentage% · ${scan.cropType.displayName}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color:
                      isDark ? AppColors.darkCaption : AppColors.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
