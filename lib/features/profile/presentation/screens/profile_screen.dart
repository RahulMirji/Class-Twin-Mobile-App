import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentName = ref.watch(studentNameProvider) ?? 'Student';
    final authState = ref.watch(authStateProvider);
    final email = authState.value?.email ?? 'No email linked';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Profile', style: AppTheme.headlineMedium),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Profile Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.tertiary.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.surfaceContainerLow,
                          child: Text(
                            studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                            style: AppTheme.displayLarge.copyWith(
                              color: AppTheme.tertiary,
                              fontSize: 40,
                            ),
                          ),
                        ),
                      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    studentName,
                    style: AppTheme.displaySmall,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: AppTheme.bodyMedium,
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),

            // ─── Menu Sections ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Account Settings'),
                  _MenuTile(
                    icon: PhosphorIconsRegular.user,
                    title: 'Personal Information',
                    onTap: () {},
                  ),
                  _MenuTile(
                    icon: PhosphorIconsRegular.shieldCheck,
                    title: 'Security & Privacy',
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('App Settings'),
                  _MenuTile(
                    icon: PhosphorIconsRegular.bell,
                    title: 'Notifications',
                    trailing: Switch.adaptive(
                      value: true,
                      onChanged: (v) {},
                      activeColor: AppTheme.tertiary,
                    ),
                  ),
                  _MenuTile(
                    icon: PhosphorIconsRegular.palette,
                    title: 'Appearance',
                    subtitle: 'Light Mode',
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('Support'),
                  _MenuTile(
                    icon: PhosphorIconsRegular.question,
                    title: 'Help Center',
                    onTap: () {},
                  ),
                  _MenuTile(
                    icon: PhosphorIconsRegular.info,
                    title: 'About ClassTwin',
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // ─── Logout ──────────────────────────────────────────
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
                        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 48),
                  
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTheme.labelSmall.copyWith(
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTheme.displaySmall.copyWith(fontSize: 24),
          ),
          Text(
            label,
            style: AppTheme.labelSmall,
          ),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, size: 20, color: AppTheme.textPrimary),
        ),
        title: Text(title, style: AppTheme.titleMedium),
        subtitle: subtitle != null 
            ? Text(subtitle!, style: AppTheme.bodySmall) 
            : null,
        trailing: trailing ?? Icon(
          PhosphorIconsRegular.caretRight,
          size: 16,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }
}
