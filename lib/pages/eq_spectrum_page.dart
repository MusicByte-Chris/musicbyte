import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/pages/engineer_reference_page.dart';
import 'package:musicbyteai/theme.dart';

class EqSpectrumPage extends StatefulWidget {
  const EqSpectrumPage({super.key});

  @override
  State<EqSpectrumPage> createState() => _EqSpectrumPageState();
}

class _EqSpectrumPageState extends State<EqSpectrumPage> {
  @override
  void initState() {
    super.initState();
    // Lock to landscape for better horizontal workspace
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]).catchError((e) => debugPrint('Orientation lock failed: $e'));
  }

  @override
  void dispose() {
    // Restore to portrait up as a sane default for the rest of the app
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).catchError((e) => debugPrint('Orientation restore failed: $e'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final barHeight = size.shortestSide * 0.22; // make it visually prominent in landscape
    final baseWidth = size.longestSide * 2; // more scrollable resolution

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => context.pop(),
          icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
        ),
        title: Text('Interactive EQ Spectrum', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Spectrum
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: InteractiveEqSpectrum(
                    barHeight: barHeight.clamp(60, 140),
                    baseWidth: baseWidth.clamp(1200, 3200),
                    showInstrumentChips: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Hint Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_rounded, color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Tap a band for details, then play the center frequency. Use highlight chips to focus on an instrument.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
