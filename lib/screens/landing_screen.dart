import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import 'register_screen.dart';
import 'login_screen.dart';

/// NutriLeaf landing page — Leafora-inspired clean layout.
/// Text at top, hero illustration centered in a soft circle, pill CTA pinned to bottom.
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
    _heroScale = Tween<double>(begin: 0.88, end: 1.0).animate(
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

  void _navigateToRegister() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: Column(
        children: [
          SizedBox(height: topPadding),

          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Brand Name ──
                  SlideTransition(
                    position: _preHeaderSlide,
                    child: FadeTransition(
                      opacity: _preHeaderFade,
                      child: Text(
                        'NutriLeaf',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF354024),
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Tagline ──
                  SlideTransition(
                    position: _headlineSlide,
                    child: FadeTransition(
                      opacity: _headlineFade,
                      child: Text(
                        'DETECT · DIAGNOSE · THRIVE',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF889063),
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Subtext ──
                  SlideTransition(
                    position: _subtextSlide,
                    child: FadeTransition(
                      opacity: _subtextFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Monitor plant health, detect nutrient deficiencies, and get smart care recommendations in one app.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.caption,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Hero Illustration ──
                  FadeTransition(
                    opacity: _heroFade,
                    child: ScaleTransition(
                      scale: _heroScale,
                      child: _buildHeroIllustration(size),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Page indicator dots ──
                  FadeTransition(
                    opacity: _badgeFade,
                    child: _buildPageDots(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── CTA Buttons (pinned to bottom) ──
          SlideTransition(
            position: _ctaSlide,
            child: FadeTransition(
              opacity: _ctaFade,
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, 8, 28, bottomPadding + 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary CTA
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF354024),
                          borderRadius: BorderRadius.circular(500),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF354024)
                                  .withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _navigateToRegister,
                            borderRadius: BorderRadius.circular(500),
                            splashColor: Colors.white.withValues(alpha: 0.15),
                            highlightColor:
                                Colors.white.withValues(alpha: 0.08),
                            child: Center(
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Secondary link
                    GestureDetector(
                      onTap: _navigateToLogin,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6.0, horizontal: 16.0),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.caption,
                            ),
                            children: [
                              TextSpan(
                                text: 'Log in',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF354024),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIllustration(Size size) {
    final diameter = size.width * 0.72;
    return Center(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Soft background circle ──
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paleGreen.withValues(alpha: 0.6),
              ),
            ),

            // ── Small accent circle (top-right) ──
            Positioned(
              top: diameter * 0.06,
              right: diameter * 0.04,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF889063).withValues(alpha: 0.25),
                ),
              ),
            ),

            // ── Small accent dot (bottom-left) ──
            Positioned(
              bottom: diameter * 0.10,
              left: diameter * 0.08,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF354024).withValues(alpha: 0.15),
                ),
              ),
            ),

            // ── Hero image ──
            ClipOval(
              child: SizedBox(
                width: diameter * 0.82,
                height: diameter * 0.82,
                child: Image.asset(
                  'assets/images/auth_hero.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _fallbackHeroWidget(diameter * 0.82),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == 0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? const Color(0xFF354024)
                : const Color(0xFF354024).withValues(alpha: 0.18),
          ),
        );
      }),
    );
  }

  /// Fallback widget if the hero image asset isn't found.
  Widget _fallbackHeroWidget(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_rounded,
              size: 64,
              color: AppColors.primaryGreen.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            Text(
              'NutriLeaf',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: AppColors.primaryGreen.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
