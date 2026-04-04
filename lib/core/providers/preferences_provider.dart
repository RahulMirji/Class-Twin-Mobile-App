import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the initial SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

// A provider that handles getting and setting the student's name
class StudentNameNotifier extends Notifier<String?> {
  static const _key = 'student_name';

  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_key);
  }

  Future<void> setName(String name) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, name);
    state = name;
  }
}

final studentNameProvider = NotifierProvider<StudentNameNotifier, String?>(() {
  return StudentNameNotifier();
});
