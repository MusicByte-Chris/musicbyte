import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/home_page.dart';
import 'pages/circle_fifths_page.dart';
import 'pages/key_detail_page.dart';
import 'pages/tools_page.dart';
import 'pages/engineer_reference_page.dart';
import 'pages/practice_log_page.dart';
import 'pages/settings_page.dart';
import 'pages/upgrade_page.dart';
import 'pages/about_page.dart';
import 'pages/chord_scale_viewer_page.dart';
import 'pages/metronome_settings_page.dart';
import 'pages/ear_trainer_page.dart';
import 'pages/eq_spectrum_page.dart';
import 'pages/pro_tools_shortcuts_page.dart';
import 'pages/note_assault_page.dart';
import 'pages/theory_reference_page.dart';
import 'pages/splash_page.dart';
import 'pages/rhythm_trainer_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // Showing a splash via `initialLocation` only works when the app starts at
  // an empty URL. On web refresh, the browser typically reloads the current
  // location (e.g. '/'), bypassing `initialLocation`. We use a redirect to
  // show the splash once per app start (session).
  static bool _didShowSplashThisSession = false;

  static void markSplashShown() => _didShowSplashThisSession = true;

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final location = state.uri.toString();
      if (location.startsWith(AppRoutes.splash)) return null;
      if (_didShowSplashThisSession) return null;

      final next = Uri.encodeComponent(location);
      return '${AppRoutes.splash}?next=$next';
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const NoTransitionPage(child: SplashPage()),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: AppRoutes.circle,
            pageBuilder: (context, state) => const NoTransitionPage(child: CircleOfFifthsPage()),
          ),
          GoRoute(
            path: AppRoutes.tools,
            pageBuilder: (context, state) => const NoTransitionPage(child: ToolsPage()),
          ),
          GoRoute(
            path: AppRoutes.reference,
            pageBuilder: (context, state) => const NoTransitionPage(child: EngineerReferencePage()),
          ),
          GoRoute(
            path: AppRoutes.log,
            pageBuilder: (context, state) => const NoTransitionPage(child: PracticeLogPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/key/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return KeyDetailPage(keyId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.viewer,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final keyId = state.uri.queryParameters['key'] ?? 'c_major';
          final startWithScale = (state.uri.queryParameters['tab'] ?? 'chord') == 'scale';
          return ChordScaleViewerPage(keyId: keyId, startWithScale: startWithScale);
        },
      ),
      GoRoute(
        path: AppRoutes.eqSpectrum,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EqSpectrumPage(),
      ),
      GoRoute(
        path: AppRoutes.proToolsShortcuts,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProToolsShortcutsPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.metronomeSettings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MetronomeSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.upgrade,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UpgradePage(),
      ),
      GoRoute(
        path: AppRoutes.about, // Assuming you might want to link here from somewhere
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.earTrainer,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EarTrainerPage(),
      ),
      GoRoute(
        path: AppRoutes.noteAssault,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NoteAssaultPage(),
      ),
      GoRoute(
        path: AppRoutes.theoryReference,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TheoryReferencePage(),
      ),
      GoRoute(
        path: AppRoutes.rhythmTrainer,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RhythmTrainerPage(),
      ),
    ],
  );
}

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String circle = '/circle';
  static const String tools = '/tools';
  static const String reference = '/reference';
  static const String log = '/log';
  static const String settings = '/settings';
  static const String upgrade = '/upgrade';
  static const String about = '/about';
  static const String viewer = '/viewer';
  static const String metronomeSettings = '/metronome-settings';
  static const String earTrainer = '/ear-trainer';
  static const String eqSpectrum = '/eq-spectrum';
  static const String proToolsShortcuts = '/pro-tools-shortcuts';
  static const String noteAssault = '/note-assault';
  static const String theoryReference = '/theory-reference';
  static const String rhythmTrainer = '/rhythm-trainer';
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _getSelectedIndex(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        if (!isDesktop) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.music_note_outlined), selectedIcon: Icon(Icons.music_note_rounded), label: 'Keys'),
                NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build_rounded), label: 'Tools'),
                NavigationDestination(icon: Icon(Icons.equalizer_outlined), selectedIcon: Icon(Icons.equalizer_rounded), label: 'Ref'),
                NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today_rounded), label: 'Log'),
              ],
            ),
          );
        }

        // Desktop / wide layout: NavigationRail + centered content.
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text('Home')),
                    NavigationRailDestination(icon: Icon(Icons.music_note_outlined), selectedIcon: Icon(Icons.music_note_rounded), label: Text('Keys')),
                    NavigationRailDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build_rounded), label: Text('Tools')),
                    NavigationRailDestination(icon: Icon(Icons.equalizer_outlined), selectedIcon: Icon(Icons.equalizer_rounded), label: Text('Ref')),
                    NavigationRailDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today_rounded), label: Text('Log')),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  int _getSelectedIndex(String location) {
    if (location == AppRoutes.home) return 0;
    if (location == AppRoutes.circle) return 1;
    if (location == AppRoutes.tools) return 2;
    if (location == AppRoutes.reference) return 3;
    if (location == AppRoutes.log) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.circle);
        break;
      case 2:
        context.go(AppRoutes.tools);
        break;
      case 3:
        context.go(AppRoutes.reference);
        break;
      case 4:
        context.go(AppRoutes.log);
        break;
    }
  }
}
