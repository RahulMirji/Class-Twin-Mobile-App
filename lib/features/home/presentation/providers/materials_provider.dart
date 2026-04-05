import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/materials_repository.dart';
import '../../domain/models/study_material.dart';

/// Provider for materials repository
final materialsRepositoryProvider = Provider((ref) => MaterialsRepository());

/// Provider for the list of study materials
final materialsProvider = FutureProvider<List<StudyMaterial>>((ref) async {
  final repo = ref.watch(materialsRepositoryProvider);
  return repo.getMaterials();
});

/// Provider for materials filtered by subject
final materialsBySubjectProvider = FutureProvider.family<List<StudyMaterial>, String>((ref, subject) async {
  final repo = ref.watch(materialsRepositoryProvider);
  return repo.getMaterialsBySubject(subject);
});
