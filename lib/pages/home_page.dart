import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/data/theory_repository.dart';
import 'package:musicbyteai/models/key_context.dart';
import 'package:musicbyteai/services/key_context_service.dart';
import 'package:musicbyteai/widgets/key_picker_sheet.dart';
import 'package:musicbyteai/services/practice_log_service.dart';
import 'package:musicbyteai/models/practice_log_model.dart';
import 'package:musicbyteai/widgets/responsive_centered.dart';
import '../theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  KeyContext? _ctx;
  // Practice data state
  List<double> _weeklyTotals = List<double>.filled(7, 0);
  int _totalMinutesAll = 0;
  int _streak = 0;
  int _sessionsCount = 0;
  List<PracticeLogModel> _recent = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadContext();
    _loadPracticeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPracticeData();
    }
  }

  Future<void> _loadContext() async {
    try {
      final c = await KeyContextService.instance.load();
      if (mounted) setState(() => _ctx = c);
    } catch (e) {
      debugPrint('HomePage: failed to load key context: $e');
      if (mounted) setState(() => _ctx = KeyContext.defaults());
    }
  }

  Future<void> _loadPracticeData() async {
    try {
      final svc = PracticeLogService.instance;
      final all = await svc.getAllSessions();
      final streak = await svc.getCurrentStreak();

      // Summary values
      final total = all.fold<int>(0, (sum, e) => sum + e.minutes);
      final count = all.length;

      // Compute current week's Monday..Sunday totals (Mon=0..Sun=6)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diffToMon = today.weekday - DateTime.monday; // 0..6
      final monday = today.subtract(Duration(days: diffToMon));
      final sunday = monday.add(const Duration(days: 6));
      final totals = List<double>.filled(7, 0);
      for (final e in all) {
        final d = e.date;
        if (!d.isBefore(monday) && !d.isAfter(sunday)) {
          final idx = d.weekday - 1; // 0..6
          if (idx >= 0 && idx < 7) totals[idx] += e.minutes.toDouble();
        }
      }

      // Recent 3 by date desc (cache already desc, but ensure)
      final recent = [...all]..sort((a, b) => b.date.compareTo(a.date));
      final top3 = recent.take(3).toList();

      if (!mounted) return;
      setState(() {
        _totalMinutesAll = total;
        _sessionsCount = count;
        _streak = streak;
        _weeklyTotals = totals;
        _recent = top3;
      });
    } catch (e) {
      debugPrint('HomePage: failed to load practice data: $e');
      if (!mounted) return;
      setState(() {
        _weeklyTotals = List<double>.filled(7, 0);
        _totalMinutesAll = 0;
        _streak = 0;
        _sessionsCount = 0;
        _recent = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = ResponsiveCentered.isWide(context);
    final selectedId = _ctx?.selectedKeyId ?? 'c_major';
    final keyData = TheoryRepository.getKeyById(selectedId);

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "MusicByte",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Professional Reference & Utility",
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(
              Icons.settings_rounded,
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
      ],
    );

    final activeKeyContextCard = Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Active Key Context",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openKeyPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(children: [
                    Icon(Icons.music_note_rounded, size: 14, color: theme.colorScheme.onPrimary),
                    const SizedBox(width: 6),
                    Text(
                      keyData.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: theme.colorScheme.onPrimary),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Relative Minor",
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      keyData.relativeMinor,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Signatures",
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      keyData.signatureDesc,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/circle'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.explore_rounded),
            label: const Text("Open Circle of Fifths"),
          ),
        ],
      ),
    );

    final coreUtilitiesHeader = Text(
      "Core Utilities",
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );

    final coreUtilitiesCards = [
      const _ToolCard(icon: Icons.timer, title: "Metronome", desc: "Precision timing & polyrhythms", route: '/tools'),
      const _ToolCard(icon: Icons.mic_none_rounded, title: "Tuner", desc: "High-accuracy pitch detection", route: '/tools'),
      const _ToolCard(icon: Icons.waves, title: "Tone Gen", desc: "Pure sine & frequency reference", route: '/tools'),
      const _ToolCard(icon: Icons.straighten, title: "EQ Cheat", desc: "Engineer frequency ranges", route: '/reference'),
      const _ToolCard(icon: Icons.hearing_rounded, title: "Ear Trainer", desc: "Intervals & chord recognition", route: '/ear-trainer'),
      const _ToolCard(icon: Icons.flash_on_rounded, title: "Note Assault", desc: "Fast sight-reading game", route: '/note-assault'),
      const _ToolCard(icon: Icons.menu_book_rounded, title: "Music Theory", desc: "Scales, key signatures, symbols", route: '/theory-reference'),
    ];

    final practiceSummaryCard = Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Practice Summary",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                "This Week",
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 70,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = ["M", "T", "W", "T", "F", "S", "S"];
                        if (value.toInt() < 0 || value.toInt() >= titles.length) return const SizedBox();
                        return Text(
                          titles[value.toInt()],
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) => _makeBarGroup(i, _weeklyTotals[i], theme.colorScheme.primary)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(value: '${(_totalMinutesAll / 60).toStringAsFixed(1)}h', label: 'Total Hours'),
              _StatItem(value: _streak.toString(), label: 'Current Streak'),
              _StatItem(value: _sessionsCount.toString(), label: 'Sessions'),
            ],
          ),
        ],
      ),
    );

    final recentLogSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Log",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () async {
                await context.push('/log');
                if (mounted) _loadPracticeData();
              },
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              'Start your first practice session.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
          )
        else
          Column(
            children: _recent.map((e) {
              final dateStr = MaterialLocalizations.of(context).formatShortDate(e.date);
              return _SessionRow(
                icon: Icons.music_note_rounded,
                title: e.focusArea,
                subtitle: e.notes ?? '',
                time: '${e.minutes}m',
                date: dateStr,
              );
            }).toList(),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ResponsiveCentered(
          maxWidth: isWide ? 1200 : 980,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              if (!isWide) ...[
                header,
                const SizedBox(height: 32),
                activeKeyContextCard,
                const SizedBox(height: 24),
                coreUtilitiesHeader,
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: coreUtilitiesCards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: coreUtilitiesCards[1]),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: coreUtilitiesCards[2]),
                  const SizedBox(width: 16),
                  Expanded(child: coreUtilitiesCards[3]),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: coreUtilitiesCards[4]),
                  const SizedBox(width: 16),
                  Expanded(child: coreUtilitiesCards[5]),
                ]),
                const SizedBox(height: 16),
                coreUtilitiesCards[6],
                const SizedBox(height: 24),
                practiceSummaryCard,
                const SizedBox(height: 24),
                recentLogSection,
                const SizedBox(height: 80),
              ] else ...[
                header,
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          activeKeyContextCard,
                          const SizedBox(height: 20),
                          coreUtilitiesHeader,
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 12.0;
                              final tileW = ((constraints.maxWidth - spacing) / 2).clamp(260.0, 520.0);
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  for (final card in coreUtilitiesCards)
                                    SizedBox(width: tileW, child: card),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          practiceSummaryCard,
                          const SizedBox(height: 20),
                          recentLogSection,
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
          ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/circle'),
        icon: const Icon(Icons.grid_view_rounded),
        label: const Text("Key Selector"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 12,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 70,
            color: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Future<void> _openKeyPicker() async {
    try {
      final theme = Theme.of(context);
      await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
        builder: (ctx) => KeyPickerSheet(
          selectedId: _ctx?.selectedKeyId ?? 'c_major',
          onSelect: (id) async {
            Navigator.of(ctx).pop();
            await KeyContextService.instance.setSelectedKey(id);
            if (!mounted) return;
            final next = await KeyContextService.instance.load();
            setState(() => _ctx = next);
          },
        ),
      );
    } catch (e) {
      debugPrint('HomePage: open key picker failed: $e');
    }
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String? route;

  const _ToolCard({required this.icon, required this.title, required this.desc, this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.go(route ?? '/tools'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(desc, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
        ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final String date;

  const _SessionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.tertiary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                date,
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
