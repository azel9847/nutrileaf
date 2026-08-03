import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../models/scan_result.dart';
import '../widgets/scan_history_tile.dart';
import '../widgets/crop_chip.dart';
import 'result_screen.dart';

/// History page showing all past scans with crop filter and swipe-to-delete.
class HistoryScreen extends StatefulWidget {
  final CropType? initialCropFilter;

  const HistoryScreen({super.key, this.initialCropFilter});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _allScans = [];
  List<ScanResult> _filteredScans = [];
  CropType? _selectedCrop;
  bool _isLoading = true;

  void setCropFilter(CropType? crop) {
    _onCropFilterChanged(crop);
  }

  void refreshData() {
    _loadHistory();
  }

  @override
  void initState() {
    super.initState();
    _selectedCrop = widget.initialCropFilter;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final scans = await HistoryService().getHistory();
    if (mounted) {
      setState(() {
        _allScans = scans;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedCrop == null) {
      _filteredScans = _allScans;
    } else {
      _filteredScans =
          _allScans.where((s) => s.cropType == _selectedCrop).toList();
    }
  }

  void _onCropFilterChanged(CropType? crop) {
    setState(() {
      _selectedCrop = crop;
      _applyFilter();
    });
  }

  Future<void> _deleteScan(String scanId) async {
    await HistoryService().deleteScan(scanId);
    _loadHistory();
  }

  Future<void> _clearAll() async {
    final lang = context.read<SettingsService>().language;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
        title: Text(
          AppStrings.get('clear_all', lang),
          style: AppTextStyles.headline3,
        ),
        content: Text(
          AppStrings.get('clear_confirm', lang),
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppStrings.get('cancel', lang),
              style: AppTextStyles.body.copyWith(color: AppColors.caption),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
            ),
            child: Text(AppStrings.get('clear_all', lang)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HistoryService().clearHistory();
      _loadHistory();
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
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingMD),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.get('scan_history', lang),
                      style: AppTextStyles.headline2.copyWith(
                        color: isDark ? AppColors.darkHeadingText : null,
                      ),
                    ),
                  ),
                  if (_allScans.isNotEmpty)
                    GestureDetector(
                      onTap: _clearAll,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: isDark
                              ? SoftShadows.darkSubtle
                              : SoftShadows.lightSubtle,
                        ),
                        child: Icon(
                          Icons.delete_sweep_rounded,
                          size: 20,
                          color: AppColors.dangerRed,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Crop filter chips
            if (_allScans.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingMD),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      CropChip(
                        label: AppStrings.get('all_crops', lang),
                        icon: Icons.filter_list_rounded,
                        color: AppColors.primaryGreen,
                        isSelected: _selectedCrop == null,
                        onTap: () => _onCropFilterChanged(null),
                      ),
                      const SizedBox(width: 8),
                      ...CropType.values.map((crop) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CropChip(
                              label: crop.displayName,
                              icon: crop.icon,
                              color: crop.color,
                              isSelected: _selectedCrop == crop,
                              onTap: () => _onCropFilterChanged(crop),
                            ),
                          )),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : _filteredScans.isEmpty
                      ? _buildEmptyState(isDark, lang)
                      : _buildList(isDark, lang),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(bool isDark, String lang) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      itemCount: _filteredScans.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_filteredScans.length} scan${_filteredScans.length != 1 ? 's' : ''}',
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.darkCaption : null,
              ),
            ),
          );
        }
        final scan = _filteredScans[index - 1];
        return ScanHistoryTile(
          scan: scan,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResultScreen(result: scan),
              ),
            );
          },
          onDelete: () => _deleteScan(scan.id),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                Icons.history_rounded,
                size: 56,
                color: isDark ? AppColors.leafGreen : AppColors.lightGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.get('no_scans', lang),
              style: AppTextStyles.headline3.copyWith(
                color: isDark ? AppColors.darkCaption : AppColors.caption,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.get('no_scans_desc', lang),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: isDark ? AppColors.darkCaption : AppColors.caption,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tap the Scan Leaf button below to get started!',
              style: AppTextStyles.body.copyWith(
                color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
