import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/study_material.dart';

/// Repository for fetching study materials/notes
class MaterialsRepository {
  final _client = Supabase.instance.client;

  /// Get all published materials
  Future<List<StudyMaterial>> getMaterials() async {
    final response = await _client
        .from('materials')
        .select()
        .eq('status', 'published')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => StudyMaterial.fromJson(json))
        .toList();
  }

  /// Get materials filtered by subject
  Future<List<StudyMaterial>> getMaterialsBySubject(String subject) async {
    final response = await _client
        .from('materials')
        .select()
        .eq('status', 'published')
        .eq('subject', subject)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => StudyMaterial.fromJson(json))
        .toList();
  }
}
