import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/nav.dart';
import 'package:musicbyteai/theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  // NOTE: Asset paths are case-sensitive (especially on web).
  // Keep this in sync with the exact filename shown in Dreamflow's Assets panel.
  static const _logoAssetPath = 'assets/images/MusicByteLogo.jpg';
  static const _minSplashDuration = Duration(milliseconds: 1400);
  static const _precacheTimeout = Duration(milliseconds: 700);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  String _status = 'starting';
  String? _navError;
  bool _showFallback = false;
  Timer? _watchdog;
  Timer? _ticker;
  int _elapsedSeconds = 0;
  final DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();

    debugPrint('Splash: initState');

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.98, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    // If anything goes wrong in navigation (route errors, plugin stalls, etc.),
    // show a manual "Continue" button so the app never appears frozen.
    _watchdog = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      debugPrint('Splash: watchdog fired (showing fallback UI)');
      setState(() => _showFallback = true);
    });

    // Visible on-screen ticker so we can confirm timers/frames are progressing
    // even in release builds.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds = DateTime.now().difference(_startedAt).inSeconds);
    });

    // Ensure the splash stays visible briefly, then navigate.
    // IMPORTANT: wait until after the first frame so plugin channels are ready
    // in release builds (calling permission_handler too early can hang on some devices).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('Splash: first frame rendered; starting _goNext()');
      unawaited(_goNext());
    });
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    setState(() {
      _status = 'preparing';
      _navError = null;
    });

    // On web, image decoding/precaching can occasionally stall. We keep the splash
    // up for a minimum duration, but we *cap* how long we'll wait for precache so
    // the app never gets stuck on the splash.
    final logo = const AssetImage(_logoAssetPath);

    try {
      await Future.wait([
        Future<void>.delayed(_minSplashDuration),
        _precacheWithTimeout(logo),
      ]).timeout(const Duration(seconds: 3));
    } catch (e, st) {
      debugPrint('Splash: init wait failed (continuing anyway): $e');
      debugPrint(st.toString());
    }

    if (!mounted) return;

    setState(() => _status = 'navigating');

    // Mark the splash as shown so the router redirect doesn't loop.
    AppRouter.markSplashShown();

    final nextRaw = GoRouterState.of(context).uri.queryParameters['next'];
    final next = (nextRaw == null || nextRaw.isEmpty) ? AppRoutes.home : Uri.decodeComponent(nextRaw);
    try {
      if (next.startsWith(AppRoutes.splash)) {
        debugPrint('Splash navigating to Home (next was splash).');
        context.go(AppRoutes.home);
      } else {
        debugPrint('Splash navigating to: $next');
        context.go(next);
      }
      _watchdog?.cancel();
    } catch (e, st) {
      debugPrint('Splash: navigation failed: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      setState(() {
        _navError = e.toString();
        _showFallback = true;
        _status = 'navigation_error';
      });
    }
  }

  void _forceContinue() {
    try {
      AppRouter.markSplashShown();
      context.go(AppRoutes.home);
      _watchdog?.cancel();
    } catch (e, st) {
      debugPrint('Splash: force continue failed: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      setState(() {
        _navError = e.toString();
        _showFallback = true;
      });
    }
  }

  Future<void> _precacheWithTimeout(ImageProvider provider) async {
    try {
      // First, validate that the asset is present in the bundle. If it isn't,
      // `Image.asset` can fail silently on some web builds.
      await Future.any([
        rootBundle.load(_logoAssetPath),
        Future<void>.delayed(_precacheTimeout),
      ]);

      // Then try to decode/cache it. We cap waiting time so navigation never hangs.
      await Future.any([
        precacheImage(provider, context),
        Future<void>.delayed(_precacheTimeout),
      ]);
    } catch (e, st) {
      debugPrint('Splash logo precache failed for $_logoAssetPath: $e');
      debugPrint(st.toString());
    }
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark ? AppColors.splashBackgroundDark : AppColors.splashBackgroundLight;
    final route = GoRouterState.of(context).uri.toString();

    // NOTE: We avoid Color.withValues(...) here because we've seen a startup crash
    // on web builds where a named-parameter mismatch results in a null->int cast.
    // Using withAlpha keeps this splash screen maximally robust.
    Color alpha(Color c, double a) => c.withAlpha((a.clamp(0.0, 1.0) * 255).round());

    // Splash background is always black, but the app may be in light theme.
    // Force readable foreground colors here so diagnostics/buttons can never be “invisible”.
    final diagStyle = theme.textTheme.labelSmall?.copyWith(color: alpha(AppColors.splashForeground, 0.92), height: 1.2);
    final bodyMutedStyle = theme.textTheme.bodyMedium?.copyWith(color: alpha(AppColors.splashForegroundMuted, 0.9), height: 1.4);

    return Scaffold(
      backgroundColor: bg,
      body: ColoredBox(
        color: bg,
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SplashLogo(theme: theme),
                        const SizedBox(height: 18),
                        AnimatedOpacity(
                          opacity: _showFallback ? 1 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'If the app doesn\'t continue automatically, tap below.',
                                textAlign: TextAlign.center,
                                style: bodyMutedStyle,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _forceContinue,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                  child: Text('Continue', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                                ),
                              ),
                              if (_navError != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Navigation error: $_navError',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.splashForegroundError),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Always-on diagnostics (high contrast), so it can't fail silently.
                        const SizedBox(height: 14),
                        Text(
                          'Loading… ${_elapsedSeconds}s\nStatus: $_status\nRoute: $route',
                          textAlign: TextAlign.center,
                          style: diagStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.theme});

  final ThemeData theme;

  static const _logoAssetPath = 'assets/images/MusicByteLogo.jpg';

  @override
  Widget build(BuildContext context) {
    return Image(
      image: const AssetImage(_logoAssetPath),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return SizedBox(
          height: 180,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Splash Image.asset error for $_logoAssetPath: $error');
        if (stackTrace != null) debugPrint(stackTrace.toString());

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.graphic_eq_rounded, size: 44, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('MusicByte', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Logo failed to load.\nExpected: $_logoAssetPath',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}
