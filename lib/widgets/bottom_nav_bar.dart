import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// Expanding-pill bottom navigation bar.
///
/// Active tab → solid Kombu Green pill with icon + label.
/// Inactive tabs → icon only, muted caption color.
///
/// Layout: Home | History | Scan | Analytics | Settings
/// All 5 indices and onTap callbacks are unchanged.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final items = [
      _NavItemData(icon: Icons.home_rounded, label: 'Home'),
      _NavItemData(icon: Icons.history_rounded, label: 'History'),
      _NavItemData(icon: Icons.document_scanner_rounded, label: 'Scan'),
      _NavItemData(icon: Icons.bar_chart_rounded, label: 'Analytics'),
      _NavItemData(icon: Icons.settings_rounded, label: 'Settings'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomPadding + 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFF354024).withValues(alpha: 0.10),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.85),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            return _NavItem(
              data: items[index],
              isSelected: currentIndex == index,
              onTap: () => onTap(index),
              isDark: isDark,
            );
          }),
        ),
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF354024); // Kombu Green
    final inactiveColor =
        isDark ? AppColors.darkCaption : const Color(0xFFAAAAAA);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: isSelected
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.leafGreen : activeColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(500),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                data.icon,
                size: 22,
                color: isSelected ? Colors.white : inactiveColor,
              ),

              // Label — only visible when active
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: isSelected ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Text(
                      data.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
