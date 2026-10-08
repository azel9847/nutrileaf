import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

/// Screen displayed after a user signs up to instruct them to check their email.
class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.softBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 64,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),
              
              // Headline
              Text(
                'Check your email',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                ),
              ),
              const SizedBox(height: 16),
              
              // Message text
              Text(
                'If the email is valid, a confirmation link has been sent. Please check your inbox.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Back to Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _navigateToLogin(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? AppColors.darkDivider : AppColors.primaryGreen,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                    ),
                  ),
                  child: Text(
                    'Back to Login',
                    style: AppTextStyles.button.copyWith(
                      color: isDark ? AppColors.white : AppColors.primaryGreen,
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
