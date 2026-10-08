import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';
import 'login_screen.dart';
import 'check_email_screen.dart';

/// Registration screen — hero + white card form layout.
///
/// Flow: Fill form → Create Account → Verify Email → App
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String? _successMessage;

  // Rate limit lockout timer
  DateTime? _rateLimitUntil;
  Timer? _rateLimitTimer;

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
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _rateLimitTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  bool _isValidEmailFormat(String email) {
    return RegExp(r'^[^\@\s]+@[^\@\s]+\.[^\@\s]+$').hasMatch(email);
  }

  // ── Rate limit ─────────────────────────────────────────────────────────

  void _startRateLimitTimer(int seconds) {
    setState(() {
      _rateLimitUntil = DateTime.now().add(Duration(seconds: seconds));
    });

    _rateLimitTimer?.cancel();
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_rateLimitUntil == null ||
          DateTime.now().isAfter(_rateLimitUntil!)) {
        setState(() {
          _rateLimitUntil = null;
        });
        timer.cancel();
      } else {
        setState(() {}); // Trigger rebuild to update countdown text
      }
    });
  }

  // ── Registration ────────────────────────────────────────────────────────

  Future<void> _register() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    if (!_isValidEmailFormat(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    final password = _passwordController.text;
    if (password.length < 6 ||
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password) ||
        !RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() {
        _errorMessage = 'Password does not meet all requirements.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 50));

    if (_rateLimitUntil != null &&
        DateTime.now().isBefore(_rateLimitUntil!)) {
      final secondsLeft =
          _rateLimitUntil!.difference(DateTime.now()).inSeconds;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Too many requests. Please wait $secondsLeft seconds.';
      });
      return;
    }

    final result = await AuthService().signUp(
      email: email,
      displayName: _nameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CheckEmailScreen()),
      );
    } else {
      if (result.errorMessage?.toLowerCase().contains('wait') ?? false) {
        _startRateLimitTimer(60);
      }
      setState(() {
        _errorMessage = result.errorMessage;
        _successMessage = null;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  // ── Password strength ───────────────────────────────────────────────────

  double _passwordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 6) strength += 0.25;
    if (password.length >= 10) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.20;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.20;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength += 0.20;
    }
    return strength.clamp(0.0, 1.0);
  }

  Color _strengthColor(double strength) {
    if (strength < 0.3) return AppColors.dangerRed;
    if (strength < 0.6) return AppColors.warningAmber;
    return AppColors.successGreen;
  }

  String _strengthLabel(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Fair';
    if (strength < 0.8) return 'Good';
    return 'Strong';
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.30;

    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.softBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // ── Hero panel ─────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroHeight,
              child: _buildHeroPanel(isDark),
            ),

            // ── Floating back button ───────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              child: _buildBackButton(isDark),
            ),

            // ── Form card ─────────────────────────────────────────────
            Positioned.fill(
              top: heroHeight - 28,
              child: _buildFormCard(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero panel ──────────────────────────────────────────────────────────

  Widget _buildHeroPanel(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.softBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decorative soft circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: -15,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mintGreen.withValues(alpha: 0.12),
              ),
            ),
          ),
          // Hero illustration
          Padding(
            padding: const EdgeInsets.only(top: 36, bottom: 12),
            child: Image.asset(
              'assets/images/auth_hero.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.eco_rounded,
                  size: 72,
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating back button ─────────────────────────────────────────────────

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
          boxShadow:
              isDark ? SoftShadows.darkSubtle : SoftShadows.lightSubtle,
        ),
        child: Icon(
          Icons.arrow_back_ios_rounded,
          size: 16,
          color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
        ),
      ),
    );
  }

  // ── Form card ────────────────────────────────────────────────────────────

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
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkHeadingText
                        : const Color(0xFF354024),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join NutriLeaf to save your feedback and improve AI results.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color:
                        isDark ? AppColors.darkCaption : AppColors.caption,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // Full name field
                _buildInputField(
                  controller: _nameController,
                  hint: 'Full name',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  keyboardType: TextInputType.name,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Email field
                _buildInputField(
                  controller: _emailController,
                  hint: 'Email address',
                  icon: Icons.mail_outline_rounded,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
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
                  onChanged: (_) => setState(() {}),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.darkCaption
                          : AppColors.caption,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) {
                      return 'Must be at least 6 characters';
                    }
                    if (!RegExp(r'\d').hasMatch(v)) {
                      return 'Must contain at least one number';
                    }
                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) {
                      return 'Must contain at least one special character';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(v)) {
                      return 'Must contain at least one uppercase letter';
                    }
                    if (v.length > 72) {
                      return 'Must not exceed 72 characters';
                    }
                    return null;
                  },
                ),

                // Password strength indicator
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildPasswordStrengthBar(isDark),
                  const SizedBox(height: 8),
                  _buildPasswordRequirements(isDark),
                ],

                const SizedBox(height: 14),

                // Confirm password field
                _buildInputField(
                  controller: _confirmPasswordController,
                  hint: 'Confirm password',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  obscureText: _obscureConfirm,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    child: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.darkCaption
                          : AppColors.caption,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                // Success / Error messages
                if (_successMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildBanner(
                    isDark: isDark,
                    color: AppColors.successGreen,
                    icon: Icons.check_circle_outline_rounded,
                    message: _successMessage!,
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildBanner(
                    isDark: isDark,
                    color: AppColors.dangerRed,
                    icon: Icons.error_outline_rounded,
                    message: _errorMessage!,
                  ),
                ],

                const SizedBox(height: 28),

                // Create Account button
                _buildPrimaryButton(isDark),

                const SizedBox(height: 28),

                // Log in link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (ctx, anim1, anim2) =>
                              const LoginScreen(),
                          transitionsBuilder:
                              (ctx, animation, anim2, child) =>
                                  FadeTransition(
                                      opacity: animation, child: child),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? AppColors.darkCaption
                                : AppColors.caption,
                          ),
                          children: [
                            TextSpan(
                              text: 'Log in',
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
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
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
            color:
                isDark ? AppColors.darkCaption : const Color(0xFF889063),
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
        fillColor: isDark ? AppColors.darkSurface : AppColors.white,
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
            color: isDark ? AppColors.leafGreen : const Color(0xFF354024),
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

  Widget _buildPrimaryButton(bool isDark) {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final isFormValid = email.isNotEmpty &&
        name.isNotEmpty &&
        _isValidEmailFormat(email) &&
        password.length >= 6 &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        confirmPassword == password;

    final canSubmit =
        isFormValid && !_isLoading && _rateLimitUntil == null;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: GestureDetector(
        onTap: canSubmit ? _register : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: canSubmit
                ? const Color(0xFF354024)
                : const Color(0xFF354024).withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(500),
            boxShadow: canSubmit
                ? [
                    BoxShadow(
                      color:
                          const Color(0xFF354024).withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white),
                    ),
                  )
                : Text(
                    _rateLimitUntil != null
                        ? 'Wait ${_rateLimitUntil!.difference(DateTime.now()).inSeconds}s'
                        : 'Create Account',
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

  Widget _buildPasswordStrengthBar(bool isDark) {
    final strength = _passwordStrength(_passwordController.text);
    final color = _strengthColor(strength);
    final label = _strengthLabel(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength,
                  minHeight: 5,
                  backgroundColor: isDark
                      ? AppColors.darkDivider
                      : AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(bool isDark) {
    final password = _passwordController.text;
    final hasLength = password.length >= 6;
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasSpecial =
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);

    Widget req(String text, bool isMet) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isMet
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 14,
                color: isMet
                    ? AppColors.successGreen
                    : (isDark
                        ? AppColors.darkCaption
                        : AppColors.caption),
              ),
              const SizedBox(width: 7),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isMet
                      ? (isDark
                          ? AppColors.darkBodyText
                          : AppColors.bodyText)
                      : (isDark
                          ? AppColors.darkCaption
                          : AppColors.caption),
                  decoration:
                      isMet ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        req('At least 6 characters', hasLength),
        req('At least one uppercase letter (A–Z)', hasUpper),
        req('At least one number (0–9)', hasNumber),
        req('At least one special character (!@#\$…)', hasSpecial),
      ],
    );
  }

  Widget _buildBanner({
    required bool isDark,
    required Color color,
    required IconData icon,
    required String message,
  }) {
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
              message,
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
