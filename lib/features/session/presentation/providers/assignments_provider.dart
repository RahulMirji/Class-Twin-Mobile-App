import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:class_twin/features/session/data/assignments_repository.dart';
import 'package:class_twin/features/session/domain/models/remedial_assignment.dart';
import 'package:class_twin/core/providers/preferences_provider.dart';

final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  return AssignmentsRepository();
});

final assignedQuizzesProvider = FutureProvider<List<RemedialAssignment>>((ref) async {
  final studentName = ref.watch(studentNameProvider);
  if (studentName == null) return [];

  final repository = ref.watch(assignmentsRepositoryProvider);
  return repository.fetchAssignedQuizzes(studentName);
});
