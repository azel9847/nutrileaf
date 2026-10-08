import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/scan_result.dart';
import '../models/nutrient.dart';
import '../utils/constants.dart';

/// Soft UI list tile for displaying a scan history entry with image thumbnail.
class ScanHistoryTile extends StatelessWidget {
  final ScanResult scan;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ScanHistoryTile({
    super.key,
    required this.scan,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(scan.dateTime);
    final percentage = (scan.confidence * 100).toStringAsFixed(1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(scan.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.dangerRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: AppColors.dangerRed,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(AppDimens.paddingMD),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
            boxShadow: isDark ? SoftShadows.darkSubtle : SoftShadows.lightSubtle,
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                child: _buildThumbnail(isDark),
              ),
              const SizedBox(width: AppDimens.paddingMD),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.detectedNutrient == NutrientType.healthy
                          ? 'Healthy Plant'
                          : '${scan.detectedNutrient.displayName} Deficiency',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: isDark ? AppColors.darkHeadingText : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Crop badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scan.cropType.color.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            scan.cropType.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: scan.cropType.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkCaption : null,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Confidence badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scan.detectedNutrient.color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                ),
                child: Text(
                  '$percentage%',
                  style: AppTextStyles.caption.copyWith(
                    color: scan.detectedNutrient.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    // Use in-memory bytes when present (fresh scan session).
    // History items loaded from storage won't have bytes — show placeholder.
    final bytes = scan.imageBytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusSM),
        child: Image.memory(
          bytes,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : AppColors.paleGreen,
        borderRadius: BorderRadius.circular(AppDimens.radiusSM),
      ),
      child: Icon(
        Icons.eco_rounded,
        color: AppColors.lightGreen,
        size: 28,
      ),
    );
  }
}
