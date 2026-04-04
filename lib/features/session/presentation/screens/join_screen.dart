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
    if (name == null || name.isEmpty) return; // Should not happen with onboarding guard

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
      // Navigation is handled by the router redirect
      context.go('/session');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                      IconButton(
                        onPressed: () => context.go('/'),
                        icon: Icon(PhosphorIconsBold.caretLeft,
                            color: AppTheme.textPrimary, size: 22),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        'How are you joining?',
                        style: AppTheme.displayMedium,
                      ).animate().fadeIn(duration: 500.ms),

                      const SizedBox(height: 8),
                      Text(
                        'Session Mode',
                        style: AppTheme.labelMedium.copyWith(color: AppTheme.textTertiary),
                      ),

                      const SizedBox(height: 32),

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
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _selectedMode != null && !_isJoining ? _joinSession : null,
                          child: _isJoining
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.onPrimary,
                                  ),
                                )
                              : const Text('Continue'),
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
          color: isSelected
              ? AppTheme.surfaceContainerLowest
              : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected ? AppTheme.ambientShadow : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryContainer
                    : AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textTertiary,
                  size: 22),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.responseSomewhat.withValues(alpha: 0.15),
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
          ],
        ),
      ),
    );
  }
}
