import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/models/app_settings.dart';
import 'package:musicbyteai/services/settings_service.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/widgets/responsive_centered.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppSettings? _settings;
  bool _loading = true;

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://app.musicbyte.dev/privacy');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) debugPrint('Failed to open privacy policy: $uri');
    } catch (e) {
      debugPrint('Failed to open privacy policy: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsService.instance.load();
    if (mounted) setState(() {
      _settings = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSchemeId = appColorSchemeIdFromString(_settings?.appColorScheme);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveCentered(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  child: Text("Configure your professional workspace", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
                ),
          
          _SectionHeader(title: "THEORY & ENGINEERING"),
          _SettingTile(
            icon: Icons.tune_rounded,
            title: "A4 Reference Frequency",
            subtitle: "Standard pitch for tone generation",
            trailing: _Dropdown(
              value: _settings!.a4Reference,
              options: const ["432 Hz", "440 Hz", "441 Hz", "442 Hz", "444 Hz"],
              onChanged: (v) async {
                if (v == null) return;
                await SettingsService.instance.update(a4Reference: v);
                await _load();
              },
            ),
          ),
          _SettingTile(
            icon: Icons.music_note_rounded,
            title: "Enharmonic Preference",
            subtitle: "How accidentals are displayed",
            trailing: _Dropdown(
              value: _settings!.enharmonicPreference,
              options: const ["Sharps (#)", "Flats (b)", "Contextual"],
              onChanged: (v) async {
                if (v == null) return;
                await SettingsService.instance.update(enharmonicPreference: v);
                await _load();
              },
            ),
          ),
          _SettingTile(
            icon: Icons.grid_on_rounded,
            title: "Notation System",
            trailing: _Dropdown(
              value: _settings!.notationSystem,
              options: const ["English", "Latin", "German"],
              onChanged: (v) async {
                if (v == null) return;
                await SettingsService.instance.update(notationSystem: v);
                await _load();
              },
            ),
          ),

          _SectionHeader(title: "INTERFACE"),
          _SettingTile(
            icon: Icons.light_mode_rounded,
            title: "Lite Mode",
            subtitle: "Brighter palette for daylight sessions",
            trailing: Switch(
              value: !_settings!.darkMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (v) async {
                // v=true => Lite mode => darkMode=false
                await SettingsService.instance.update(darkMode: !v);
              await _load();
              },
            ),
          ),
          _SettingTile(
            icon: Icons.palette_rounded,
            title: "App Color Scheme",
            subtitle: "${appColorSchemeLabel(currentSchemeId)} · applies globally",
            trailing: OutlinedButton(
              onPressed: () async {
                final selected = await showModalBottomSheet<AppColorSchemeId>(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  // Avoid relying on nullable CardThemeData.color; ensure a stable, non-null surface.
                  backgroundColor: theme.colorScheme.surface,
                  isDismissible: true,
                  enableDrag: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                  builder: (_) => _ColorSchemePickerSheet(selected: currentSchemeId),
                );
                if (selected == null) return;
                await SettingsService.instance.update(appColorScheme: selected.name);
                await _load();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Choose', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                ],
              ),
            ),
          ),
          _SettingTile(
            icon: Icons.touch_app_rounded,
            title: "Haptic Feedback",
            subtitle: "Tactile response on metronome/tuner",
            trailing: Switch(value: _settings!.haptics, activeColor: theme.colorScheme.primary, onChanged: (v) async {
              await SettingsService.instance.update(haptics: v);
              await _load();
            }),
          ),

          _SectionHeader(title: "LICENSE & SUPPORT"),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.safeCardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: theme.colorScheme.primary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.article_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "License",
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "MIT licensed",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.forum_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Support",
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Community Support",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                ),
              ],
            ),
          ),
          _SettingTile(
            icon: Icons.favorite_rounded,
            title: "Tip Jar",
            subtitle: "Support independent utility development",
            trailing: Icon(Icons.chevron_right_rounded, color: theme.hintColor),
            onTap: () => context.push('/upgrade'),
          ),

          _SectionHeader(title: "ABOUT"),
          Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 40),
            padding: const EdgeInsets.all(20),
            color: theme.safeCardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoRow(label: "Version", value: "1.04 (Build 191)"),
                const SizedBox(height: 12),
                _InfoRow(label: "Developer", value: "Engineered by MusicByte"),
                const SizedBox(height: 12),
                Divider(color: theme.dividerColor, thickness: 0.5),
                const SizedBox(height: 16),
                Text(
                  "MusicByte is a specialized utility for audio engineers and musicians. Built for speed, precision, and offline reliability.",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _openPrivacyPolicy,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        overlayColor: Colors.transparent,
                      ),
                      child: Text(
                        "Privacy Policy",
                        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(color: theme.dividerColor, shape: BoxShape.circle),
                    ),
                    Text("Terms of Service", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
              ],
            ),
          ),
              ],
            ),
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.safeCardColor,
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String?>? onChanged;

  const _Dropdown({required this.value, required this.options, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: theme.textTheme.bodyMedium))).toList(),
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
          icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _ColorSchemePickerSheet extends StatelessWidget {
  final AppColorSchemeId selected;
  const _ColorSchemePickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    final specs = AppColorSchemes.all;
    if (kDebugMode) debugPrint('ColorSchemePickerSheet: specs=${specs.length}, selected=$selected');
    return SafeArea(
      child: Material(
        color: theme.colorScheme.surface,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          child: SizedBox(
            height: maxHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'App Color Schemes',
                          style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        // Bottom sheets are presented with Navigator; pop via rootNavigator to be robust.
                        onPressed: () => Navigator.of(context, rootNavigator: true).maybePop(),
                        icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick a global look for both Lite + Dark modes.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: specs.isEmpty
                        ? Center(
                            child: Text(
                              'No schemes available (unexpected).',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              for (final spec in specs) ...[
                                _ColorSchemeOptionTile(
                                  spec: spec,
                                  selected: spec.id == selected,
                                  onTap: () => Navigator.of(context, rootNavigator: true).pop(spec.id),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSchemeOptionTile extends StatelessWidget {
  final AppColorSchemeSpec spec;
  final bool selected;
  final VoidCallback onTap;
  const _ColorSchemeOptionTile({required this.spec, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = selected ? theme.colorScheme.primary : theme.dividerColor;
    final bg = selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.scaffoldBackgroundColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: border, width: selected ? 1.2 : 1),
          ),
          child: Row(
            children: [
              _SchemeSwatches(primary: spec.primary, secondary: spec.secondary, tertiary: spec.tertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appColorSchemeLabel(spec.id), style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Dark + Lite variants',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchemeSwatches extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  const _SchemeSwatches({required this.primary, required this.secondary, required this.tertiary});

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c) => Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
          ),
        );

    return SizedBox(
      width: 52,
      height: 16,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(left: 0, child: dot(primary)),
          Positioned(left: 18, child: dot(secondary)),
          Positioned(left: 36, child: dot(tertiary)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
