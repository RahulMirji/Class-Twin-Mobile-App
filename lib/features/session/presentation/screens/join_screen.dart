import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../domain/models/student.dart';
import '../providers/session_provider.dart';
import '../../domain/session_state.dart';

import '../../../../core/providers/preferences_provider.dart';

/// JoinScreen — Mode selection
class JoinScreen extends ConsumerStatefulWidget {
  final String sessionCode;
  const JoinScreen({super.key, required this.sessionCode});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  StudentMode? _selectedMode;
  bool _isJoining = false;

  void _joinSession() async {
    final name = ref.read(studentNameProvider);
    if (name == null || name.isEmpty) return;

    final mode = _selectedMode ?? StudentMode.inRoom;

    setState(() => _isJoining = true);

    await ref.read(sessionStateProvider.notifier).joinSession(
          joinCode: widget.sessionCode,
          studentName: name,
          mode: mode,
        );

    if (!mounted) return;

    final state = ref.read(sessionStateProvider);
    if (state is SessionError) {
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppTheme.error,
        ),
      );
    } else {
      context.go('/session');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.onboardingGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Back button
                        GestureDetector(
                          onTap: () => context.go('/'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Icon(
                              PhosphorIconsBold.caretLeft,
                              color: AppTheme.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          'How are you\njoining?',
                          style: AppTheme.displayMedium.copyWith(height: 1.15),
                        ).animate().fadeIn(duration: 500.ms),

                        const SizedBox(height: 6),
                        Text(
                          'Session Mode',
                          style: AppTheme.labelMedium.copyWith(color: AppTheme.textTertiary),
                        ),

                        const SizedBox(height: 28),

                        // Mode card A: In Room
                        _ModeCard(
                          icon: PhosphorIconsBold.mapPin,
                          title: "I'm in the classroom",
                          subtitle: 'Sync with local hardware',
                          isSelected: _selectedMode == StudentMode.inRoom,
                          onTap: () => setState(() => _selectedMode = StudentMode.inRoom),
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                        const SizedBox(height: 12),

                        // Mode card B: Remote
                        _ModeCard(
                          icon: PhosphorIconsBold.monitor,
                          title: "I'm joining remotely",
                          subtitle: 'Virtual learning environment',
                          badge: 'Requires good WiFi',
                          isSelected: _selectedMode == StudentMode.remote,
                          onTap: () => setState(() => _selectedMode = StudentMode.remote),
                        ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                        const Spacer(),

                        // Join button
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _selectedMode != null && !_isJoining ? _joinSession : null,
                            child: _isJoining
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppTheme.onPrimary,
                                    ),
                                  )
                                : const Text('Continue', style: TextStyle(fontSize: 16)),
                          ),
                        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'By joining you agree to our terms of conduct',
                            style: AppTheme.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceContainerLowest : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.ambientShadowWarm : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryContainer : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTheme.bodySmall),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.responseSomewhat.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  badge!,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.responseSomewhat,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(PhosphorIconsFill.checkCircle, color: AppTheme.primary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
