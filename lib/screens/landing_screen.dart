import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import 'main_shell.dart';

/// NutriLeaf landing page with hero plant image, welcome copy,
/// trust badge, and a pill-shaped CTA — all against #F4F4EB.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _textController;
  late AnimationController _ctaController;

  late Animation<double> _heroFade;
  late Animation<double> _heroScale;
  late Animation<double> _preHeaderFade;
  late Animation<Offset> _preHeaderSlide;
  late Animation<double> _headlineFade;
  late Animation<Offset> _headlineSlide;
  late Animation<double> _subtextFade;
  late Animation<Offset> _subtextSlide;
  late Animation<double> _badgeFade;
  late Animation<double> _ctaFade;
  late Animation<Offset> _ctaSlide;

  @override
  void initState() {
    super.initState();

    // ── Hero image animation ──
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _heroScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // ── Text stagger animation ──
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _preHeaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _preHeaderSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    _headlineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
      ),
    );
    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _subtextFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _subtextSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.55, 0.80, curve: Curves.easeOut),
      ),
    );

    // ── CTA animation ──
    _ctaController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctaController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _ctaSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctaController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // ── Stagger the animation chain ──
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _ctaController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _textController.dispose();
    _ctaController.dispose();
    super.dispose();
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // ── Hero Image ──
                    FadeTransition(
                      opacity: _heroFade,
                      child: ScaleTransition(
                        scale: _heroScale,
                        child: Container(
                          width: size.width * 0.75,
                          height: size.width * 0.75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset(
                              'assets/images/download.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _fallbackHeroWidget();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── WELCOME pre-header ──
                    SlideTransition(
                      position: _preHeaderSlide,
                      child: FadeTransition(
                        opacity: _preHeaderFade,
                        child: Text(
                          'WELCOME',
                          style: GoogleFonts.alata(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.terracotta.withValues(alpha: 0.65),
                            letterSpacing: 5.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Main headline ──
                    SlideTransition(
                      position: _headlineSlide,
                      child: FadeTransition(
                        opacity: _headlineFade,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Text(
                            'Take care of your\nplants the smart way.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.alata(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Subtext ──
                    SlideTransition(
                      position: _subtextSlide,
                      child: FadeTransition(
                        opacity: _subtextFade,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Monitor plant health, detect nutrient deficiencies, and get smart care recommendations in one app.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.alata(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B7B6B),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Trust badge ──
                    FadeTransition(
                      opacity: _badgeFade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Build the perfect care for your plants',
                          style: GoogleFonts.alata(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.terracotta.withValues(alpha: 0.80),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── CTA Button (pinned to bottom) ──
            SlideTransition(
              position: _ctaSlide,
              child: FadeTransition(
                opacity: _ctaFade,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    32,
                    8,
                    32,
                    bottomPadding + 28,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: SoftShadows.ctaButton,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _navigateToApp,
                          borderRadius: BorderRadius.circular(50),
                          splashColor: Colors.white.withValues(alpha: 0.15),
                          highlightColor: Colors.white.withValues(alpha: 0.08),
                          child: Center(
                            child: Text(
                              'Get Started',
                              style: GoogleFonts.alata(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: AppColors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fallback widget if the hero image asset isn't found.
  Widget _fallbackHeroWidget() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_rounded,
              size: 80,
              color: AppColors.primaryGreen.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              'NutriLeaf',
              style: GoogleFonts.alata(
                fontSize: 22,
                color: AppColors.primaryGreen.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
