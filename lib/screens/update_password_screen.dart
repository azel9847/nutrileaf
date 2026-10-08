import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';
import '../services/auth_service.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text;

    if (newPassword.isEmpty || newPassword.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService().updatePassword(newPassword: newPassword);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      _showSuccess(result.successMessage ?? 'Password updated successfully!');
      // Do nothing else! Supabase will emit AuthChangeEvent.userUpdated,
      // and AuthGate will automatically exit recovery mode and show MainShell!
    } else {
      _showError(result.errorMessage ?? 'Failed to update password.');
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
            Icons.close_rounded,
            color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
          ),
          onPressed: () async {
            // If they cancel, sign them out of the recovery session
            await AuthService().signOut();
            // AuthGate will detect signedOut and return to LandingScreen
          },
        ),
        title: Text(
          'Update Password',
          style: AppTextStyles.headline3.copyWith(
            color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set New Password',
                style: AppTextStyles.headline2.copyWith(
                  color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your new password must be at least 6 characters long.',
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'New Password',
                style: AppTextStyles.bodyBold.copyWith(
                  color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscurePassword,
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.darkBodyText : AppColors.bodyText,
                ),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkCaption : AppColors.caption,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkCaption : AppColors.caption,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: isDark ? AppColors.darkCaption : AppColors.caption,
                    ),
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
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text('Update Password', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
