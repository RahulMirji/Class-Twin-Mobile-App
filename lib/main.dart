import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'core/providers/preferences_provider.dart';
import 'app.dart';

import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/providers/notification_provider.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Start critical initializations in parallel
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      Hive.initFlutter(),
      Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      ).timeout(const Duration(seconds: 15)),
    ]);

    final sharedPreferences = results[0] as SharedPreferences;
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );

    // Initialize notifications
    await container.read(notificationServiceProvider).init();

    // Initialize Sentry and Run App
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConstants.sentryDsn;
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(
        UncontrolledProviderScope(
          container: container,
          child: const ClassTwinApp(),
        ),
      ),
    );
  } catch (e, stack) {
    debugPrint('Critical Initialization Error: $e');
    debugPrint(stack.toString());
    
    // Run minimal app to show error if possible, or just remove splash
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Failed to start app: $e\n\nPlease check your internet connection.'),
          ),
        ),
      ),
    ));
  } finally {
    FlutterNativeSplash.remove();
  }
}
