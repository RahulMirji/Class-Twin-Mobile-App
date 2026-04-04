import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme.dart';
import '../../domain/models/student.dart';
import '../providers/session_provider.dart';
import '../../domain/session_state.dart';

/// JoinScreen — Step 1: Name entry, Step 2: Mode selection (conditional)
class JoinScreen extends ConsumerStatefulWidget {
  final String sessionCode;
  const JoinScreen({super.key, required this.sessionCode});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _nameController = TextEditingController();
  int _step = 1;
  StudentMode? _selectedMode;
  bool _isJoining = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _step = 2);
  }

  void _joinSession() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _step == 1 ? _buildStep1() : _buildStep2(),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        IconButton(
          onPressed: () => context.go('/'),
          icon: Icon(PhosphorIconsBold.caretLeft,
              color: AppTheme.textPrimary, size: 22),
        ),
        const SizedBox(height: 40),

        // Question
        Text(
          "What's your name?",
          style: AppTheme.displayMedium,
        ).animate().fadeIn(duration: 500.ms),

        const SizedBox(height: 12),
        Text(
          'To personalize your learning journey, we\'d love to know how to address you in our digital atelier.',
          style: AppTheme.bodyMedium,
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        const SizedBox(height: 40),

        // Name input
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: AppTheme.titleLarge,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: AppTheme.titleLarge.copyWith(
              color: AppTheme.textTertiary.withValues(alpha: 0.5),
            ),
          ),
          onSubmitted: (_) => _goToStep2(),
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

        const Spacer(),

        // Continue button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _goToStep2,
            child: const Text('Continue'),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

        const SizedBox(height: 12),

        Center(
          child: Text(
            'By continuing, you agree to our Terms of Service',
            style: AppTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _step = 1),
              icon: Icon(PhosphorIconsBold.caretLeft,
                  color: AppTheme.textPrimary, size: 22),
            ),
            const Spacer(),
            Text(
              'Step 2 of 3',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ],
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
