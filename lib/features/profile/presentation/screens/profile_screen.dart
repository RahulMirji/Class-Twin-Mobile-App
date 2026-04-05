import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        backgroundColor: AppTheme.primary,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentName = ref.watch(studentNameProvider) ?? 'Student';
    final authState = ref.watch(authStateProvider);
    final email = authState.value?.email ?? 'No email linked';
    final initial = studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Gradient Header with Profile ──────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                  child: Column(
                    children: [
                      // App bar row
                      Row(
                        children: [
                          Text('Profile', style: AppTheme.titleLarge),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Avatar with amber gradient ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB8622A), Color(0xFFF5C397)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: AppTheme.primaryContainer,
                            child: Text(
                              initial,
                              style: AppTheme.displaySmall.copyWith(
                                color: AppTheme.primary,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                       .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.03, 1.03), curve: Curves.easeInOut),

                      const SizedBox(height: 16),

                      Text(
                        studentName,
                        style: AppTheme.displaySmall,
                      ).animate().fadeIn(delay: 150.ms),

                      const SizedBox(height: 6),

                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: email));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Email copied to clipboard!'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                              backgroundColor: AppTheme.tertiary,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Text(
                            email,
                            style: AppTheme.bodySmall,
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Menu Sections ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Account Settings'),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: PhosphorIconsRegular.user,
                    title: 'Personal Information',
                    onTap: () => _showComingSoon(context),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
                  _MenuTile(
                    icon: PhosphorIconsRegular.shieldCheck,
                    title: 'Security & Privacy',
                    onTap: () => _showComingSoon(context),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),

                  const SizedBox(height: 28),
                  _buildSectionHeader('App Settings'),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: PhosphorIconsRegular.bell,
                    title: 'Notifications',
                    trailing: Switch.adaptive(
                      value: true,
                      onChanged: (v) {},
                      activeColor: AppTheme.primary,
                      activeThumbColor: Colors.white,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: AppTheme.surfaceContainerHighest,
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
                  _MenuTile(
                    icon: PhosphorIconsRegular.palette,
                    title: 'Appearance',
                    subtitle: 'Light Mode',
                    onTap: () => _showComingSoon(context),
                  ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),

                  const SizedBox(height: 28),
                  _buildSectionHeader('Support'),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: PhosphorIconsRegular.question,
                    title: 'Help Center',
                    onTap: () => _showComingSoon(context),
                  ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1),
                  _MenuTile(
                    icon: PhosphorIconsRegular.info,
                    title: 'About Class Twin',
                    onTap: () => _showComingSoon(context),
                  ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.1),

                  const SizedBox(height: 36),

                  // ─── Logout ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).signOut();
                      },
                      icon: Icon(PhosphorIconsBold.signOut, color: AppTheme.error, size: 20),
                      label: Text(
                        'Log Out',
                        style: AppTheme.labelLarge.copyWith(color: AppTheme.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.35)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 28),

                  Center(
                    child: Text(
                      'Version 1.0.2',
                      style: AppTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: AppTheme.labelSmall.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.selectionClick(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          title: Text(title, style: AppTheme.titleMedium),
          subtitle: subtitle != null
              ? Text(subtitle!, style: AppTheme.bodySmall)
              : null,
          trailing: trailing ??
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: AppTheme.textTertiary,
              ),
        ),
      ),
    );
  }
}
