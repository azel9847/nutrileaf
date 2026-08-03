import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// Premium soft UI / neumorphic bottom navigation bar with a floating center
/// Scan Leaf action button.
///
/// Layout:  Home | History | [Scan Leaf] | Analytics | Settings
///
/// The center button is a larger, elevated, circular button with a green glow
/// that sits above the navigation bar to emphasize the primary scan action.
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

    return Container(
      // Extra space above to accommodate the floating center button
      margin: const EdgeInsets.only(top: 12),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Nav bar body ──
          Container(
            height: AppDimens.bottomNavHeight + bottomPadding,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : AppColors.primaryGreen.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.9),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: bottomPadding + 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Home (index 0)
                  Expanded(
                    child: _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      onTap: () => onTap(0),
                      isDark: isDark,
                    ),
                  ),
                  // History (index 1)
                  Expanded(
                    child: _NavItem(
                      icon: Icons.history_rounded,
                      label: 'History',
                      isSelected: currentIndex == 1,
                      onTap: () => onTap(1),
                      isDark: isDark,
                    ),
                  ),
                  // Center spacer for the floating button
                  const SizedBox(width: 64),
                  // Analytics (index 3)
                  Expanded(
                    child: _NavItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      isSelected: currentIndex == 3,
                      onTap: () => onTap(3),
                      isDark: isDark,
                    ),
                  ),
                  // Settings (index 4)
                  Expanded(
                    child: _NavItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      isSelected: currentIndex == 4,
                      onTap: () => onTap(4),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Floating Scan Leaf button (index 2) ──
          Positioned(
            top: -22,
            child: _ScanLeafButton(
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Floating center Scan Leaf button ────────────────────────────────────────

class _ScanLeafButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ScanLeafButton({
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_ScanLeafButton> createState() => _ScanLeafButtonState();
}

class _ScanLeafButtonState extends State<_ScanLeafButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isSelected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ScanLeafButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = widget.isSelected ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Outer glow ring
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected
                    ? AppColors.primaryGreen
                    : AppColors.lightGreen,
                boxShadow: [
                  // Main green glow
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(
                      alpha: widget.isSelected ? 0.45 : 0.30,
                    ),
                    blurRadius: widget.isSelected ? 24 : 16,
                    spreadRadius: widget.isSelected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                  // Neumorphic light edge
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(-2, -2),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: widget.isDark ? 0.1 : 0.35,
                  ),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: AppColors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan Leaf',
              style: GoogleFonts.alata(
                fontSize: 10,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isSelected
                    ? (widget.isDark ? AppColors.leafGreen : AppColors.primaryGreen)
                    : (widget.isDark ? AppColors.darkCaption : AppColors.caption),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Standard nav item ───────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.leafGreen : AppColors.primaryGreen;
    final inactiveColor = isDark ? AppColors.darkCaption : AppColors.caption;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: isSelected ? 22 : 20,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.alata(
                fontSize: 10,
                height: 1.1,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: const EdgeInsets.only(top: 1),
              width: isSelected ? 4 : 0,
              height: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
