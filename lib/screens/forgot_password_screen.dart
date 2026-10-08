import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';
import '../services/auth_service.dart';

/// Screen for password reset using Supabase email link flow.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  bool _isSuccess = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dangerRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().resetPasswordForEmail(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      setState(() => _isSuccess = true);
    } else {
      _showError(result.errorMessage ?? 'Failed to send reset link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Forgot Password',
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _isSuccess ? _buildSuccess(isDark) : _buildEnterEmail(isDark),
        ),
      ),
    );
  }

  Widget _buildEnterEmail(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Your Password',
          style: AppTextStyles.headline2.copyWith(
            color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the email associated with your account and we will send you a secure link to reset your password.',
          style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
          ),
        ),
        const SizedBox(height: 32),

        // Email Field
        Text(
          'Email Address',
          style: AppTextStyles.bodyBold.copyWith(
            color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
          ),
          decoration: InputDecoration(
            hintText: 'your@email.com',
            hintStyle: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkCaption : AppColors.caption,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              size: 20,
              color: isDark ? AppColors.darkCaption : AppColors.caption,
            ),
            filled: true,
            fillColor: isDark
                ? AppColors.darkCard
                : AppColors.paleGreen.withValues(alpha: 0.4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSM),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSM),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSM),
              borderSide: BorderSide(
                color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendResetLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              disabledBackgroundColor:
                  AppColors.primaryGreen.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusLG),
              ),
              elevation: _isLoading ? 0 : 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Text('Send Reset Link', style: AppTextStyles.button),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.successGreen,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          style: AppTextStyles.headline2.copyWith(
            color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We have sent a password reset link to\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusLG),
              ),
            ),
            child: Text(
              'Back to Login',
              style: AppTextStyles.bodyBold.copyWith(
                color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
