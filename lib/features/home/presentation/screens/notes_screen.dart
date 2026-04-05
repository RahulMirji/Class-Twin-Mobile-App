import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme.dart';
import '../providers/materials_provider.dart';
import '../../domain/models/study_material.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ─── Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              centerTitle: false,
              title: Text(
                'Study Notes',
                style: AppTheme.displaySmall.copyWith(color: AppTheme.textPrimary),
              ),
              background: Container(color: AppTheme.surface),
            ),
          ),

          // ─── Content ─────────────────────────────────────────
          materialsAsync.when(
            data: (materials) => materials.isEmpty
                ? const SliverFillRemaining(
                    child: _EmptyNotesState(),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final material = materials[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _NoteCard(material: material)
                                .animate()
                                .fadeIn(delay: (index * 50).ms, duration: 400.ms)
                                .slideY(begin: 0.05, end: 0),
                          );
                        },
                        childCount: materials.length,
                      ),
                    ),
                  ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final StudyMaterial material;

  const _NoteCard({required this.material});

  IconData _getIcon() {
    switch (material.fileExtension) {
      case 'pdf':
        return PhosphorIconsFill.filePdf;
      case 'doc':
      case 'docx':
        return PhosphorIconsFill.fileDoc;
      case 'ppt':
      case 'pptx':
        return PhosphorIconsFill.filePpt;
      case 'jpg':
      case 'png':
        return PhosphorIconsFill.fileImage;
      default:
        return PhosphorIconsFill.file;
    }
  }

  Color _getIconColor() {
    switch (material.fileExtension) {
      case 'pdf':
        return const Color(0xFFE53935); // PDF Red
      case 'doc':
      case 'docx':
        return const Color(0xFF1E88E5); // Word Blue
      default:
        return AppTheme.primary;
    }
  }

  Future<void> _openNote() async {
    if (material.storageUrl == null) return;
    final url = Uri.parse(material.storageUrl!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openNote,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // File Type Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getIconColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Icon(_getIcon(), color: _getIconColor(), size: 28),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.subject.toUpperCase(),
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        material.title,
                        style: AppTheme.titleMedium.copyWith(height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        material.topic ?? 'General Topic',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                
                // Download/View Action
                IconButton(
                  onPressed: _openNote,
                  icon: Icon(
                    PhosphorIconsRegular.downloadSimple,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotesState extends StatelessWidget {
  const _EmptyNotesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.bookOpen,
            size: 64,
            color: AppTheme.textTertiary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes uploaded yet',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            'Your teacher will share study materials here.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
