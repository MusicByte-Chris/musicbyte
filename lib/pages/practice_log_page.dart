import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:musicbyteai/models/practice_log_model.dart';
import 'package:musicbyteai/services/practice_log_service.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/widgets/responsive_centered.dart';

class PracticeLogPage extends StatefulWidget {
  const PracticeLogPage({super.key});

  @override
  State<PracticeLogPage> createState() => _PracticeLogPageState();
}

class _PracticeLogPageState extends State<PracticeLogPage> {
  final _minutesCtrl = TextEditingController(text: '60');
  final _notesCtrl = TextEditingController();
  final _focusAreas = const ['Scales & Arpeggios', 'Ear Training', 'Sight Reading', 'Composition', 'Improvisation', 'Technique'];
  String _selectedFocus = 'Scales & Arpeggios';
  bool _loading = true;
  List<PracticeLogModel> _sessions = const [];
  Map<String, List<PracticeLogModel>> _groupedByDate = const {};
  Set<String> _datesWithSessions = const {};
  // Kept from previous month view but no longer used; week view uses current Monday.
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDate;
  int _weekTotalMinutes = 0;

  // Timer state
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await PracticeLogService.instance.getAllSessions();
      if (mounted) {
        setState(() {
          _sessions = List.of(list);
          _recomputeGroups();
        });
        debugPrint('PracticeLogPage: loaded ${_sessions.length} sessions; dates=${_groupedByDate.keys.length}');
      }
      await _computeWeeklySummary();
    } catch (e) {
      debugPrint('PracticeLogPage: load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _recomputeGroups() {
    final map = <String, List<PracticeLogModel>>{};
    for (final s in _sessions) {
      (map[s.sessionDate] ??= []).add(s);
    }
    // Sort each list desc by date insert order already sorted but ensure
    for (final entry in map.entries) {
      entry.value.sort((a, b) => b.date.compareTo(a.date));
    }
    _groupedByDate = map;
    _datesWithSessions = map.keys.toSet();
  }

  Future<void> _computeWeeklySummary() async {
    try {
      // Use this week's Monday as the start
      final today = DateTime.now();
      final d = DateTime(today.year, today.month, today.day);
      final diffToMon = d.weekday - DateTime.monday;
      final monday = d.subtract(Duration(days: diffToMon));
      final total = await PracticeLogService.instance.getTotalMinutesForWeek(monday);
      if (mounted) setState(() => _weekTotalMinutes = total);
      debugPrint('PracticeLogPage: weekly total minutes=$total starting ${_formatDate(monday)}');
    } catch (e) {
      debugPrint('PracticeLogPage: computeWeeklySummary failed: $e');
    }
  }

  int get _totalMinutes => _sessions.fold(0, (sum, s) => sum + s.minutes);

  int get _streakDays {
    final today = DateTime.now();
    final dateOnly = (DateTime d) => DateTime(d.year, d.month, d.day);
    final daysWithPractice = _sessions.map((s) => dateOnly(s.date)).toSet();
    int streak = 0;
    var cursor = dateOnly(today);
    while (daysWithPractice.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double get _avgPerDayWeek => _weekTotalMinutes / 7.0;

  Future<void> _saveSession() async {
    final minutes = int.tryParse(_minutesCtrl.text.trim());
    if (minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid minutes')));
      return;
    }
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
    await PracticeLogService.instance.addSession(focusArea: _selectedFocus, minutes: minutes, notes: notes);
    _minutesCtrl.text = '60';
    _notesCtrl.clear();
    await _load();
  }

  Future<void> _resetProgress() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: const Text('Reset Progress'),
        content: const Text('This will remove all practice sessions. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PracticeLogService.instance.resetAllProgress();
      setState(() {
        _selectedDate = null;
        _sessions = const [];
        _groupedByDate = const {};
        _datesWithSessions = const {};
        _weekTotalMinutes = 0;
        _loading = true;
      });
      await _load();
    }
  }

  @override
  void dispose() {
    try {
      _timer?.cancel();
    } catch (e) {
      debugPrint('PracticeLogPage: timer cancel in dispose failed: $e');
    }
    _minutesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = ResponsiveCentered.isWide(context);

    final header = Container(
      padding: const EdgeInsets.all(24),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Practice Log', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Text('Track your musical growth', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
            ],
          ),
          const SizedBox.shrink(),
        ],
      ),
    );

    final timerCard = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.06), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.timer_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('Live Session Running', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _formatElapsedMMSS(_elapsedSeconds),
                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary, letterSpacing: 1.5),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(_selectedFocus.isEmpty ? 'No focus selected' : _selectedFocus, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
            ),
          ],
        ),
      ),
    );

    final calendarSection = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('This Week', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            Text(_weekLabel(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
          ],
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          final today = DateTime.now();
          final d = DateTime(today.year, today.month, today.day);
          final monday = d.subtract(Duration(days: d.weekday - DateTime.monday));
          const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          return Row(children: [
            for (int i = 0; i < 7; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final day = DateTime(monday.year, monday.month, monday.day + i);
                    setState(() => _selectedDate = day);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _CalendarDay(
                      dayName: names[i],
                      dayNum: '${monday.add(Duration(days: i)).day}',
                      active: _selectedDate != null && _sameDate(monday.add(Duration(days: i)), _selectedDate!),
                      isToday: _sameDate(monday.add(Duration(days: i)), d),
                      hasData: _datesWithSessions.contains(_formatDate(monday.add(Duration(days: i)))),
                    ),
                  ),
                ),
              ),
          ]);
        }),
      ]),
    );

    final weeklySummary = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: _StatCard(label: 'Total Hours (Week)', value: _loading ? '—' : '${(_weekTotalMinutes / 60).toStringAsFixed(1)}h')),
          const SizedBox(width: 16),
          Expanded(child: _StatCard(label: 'Avg/Day (Week)', value: _loading ? '—' : '${_avgPerDayWeek.toStringAsFixed(0)}m')),
          const SizedBox(width: 16),
          Expanded(child: _StatCard(label: 'Current Streak', value: _loading ? '—' : '${_streakDays}d')),
        ]),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _resetProgress,
            icon: Icon(Icons.delete_sweep_rounded, color: theme.colorScheme.error),
            label: Text('Reset Progress', style: TextStyle(color: theme.colorScheme.error)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: theme.colorScheme.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
          ),
        ),
      ]),
    );

    final newSessionForm = Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: theme.dividerColor), boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.1), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('New Session', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Focus Area', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: theme.dividerColor)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFocus,
                    isExpanded: true,
                    items: _focusAreas.map((e) => DropdownMenuItem(value: e, child: Text(e, style: theme.textTheme.bodyMedium))).toList(),
                    onChanged: (v) => setState(() => _selectedFocus = v ?? _selectedFocus),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Minutes', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(hintText: '60', filled: true, fillColor: theme.scaffoldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: theme.dividerColor)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                keyboardType: TextInputType.number,
                controller: _minutesCtrl,
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notes', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(hintText: 'Focused on Eb Major modes...', filled: true, fillColor: theme.scaffoldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: theme.dividerColor))),
            maxLines: 3,
            controller: _notesCtrl,
          ),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading ? null : _saveSession,
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Save Session'),
        ),
      ]),
    );

    final sessionsList = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_selectedDate == null ? 'Sessions' : 'Sessions on ${_formatDate(_selectedDate!)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          if (_selectedDate != null) TextButton(onPressed: () => setState(() => _selectedDate = null), child: const Text('Clear')),
        ]),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (_sessions.isEmpty)
          Text('No sessions yet. Log your first session above.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary))
        else if (_selectedDate != null) ...[
          for (final s in (_groupedByDate[_formatDate(_selectedDate!)] ?? const <PracticeLogModel>[]))
            _SessionItem(icon: Icons.music_note_rounded, title: s.focusArea, subtitle: s.notes ?? _formatDate(s.date), duration: '${s.minutes}m', time: _relativeTime(s.date)),
          if ((_groupedByDate[_formatDate(_selectedDate!)] ?? const <PracticeLogModel>[]).isEmpty)
            Text('No sessions on this date.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
        ] else ...[
          for (final ymd in _groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a))) ...[
            Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: Text(ymd, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary))),
            for (final s in _groupedByDate[ymd]!)
              _SessionItem(icon: Icons.music_note_rounded, title: s.focusArea, subtitle: s.notes ?? _formatDate(s.date), duration: '${s.minutes}m', time: _relativeTime(s.date)),
          ],
        ],
      ]),
    );

    final weeklyChart = Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: theme.dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Weekly Activity', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 24),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 120,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                  const titles = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  if (value.toInt() < 0 || value.toInt() >= titles.length) return const SizedBox();
                  return Text(titles[value.toInt()], style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor));
                }, reservedSize: 20)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: _buildWeeklyBars(theme),
            ),
          ),
        ),
      ]),
    );

    final contentMobile = ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        header,
        if (_isTimerRunning) ...[
          const SizedBox(height: 8),
          timerCard,
        ],
        const SizedBox(height: 16),
        calendarSection,
        const SizedBox(height: 24),
        weeklySummary,
        const SizedBox(height: 24),
        newSessionForm,
        const SizedBox(height: 24),
        sessionsList,
        const SizedBox(height: 24),
        weeklyChart,
      ],
    );

    final contentWide = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (_isTimerRunning) ...[
            const SizedBox(height: 8),
            timerCard,
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    calendarSection,
                    const SizedBox(height: 24),
                    weeklySummary,
                    const SizedBox(height: 24),
                    newSessionForm,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    sessionsList,
                    const SizedBox(height: 24),
                    weeklyChart,
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ResponsiveCentered(
          maxWidth: isWide ? 1200 : 980,
          child: isWide ? contentWide : contentMobile,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading
            ? null
            : () {
                if (_isTimerRunning) {
                  _onStopTimerPressed();
                } else {
                  _onStartTimerPressed();
                }
              },
        icon: Icon(_isTimerRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
        label: Text(_isTimerRunning ? 'Stop Timer' : 'Start Timer'),
        backgroundColor: _isTimerRunning ? theme.colorScheme.error : theme.colorScheme.tertiary,
        foregroundColor: _isTimerRunning ? theme.colorScheme.onError : theme.colorScheme.surface,
      ),
    );
  }

  bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekLabel() {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    final monday = d.subtract(Duration(days: d.weekday - DateTime.monday));
    final sunday = monday.add(const Duration(days: 6));
    String m(int month) {
      const ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return ms[month - 1];
    }
    String fmt(DateTime x) => '${m(x.month)} ${x.day}';
    return '${fmt(monday)} – ${fmt(sunday)}';
  }

  List<BarChartGroupData> _buildWeeklyBars(ThemeData theme) {
    if (_loading) return List.generate(7, (i) => _makeBarGroup(i, 0, theme.colorScheme.tertiary));
    // Build per-day totals for current week (Mon..Sun)
    final today = DateTime.now();
    final dateOnly = (DateTime d) => DateTime(d.year, d.month, d.day);
    final monday = dateOnly(today).subtract(Duration(days: dateOnly(today).weekday - DateTime.monday));
    final totals = List<int>.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final ymd = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return _sessions.where((s) => s.sessionDate == ymd).fold(0, (sum, s) => sum + s.minutes);
    });
    final max = totals.isEmpty ? 60 : totals.reduce((a, b) => a > b ? a : b);
    final maxY = max.clamp(30, 120).toDouble();
    return [
      for (int i = 0; i < 7; i++) _makeBarGroup(i, totals[i].toDouble().clamp(0, maxY), theme.colorScheme.tertiary)
    ];
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) => BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: y,
            color: color,
            width: 16,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(show: true, toY: ((y <= 0 ? 60 : y * 1.2).clamp(30, 140)).toDouble(), color: color.withValues(alpha: 0.1)),
          ),
        ],
      );

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime m) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[m.month - 1]} ${m.year}';
  }

  // ===== Timer helpers & handlers =====
  String _formatElapsedMMSS(int totalSeconds) {
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _onStartTimerPressed() async {
    if (_isTimerRunning) {
      debugPrint('PracticeLogPage: start requested but timer already running');
      return;
    }
    final needsConfirm = _notesCtrl.text.trim().isEmpty || _selectedFocus.trim().isEmpty;
    if (needsConfirm) {
      final proceed = await _showIncompleteFieldsSheet();
      if (proceed != true) return;
    }
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      _elapsedSeconds = 0;
    });
    try {
      _timer?.cancel();
    } catch (_) {}
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _elapsedSeconds += 1);
    });
    debugPrint('PracticeLogPage: timer started');
  }

  Future<void> _onStopTimerPressed() async {
    if (!_isTimerRunning) return;
    final seconds = _elapsedSeconds;
    try {
      _timer?.cancel();
    } catch (e) {
      debugPrint('PracticeLogPage: stop cancel timer error: $e');
    }
    setState(() => _isTimerRunning = false);

    final save = await _showSaveOrDiscardSheet(seconds);
    if (save == true) {
      final minutes = seconds <= 0 ? 1 : ((seconds / 60).round().clamp(1, 100000));
      final notesRaw = _notesCtrl.text;
      final notes = notesRaw.trim().isEmpty ? null : notesRaw.trim();
      debugPrint('PracticeLogPage: saving timed session: $_selectedFocus, ${minutes}m');
      await PracticeLogService.instance.addSession(focusArea: _selectedFocus, minutes: minutes, notes: notes);
      await _load();
    } else {
      debugPrint('PracticeLogPage: timed session discarded');
    }
    setState(() => _elapsedSeconds = 0);
  }

  Future<bool?> _showIncompleteFieldsSheet() async {
    final theme = Theme.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Complete Details?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                ],
              ),
              const SizedBox(height: 12),
              Text('We recommend filling Focus Area and Notes before starting the timer. You can still continue without them.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                      child: const Text('Go Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                      child: const Text('Continue Anyway'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _showSaveOrDiscardSheet(int seconds) async {
    final theme = Theme.of(context);
    final durationText = _formatElapsedMMSS(seconds);
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.timer_off_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Finish Session?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            ]),
            const SizedBox(height: 12),
            Text('Elapsed: $durationText', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Would you like to save this session to your log?', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error, side: BorderSide(color: theme.colorScheme.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                  child: const Text('Save Session'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selected;
  final Set<String> hasData; // yyyy-MM-dd
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({required this.month, required this.selected, required this.hasData, required this.onSelect});

  String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    // Compute Monday-start grid
    final weekday = firstOfMonth.weekday; // Mon=1..Sun=7
    final diffToMon = weekday - DateTime.monday; // 0..6
    final gridStart = firstOfMonth.subtract(Duration(days: diffToMon));
    // 6 weeks * 7 days = 42 cells to cover all months
    final days = List<DateTime>.generate(42, (i) => DateTime(gridStart.year, gridStart.month, gridStart.day + i));

    return Column(
      children: [
        for (int r = 0; r < 6; r++)
          Row(
            children: [
              for (int c = 0; c < 7; c++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _MonthDay(
                      date: days[r * 7 + c],
                      inMonth: days[r * 7 + c].month == month.month,
                      active: selected != null && _sameDate(days[r * 7 + c], selected!),
                      hasData: hasData.contains(_ymd(days[r * 7 + c])),
                      onTap: () => onSelect(DateTime(days[r * 7 + c].year, days[r * 7 + c].month, days[r * 7 + c].day)),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MonthDay extends StatelessWidget {
  final DateTime date;
  final bool inMonth;
  final bool active;
  final bool hasData;
  final VoidCallback onTap;

  const _MonthDay({required this.date, required this.inMonth, required this.active, required this.hasData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fgMuted = theme.colorScheme.secondary;
    final dayText = '${date.day}';
    final bg = active ? theme.colorScheme.tertiary : Colors.transparent;
    final borderColor = hasData ? theme.colorScheme.tertiary : Colors.transparent;
    final textColor = active
        ? theme.colorScheme.surface
        : inMonth
            ? theme.colorScheme.onSurface
            : fgMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: borderColor)),
        child: Center(
          child: Text(dayText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final String dayName;
  final String dayNum;
  final bool active;
  final bool isToday;
  final bool hasData;

  const _CalendarDay({
    required this.dayName,
    required this.dayNum,
    required this.active,
    required this.isToday,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.tertiary
            : (isToday ? theme.colorScheme.tertiary.withValues(alpha: 0.12) : Colors.transparent),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: hasData ? theme.colorScheme.tertiary : Colors.transparent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: active ? theme.colorScheme.surface : theme.colorScheme.secondary,
            ),
          ),
          Text(
            dayNum,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: active ? theme.colorScheme.surface : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String duration;
  final String time;

  const _SessionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: theme.colorScheme.tertiary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                duration,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
