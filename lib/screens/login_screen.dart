import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Login screen — hero + white card form layout.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isUnverified = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmailFormat(String email) {
    return RegExp(r'^[^\@\s]+@[^\@\s]+\.[^\@\s]+$').hasMatch(email);
  }

  Future<void> _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUnverified = false;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 50));

    final result = await AuthService().signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      _navigateToApp();
    } else if (result.isUnverified) {
      setState(() {
        _isLoading = false;
        _isUnverified = true;
        _errorMessage = result.errorMessage;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUnverified = false;
    });

    final result = await AuthService().signInWithGoogle();

    if (!mounted) return;

    if (result.isSuccess) {
      _navigateToApp();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
    }
  }

  void _navigateToApp() {
    if (AuthService().isLoggedIn) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.38;

    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.softBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // ── Hero panel ──────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroHeight,
              child: _buildHeroPanel(isDark, heroHeight),
            ),

            // ── Floating back button ─────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              child: _buildBackButton(isDark),
            ),

            // ── Form card ───────────────────────────────────────────────
            Positioned.fill(
              top: heroHeight - 28,
              child: _buildFormCard(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero panel ─────────────────────────────────────────────────────────

  Widget _buildHeroPanel(bool isDark, double heroHeight) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.softBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decorative soft circle accent
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mintGreen.withValues(alpha: 0.12),
              ),
            ),
          ),
          // Hero illustration
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 16),
            child: Image.asset(
              'assets/images/auth_hero.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.eco_rounded,
                  size: 80,
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating back button ────────────────────────────────────────────────

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard.withValues(alpha: 0.9)
              : AppColors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: isDark ? SoftShadows.darkSubtle : SoftShadows.lightSubtle,
        ),
        child: Icon(
          Icons.arrow_back_ios_rounded,
          size: 16,
          color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
        ),
      ),
    );
  }

  // ── Form card ───────────────────────────────────────────────────────────

  Widget _buildFormCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Welcome back',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkHeadingText
                        : const Color(0xFF354024), // Kombu Green
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to view your scan history and feedback.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.darkCaption : AppColors.caption,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // Email field
                _buildInputField(
                  controller: _emailController,
                  hint: 'Email address',
                  icon: Icons.mail_outline_rounded,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!_isValidEmailFormat(v.trim())) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Password field
                _buildInputField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  obscureText: _obscurePassword,
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color:
                          isDark ? AppColors.darkCaption : AppColors.caption,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => ForgotPasswordScreen(
                            initialEmail: _emailController.text.trim(),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.leafGreen
                              : const Color(0xFF354024),
                        ),
                      ),
                    ),
                  ),
                ),

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorBanner(isDark),
                ],

                const SizedBox(height: 24),

                // Login button
                _buildPrimaryButton(
                  label: 'Log In',
                  isLoading: _isLoading,
                  onTap: _isLoading ? null : _login,
                ),

                const SizedBox(height: 18),

                // Divider
                _buildDivider(isDark),

                const SizedBox(height: 18),

                // Google button
                _buildGoogleButton(isDark),

                const SizedBox(height: 28),

                // Sign up link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (ctx, anim1, anim2) =>
                              const RegisterScreen(),
                          transitionsBuilder: (ctx, animation, anim2, child) =>
                              FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? AppColors.darkCaption
                                : AppColors.caption,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.leafGreen
                                    : const Color(0xFF354024),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Skip link
                Center(
                  child: GestureDetector(
                    onTap: _navigateToApp,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Skip for now',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkCaption
                              : AppColors.softBrown,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────────────

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark
              ? AppColors.darkCaption.withValues(alpha: 0.7)
              : AppColors.caption.withValues(alpha: 0.8),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkCaption : const Color(0xFF889063),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 20, minHeight: 20),
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurface
            : AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.leafGreen
                : const Color(0xFF354024),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: const BorderSide(color: AppColors.dangerRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide:
              const BorderSide(color: AppColors.dangerRed, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: AppColors.dangerRed,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isLoading
                ? const Color(0xFF354024).withValues(alpha: 0.55)
                : const Color(0xFF354024),
            borderRadius: BorderRadius.circular(500),
            boxShadow: isLoading
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF354024).withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Text(
                    label,
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
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkCaption : AppColors.caption,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _loginWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(500),
          ),
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              width: 22,
              height: 22,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.g_mobiledata_rounded,
                size: 26,
                color: isDark
                    ? AppColors.darkHeadingText
                    : const Color(0xFF354024),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkHeadingText
                    : AppColors.bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    final color = _isUnverified ? AppColors.warningAmber : AppColors.dangerRed;
    final icon = _isUnverified
        ? Icons.warning_amber_rounded
        : Icons.error_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(AppDimens.radiusSM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
