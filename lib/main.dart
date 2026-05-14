import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/nav.dart';
import 'package:musicbyteai/services/settings_service.dart';
import 'package:musicbyteai/services/audio_engine_service.dart';
import 'dart:async';

/// Main entry point for the application
///
/// This sets up:
/// - Provider state management (ThemeProvider, CounterProvider)
/// - go_router navigation
/// - Material 3 theming with light/dark modes
Future<void> main() async {
  // Required before touching WidgetsBinding/PlatformDispatcher or any plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers so red screens include stack traces in logs
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) debugPrint(details.stack.toString());
  };
  // Catch uncaught async errors

  // Use a zone so any uncaught async errors in release builds still hit logs.
  runZonedGuarded(() {
    WidgetsBinding.instance.platformDispatcher.onError = (Object error, StackTrace stack) {
      debugPrint('Uncaught error: $error');
      debugPrint(stack.toString());
      return true; // handled
    };

    // IMPORTANT: draw the first Flutter frame ASAP.
    // If we await plugin calls here and they hang (rare, but can happen on some
    // release builds/devices), Android will keep showing the native launch screen
    // and eventually raise an ANR (“isn't responding”).
    runApp(const MyApp());

    // Load persisted settings *after* the app has started.
    // The ValueListenableBuilder in MyApp will rebuild when notifier updates.
    Future<void>(() async {
      try {
        await SettingsService.instance.load().timeout(const Duration(seconds: 3));

        // Warm up audio on mobile so the first tone tap works consistently.
        // (On iOS, this also ensures the audio session is configured.)
        AudioEngineService();
      } catch (e, st) {
        debugPrint('Main: deferred settings init failed: $e');
        debugPrint(st.toString());
      }
    });
  }, (error, stack) {
    debugPrint('Zone uncaught error: $error');
    debugPrint(stack.toString());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the app to provide state to all widgets
    // As you extend the app, use MultiProvider to wrap the app
    // and provide state to all widgets
    // Example:
    // return MultiProvider(
    //   providers: [
    //     ChangeNotifierProvider(create: (_) => ExampleProvider()),
    //   ],
    //   child: MaterialApp.router(
    //     title: 'Dreamflow Starter',
    //     debugShowCheckedModeBanner: false,
    //     routerConfig: AppRouter.router,
    //   ),
    // );
    return ValueListenableBuilder(
      valueListenable: SettingsService.instance.notifier,
      builder: (context, settings, _) {
        final prefersDark = settings?.darkMode ?? true; // fall back to dark per defaults
        final schemeId = appColorSchemeIdFromString(settings?.appColorScheme);
        return MaterialApp.router(
          title: 'MusicByte',
          debugShowCheckedModeBanner: false,
          theme: appLightTheme(schemeId),
          darkTheme: appDarkTheme(schemeId),
          themeMode: prefersDark ? ThemeMode.dark : ThemeMode.light,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            final safeChild = child ?? const SizedBox.shrink();
            return AppAmbientBackground(child: safeChild);
          },
        );
      },
    );
  }
}
