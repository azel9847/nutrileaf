import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_strings.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import '../widgets/soft_card.dart';

/// Settings screen with how-to guide, dark mode, language toggle, and about section.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().signOut();
      // AuthGate will automatically detect the signedOut event and pop to root (LandingScreen)
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to logout: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsService>();
    final lang = settings.language;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.softBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    AppStrings.get('settings_title', lang),
                    style: AppTextStyles.headline2.copyWith(
                      color: isDark ? AppColors.darkHeadingText : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Section
              _buildProfileSection(isDark, lang),
              const SizedBox(height: 28),

              // How to Use section
              _buildSectionTitle(
                  AppStrings.get('how_to_use', lang), isDark),
              const SizedBox(height: 12),
              _buildHowToUse(isDark, lang),

              const SizedBox(height: 28),

              // Appearance section
              _buildSectionTitle(
                  AppStrings.get('appearance', lang), isDark),
              const SizedBox(height: 12),
              SoftCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.leafGreen : AppColors.primaryGreen)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: isDark
                            ? AppColors.leafGreen
                            : AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        AppStrings.get('dark_mode', lang),
                        style: AppTextStyles.bodyBold.copyWith(
                          color: isDark
                              ? AppColors.darkHeadingText
                              : AppColors.darkText,
                        ),
                      ),
                    ),
                    Switch(
                      value: settings.isDarkMode,
                      onChanged: (_) => settings.toggleDarkMode(),
                      activeThumbColor: AppColors.primaryGreen,
                      activeTrackColor:
                          AppColors.primaryGreen.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.caption,
                      inactiveTrackColor: AppColors.divider,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Language section
              _buildSectionTitle(
                  AppStrings.get('language', lang), isDark),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  children: [
                    _LanguageOption(
                      label: AppStrings.get('english', lang),
                      subtitle: 'English',
                      isSelected: settings.language == 'en',
                      onTap: () => settings.setLanguage('en'),
                      isDark: isDark,
                    ),
                    Divider(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                      height: 1,
                    ),
                    _LanguageOption(
                      label: AppStrings.get('filipino', lang),
                      subtitle: 'Filipino',
                      isSelected: settings.language == 'fil',
                      onTap: () => settings.setLanguage('fil'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // About section
              _buildSectionTitle(
                  AppStrings.get('about', lang), isDark),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  children: [
                    // App icon and name
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppColors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NutriLeaf',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: isDark
                                      ? AppColors.darkHeadingText
                                      : AppColors.darkText,
                                ),
                              ),
                              Text(
                                'Version 0.1.0',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkCaption
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppStrings.get('app_tagline', lang),
                      style: AppTextStyles.body.copyWith(
                        color: isDark ? AppColors.darkBodyText : null,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Logout Button
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.dangerRed),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.dangerRed,
                    ),
                    label: Text(
                      'Log Out',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.dangerRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.dangerRed.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                      ),
                      backgroundColor:
                          AppColors.dangerRed.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTextStyles.headline3.copyWith(
        color: isDark ? AppColors.darkHeadingText : null,
      ),
    );
  }

  Widget _buildProfileSection(bool isDark, String lang) {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    final metadata = user.userMetadata ?? {};
    final name = metadata['name'] ?? metadata['full_name'] ?? 'NutriLeaf User';
    final avatarUrl = metadata['avatar_url'] ?? metadata['picture'] as String?;
    final email = user.email ?? 'No email associated';
    
    final isGoogle = user.identities?.any((id) => id.provider == 'google') ?? false;

    return SoftCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: (isDark ? AppColors.leafGreen : AppColors.primaryGreen)
                .withValues(alpha: 0.15),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: isDark ? AppColors.leafGreen : AppColors.primaryGreen,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.subtitle.copyWith(
                    color: isDark ? AppColors.darkHeadingText : AppColors.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkCaption : AppColors.caption,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isGoogle) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : AppColors.offWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkDivider : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          width: 14,
                          height: 14,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.account_circle, size: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Google Account',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkBodyText : AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToUse(bool isDark, String lang) {
    final steps = [
      {
        'icon': Icons.camera_alt_rounded,
        'title': AppStrings.get('step1_title', lang),
        'desc': AppStrings.get('step1_desc', lang),
        'color': AppColors.primaryGreen,
      },
      {
        'icon': Icons.psychology_rounded,
        'title': AppStrings.get('step2_title', lang),
        'desc': AppStrings.get('step2_desc', lang),
        'color': AppColors.nitrogen,
      },
      {
        'icon': Icons.checklist_rounded,
        'title': AppStrings.get('step3_title', lang),
        'desc': AppStrings.get('step3_desc', lang),
        'color': AppColors.successGreen,
      },
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final color = step['color'] as Color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SoftCard(
            child: Row(
              children: [
                // Step number
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.subtitle.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Icon
                Icon(
                  step['icon'] as IconData,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'] as String,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: isDark
                              ? AppColors.darkHeadingText
                              : AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step['desc'] as String,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkCaption : null,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _LanguageOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.language_rounded,
              size: 22,
              color: isSelected
                  ? (isDark ? AppColors.leafGreen : AppColors.primaryGreen)
                  : (isDark ? AppColors.darkCaption : AppColors.caption),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: isSelected
                          ? (isDark ? AppColors.leafGreen : AppColors.primaryGreen)
                          : (isDark ? AppColors.darkHeadingText : AppColors.darkText),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: isDark ? AppColors.darkCaption : null,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppColors.leafGreen : AppColors.primaryGreen)
                      : (isDark ? AppColors.darkDivider : AppColors.divider),
                  width: 2,
                ),
                color: isSelected
                    ? (isDark ? AppColors.leafGreen : AppColors.primaryGreen)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: AppColors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
