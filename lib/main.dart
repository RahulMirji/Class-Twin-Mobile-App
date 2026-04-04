import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // NOTE: Supabase initialization is skipped in demo mode.
  // Uncomment the block below and set your credentials in constants.dart
  // when you're ready to connect to your backend.
  //
  // await Supabase.initialize(
  //   url: AppConstants.supabaseUrl,
  //   anonKey: AppConstants.supabaseAnonKey,
  // );

  runApp(
    const ProviderScope(
      child: ClassTwinApp(),
    ),
  );
}
