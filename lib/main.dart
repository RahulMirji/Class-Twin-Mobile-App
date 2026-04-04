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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
  );

  // Initialize notifications
  await container.read(notificationServiceProvider).init();

  // Initialize Sentry for error tracking
  await SentryFlutter.init(
    (options) {
      options.dsn = AppConstants.sentryDsn;
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      await Hive.initFlutter();
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const ClassTwinApp(),
        ),
      );
    },
  );
}
