import 'package:flutter/material.dart';
import '../models/nutrient.dart';
import '../utils/constants.dart';

/// Horizontal animated bar showing confidence percentage with color coding.
class ConfidenceBar extends StatefulWidget {
  final NutrientType nutrient;
  final double confidence;
  final bool animate;

  const ConfidenceBar({
    super.key,
    required this.nutrient,
    required this.confidence,
    this.animate = true,
  });

  @override
  State<ConfidenceBar> createState() => _ConfidenceBarState();
}

class _ConfidenceBarState extends State<ConfidenceBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: widget.confidence).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.confidence * 100).toStringAsFixed(1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLowConfidence = widget.confidence < 0.6;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Nutrient short name
          SizedBox(
            width: 32,
            child: Text(
              widget.nutrient.shortName,
              style: AppTextStyles.bodyBold.copyWith(
                color: widget.nutrient.color,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Progress bar
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.softBackground,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.nutrient.color.withValues(alpha: 0.7),
                            widget.nutrient.color,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),

          // Percentage text with warning color
          SizedBox(
            width: 48,
            child: Text(
              '$percentage%',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: isLowConfidence
                    ? AppColors.warningAmber
                    : (isDark ? AppColors.darkBodyText : AppColors.bodyText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
