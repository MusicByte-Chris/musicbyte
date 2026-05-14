import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/models/music_theory.dart';
import 'package:musicbyteai/data/theory_repository.dart';
import 'package:musicbyteai/nav.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/widgets/piano_keyboard.dart';
import 'package:musicbyteai/widgets/key_picker_sheet.dart';
import 'package:musicbyteai/services/audio_engine_service.dart';
import 'package:musicbyteai/widgets/standard_guitar_chord_diagram.dart';
import 'package:musicbyteai/widgets/guitar_fretboard.dart';
import 'package:musicbyteai/models/chord_builder.dart';
import 'package:musicbyteai/widgets/chord_properties_panel.dart';
import 'package:musicbyteai/data/guitar_voicing_library.dart';

class ChordScaleViewerPage extends StatefulWidget {
  final String keyId; // e.g., 'c_major'
  final bool startWithScale; // if true, open with Scale tab

  const ChordScaleViewerPage({super.key, required this.keyId, this.startWithScale = false});

  @override
  State<ChordScaleViewerPage> createState() => _ChordScaleViewerPageState();
}

class _ChordScaleViewerPageState extends State<ChordScaleViewerPage> {
  late bool showScale;
  bool showLabels = true;
  // 0 = guitar, 1 = piano, 2 = both
  int layoutMode = 2;

  // Scale view uses a single-instrument layout to maximize usable space.
  // 0 = guitar, 1 = piano
  int scaleInstrument = 0;

  late List<Chord> diatonicChords;
  int selectedChordIndex = 0;
  ViewerChordSpec chordSpec = const ViewerChordSpec();

  final List<String> scaleIds = TheoryUtils.scaleNames.keys.toList();
  int selectedScaleIndex = 0; // 0 -> ionian by default

  @override
  void initState() {
    super.initState();
    showScale = widget.startWithScale;
    diatonicChords = TheoryRepository.getDiatonicChords(widget.keyId);

    // If we navigated here from a minor key shortcut, default the Scale tab to Minor.
    // (The chord side still assumes major harmony; this just optimizes the scale workflow.)
    try {
      final keyData = TheoryRepository.getKeyById(widget.keyId);
      final isMinorKey = keyData.name.toLowerCase().contains('minor') || keyData.mode.toLowerCase().contains('aeolian');
      if (showScale && isMinorKey) {
        final idx = scaleIds.indexOf('minor');
        if (idx >= 0) selectedScaleIndex = idx;
      }
    } catch (_) {
      // no-op
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyData = TheoryRepository.getKeyById(widget.keyId);
    final tonicPc = TheoryUtils.pcForKeyId(widget.keyId);

    final pcs = _currentPcSet(tonicPc);
    final rootPc = _currentRootPc(tonicPc);
    // Build voicing order only for Chord mode; Scale mode ignores inversion.
    final List<int>? voicingOrder = !showScale ? _voicingPcsForInversion(_currentChordPcs(tonicPc)) : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.tools);
            }
          },
        ),
        title: Text('Viewer • ${keyData.name}', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: Icon(showLabels ? Icons.visibility_rounded : Icons.visibility_off_rounded),
            tooltip: 'Interval Labels On/Off',
            onPressed: () => setState(() => showLabels = !showLabels),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final effectiveLayoutMode = isWide ? 2 : layoutMode;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _ControlsBar(
                  showScale: showScale,
                  onModeChanged: (v) => setState((){
                    if (v) chordSpec = chordSpec.copyWith(inversion: 0); // reset when switching to Scale
                    showScale = v;
                  }),
                  chords: diatonicChords,
                  selectedChordIndex: selectedChordIndex,
                  onSelectChord: (i) => setState((){
                    selectedChordIndex = i;
                    chordSpec = chordSpec.copyWith(inversion: 0); // reset on chord change
                  }),
                  scaleIds: scaleIds,
                  selectedScaleIndex: selectedScaleIndex,
                  onSelectScale: (i) => setState(()=> selectedScaleIndex = i),
                  keyName: keyData.name,
                  onTapKeyChip: _openKeyPicker,
                ),
                if (showScale) ...[
                  const SizedBox(height: 12),
                  _ScaleInstrumentToggle(
                    value: scaleInstrument,
                    onChanged: (v) => setState(() => scaleInstrument = v),
                  ),
                ] else if (!isWide) ...[
                  const SizedBox(height: 12),
                  _ViewerLayoutToggle(
                    value: effectiveLayoutMode,
                    onChanged: (v) => setState(() => layoutMode = v),
                  ),
                ],
                if (!showScale) ...[
                  const SizedBox(height: 8),
                  ChordPropertiesPanel(
                    headerTitle: _currentChordHeaderTitle(tonicPc),
                    subtitle: _currentChordSubtitle(tonicPc),
                    spec: _clampedChordSpecFor(tonicPc),
                    onChanged: (next) => setState(() => chordSpec = _clampChordSpec(next, tonicPc)),
                    onReset: () => setState(() => chordSpec = const ViewerChordSpec()),
                    collapsible: !isWide,
                    initiallyExpanded: true,
                    dense: isWide,
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (!showScale)
                        FilledButton.icon(
                          onPressed: _playSelectedChord,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play Chord'),
                        )
                      else ...[
                        FilledButton.icon(
                          onPressed: _playScaleUpDown,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play Scale'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!showScale)
                        Expanded(
                          child: _ChordDiagramPanel(
                            keyId: widget.keyId,
                            chords: diatonicChords,
                            selectedIndex: selectedChordIndex,
                            chordSpec: chordSpec,
                            onSelectChord: (i) => setState(() {
                              selectedChordIndex = i;
                            }),
                            onOpenChord: (i) => _openChordZoomSheet(i),
                            onPlayChordAtIndex: _playChordAtIndex,
                          ),
                        )
                      else
                        Expanded(
                          child: scaleInstrument == 0
                              ? _GuitarScalePositionsPanel(pcs: pcs, rootPc: rootPc, showLabels: showLabels)
                              : _PianoPanel(pcs: pcs, rootPc: rootPc, showLabels: showLabels, voicingOrder: voicingOrder),
                        ),
                    ],
                  )
                else ...[
                  if (!showScale && (effectiveLayoutMode == 0 || effectiveLayoutMode == 2))
                    _ChordDiagramPanel(
                      keyId: widget.keyId,
                      chords: diatonicChords,
                      selectedIndex: selectedChordIndex,
                      chordSpec: chordSpec,
                      onSelectChord: (i) => setState(() => selectedChordIndex = i),
                      onOpenChord: (i) => _openChordZoomSheet(i),
                      onPlayChordAtIndex: _playChordAtIndex,
                    ),
                  if (!showScale && (effectiveLayoutMode == 0 || effectiveLayoutMode == 2)) const SizedBox(height: AppSpacing.lg),
                  if (showScale) ...[
                    if (scaleInstrument == 0)
                      _GuitarScalePositionsPanel(pcs: pcs, rootPc: rootPc, showLabels: showLabels)
                    else
                      _PianoPanel(pcs: pcs, rootPc: rootPc, showLabels: showLabels, voicingOrder: voicingOrder, forceFixedHeight: true),
                  ] else ...[
                    if (effectiveLayoutMode == 1 || effectiveLayoutMode == 2)
                      _PianoPanel(
                        pcs: pcs,
                        rootPc: rootPc,
                        showLabels: showLabels,
                        voicingOrder: voicingOrder,
                        forceFixedHeight: true,
                      ),
                  ],
                ],
                const SizedBox(height: 24),
                _LegendRow(),
              ],
            ),
          );
        },
      ),
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
              selectedId: widget.keyId,
              onSelect: (id) {
                Navigator.of(ctx).pop();
                final tab = showScale ? 'scale' : 'chord';
                context.go('${AppRoutes.viewer}?key=$id&tab=$tab');
              },
            ),
      );
    } catch (e) {
      debugPrint('Failed to open key picker: $e');
    }
  }

  Set<int> _currentPcSet(int tonicPc) {
    if (showScale) {
      final id = scaleIds[selectedScaleIndex];
      return TheoryUtils.scaleById(id, tonicPc).toSet();
    } else {
      return _currentChordPcs(tonicPc).toSet();
    }
  }

  int _currentRootPc(int tonicPc) {
    if (showScale) {
      return tonicPc;
    } else {
      final base = _selectedDiatonicRootPc(tonicPc);
      return chordSpec.options.contains(ChordOption.tritoneSub) ? (base + 6) % 12 : base;
    }
  }

  // ---- Playback helpers ----
  Future<void> _playSelectedChord() async {
    await _playChordAtIndex(selectedChordIndex);
  }

  Future<void> _playChordAtIndex(int chordIndex) async {
    try {
      final tonicPc = TheoryUtils.pcForKeyId(widget.keyId);
      final pcs = _chordPcsForIndex(tonicPc, chordIndex);
      final useFlats = TheoryRepository.getKeyById(widget.keyId).sharps < 0;
      final spec = _clampChordSpec(chordSpec, tonicPc, chordIndex: chordIndex);
      final notes = _chordNotesWithInversionFor(pcs, inversion: spec.inversion, useFlats: useFlats);
      final engine = AudioEngineService();
      await engine.playChord(notes, arpeggiate: false);
      final err = engine.consumeLastError();
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
      }
    } catch (e) {
      debugPrint('Viewer: play chord error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
      }
    }
  }

  // Compute ordered chord pitch classes for the currently selected chord
  // honoring the Viewer chordType toggle.
  List<int> _currentChordPcs(int tonicPc) => _chordPcsForIndex(tonicPc, selectedChordIndex);

  List<int> _chordPcsForIndex(int tonicPc, int chordIndex) {
    final chord = diatonicChords[(chordIndex).clamp(0, diatonicChords.length - 1)];
    final chordRoot = _diatonicRootPcForIndex(tonicPc, chordIndex);
    final spec = _clampChordSpec(chordSpec, tonicPc, chordIndex: chordIndex);
    return ChordBuilder.buildChordPcsRootOrder(rootPc: chordRoot, diatonicQuality: chord.type, spec: spec);
  }

  // Creates a chord voicing order for the current inversion without altering pitch classes.
  // Example for triads: [root, 3rd, 5th] ->
  //   inv 0: [root, 3rd, 5th]
  //   inv 1: [3rd, 5th, root]
  //   inv 2: [5th, root, 3rd]
  List<int> _voicingPcsForInversion(List<int> pcs) {
    if (pcs.isEmpty) return pcs;
    final inv = chordSpec.inversion.clamp(0, pcs.length - 1);
    if (inv == 0) return List<int>.from(pcs);
    final left = pcs.sublist(inv);
    final right = pcs.sublist(0, inv);
    return [...left, ...right];
  }

  // Convert pcs to NoteModels and apply inversion.
  // For inversion i, the first i chord tones are raised an octave.
  List<NoteModel> _chordNotesWithInversionFor(List<int> pcs, {required int inversion, required bool useFlats}) {
    // Base octave = 4
    final base = pcs.map((pc) => NoteModel(noteName: TheoryUtils.nameForPc(pc, useFlats: useFlats), octave: 4)).toList(growable: true);
    final inv = inversion.clamp(0, pcs.length - 1);
    if (inv == 0) return base;
    final mutable = List<NoteModel>.from(base);
    for (int i = 0; i < inv && i < mutable.length; i++) {
      final n = mutable[i];
      mutable[i] = NoteModel(noteName: n.noteName, octave: n.octave + 1);
    }
    return [...mutable.sublist(inv), ...mutable.sublist(0, inv)];
  }

  Future<void> _openChordZoomSheet(int chordIndex) async {
    try {
      final theme = Theme.of(context);

      // Keep local state in sync with the viewer's global state, but allow
      // experimentation per-chord inside the sheet.
      var localSpec = chordSpec;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              final chord = diatonicChords[(chordIndex).clamp(0, diatonicChords.length - 1)];
              final tonicPc = TheoryUtils.pcForKeyId(widget.keyId);
              final chordRootPc = _diatonicRootPcForIndex(tonicPc, chordIndex);
              final clamped = _clampChordSpec(localSpec, tonicPc, chordIndex: chordIndex);
              final pcs = ChordBuilder.buildChordPcsRootOrder(rootPc: chordRootPc, diatonicQuality: chord.type, spec: clamped);
              final voicing = GuitarVoicingLibrary.voicingFor(chordPcsRootOrder: pcs, inversion: clamped.inversion);

              final symbol = _prettyChordSymbolForIndex(tonicPc, chordIndex: chordIndex, spec: clamped);
              final subtitle = _currentChordSubtitle(tonicPc, chordIndex: chordIndex, overrideSpec: clamped);

              Future<void> playLocal() async {
                try {
                  final useFlats = TheoryRepository.getKeyById(widget.keyId).sharps < 0;
                  final notes = _chordNotesWithInversionFor(pcs, inversion: clamped.inversion, useFlats: useFlats);
                  final engine = AudioEngineService();
                  await engine.playChord(notes, arpeggiate: false);
                  final err = engine.consumeLastError();
                  if (err != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
                  }
                } catch (e) {
                  debugPrint('Viewer zoom sheet: play chord error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio playback failed.')));
                  }
                }
              }

              // On smaller mobile screens this sheet can overflow vertically.
              // Make it scrollable and size the diagram to available height.
              return SafeArea(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
                    // Estimate remaining height for the diagram after text + selectors.
                    final availableForDiagram = (constraints.maxHeight - 260).clamp(220, 420).toDouble();

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 18 + bottomInset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.zoom_out_map_rounded, size: 18, color: theme.colorScheme.tertiary),
                              const SizedBox(width: 10),
                              Expanded(child: Text(symbol, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface), overflow: TextOverflow.ellipsis)),
                              IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close_rounded)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
                          const SizedBox(height: 14),
                          ChordPropertiesPanel(
                            headerTitle: symbol,
                            subtitle: subtitle,
                            spec: clamped,
                            onChanged: (next) => setSheetState(() => localSpec = _clampChordSpec(next, tonicPc, chordIndex: chordIndex)),
                            onReset: () => setSheetState(() => localSpec = const ViewerChordSpec()),
                            collapsible: false,
                            dense: false,
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: SizedBox(
                                height: availableForDiagram,
                                child: StandardGuitarChordDiagram(
                                  chordLabel: symbol,
                                  voicing: voicing,
                                  showPlayButton: true,
                                  onTap: playLocal,
                                  onPlay: playLocal,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: playLocal,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Play'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Failed to open chord zoom sheet: $e');
    }
  }

  int _selectedDiatonicRootPc(int tonicPc) => _diatonicRootPcForIndex(tonicPc, selectedChordIndex);

  int _diatonicRootPcForIndex(int tonicPc, int chordIndex) {
    final chord = diatonicChords[(chordIndex).clamp(0, diatonicChords.length - 1)];
    final degree = TheoryUtils.romanToDegree(chord.roman);
    final scale = TheoryUtils.majorScalePcs(tonicPc);
    return scale[degree % 7];
  }

  ViewerChordSpec _clampedChordSpecFor(int tonicPc) => _clampChordSpec(chordSpec, tonicPc);

  ViewerChordSpec _clampChordSpec(ViewerChordSpec spec, int tonicPc, {int? chordIndex}) {
    final idx = chordIndex ?? selectedChordIndex;
    final chord = diatonicChords[(idx).clamp(0, diatonicChords.length - 1)];
    final rootPc = _diatonicRootPcForIndex(tonicPc, idx);
    final pcs = ChordBuilder.buildChordPcsRootOrder(rootPc: rootPc, diatonicQuality: chord.type, spec: spec);
    final maxInv = (pcs.length - 1).clamp(0, 6);
    return spec.copyWith(inversion: spec.inversion.clamp(0, maxInv));
  }

  String _prettyChordSymbolForIndex(int tonicPc, {required int chordIndex, required ViewerChordSpec spec}) {
    final useFlats = TheoryRepository.getKeyById(widget.keyId).sharps < 0;
    final baseRoot = _diatonicRootPcForIndex(tonicPc, chordIndex);
    final rootPc = spec.options.contains(ChordOption.tritoneSub) ? (baseRoot + 6) % 12 : baseRoot;
    final chord = diatonicChords[(chordIndex).clamp(0, diatonicChords.length - 1)];

    final rootName = TheoryUtils.nameForPc(rootPc, useFlats: useFlats);
    final quality = chord.type.toLowerCase();
    final qSuffix = switch (quality) {
      'minor' => 'm',
      'dim' => 'dim',
      'aug' => 'aug',
      _ => '',
    };

    final sizeSuffix = switch (spec.size) {
      ChordSize.triad => '',
      ChordSize.seventh => _seventhSuffixStatic(spec.seventh, chord.type),
      ChordSize.ninth => '9',
      ChordSize.eleventh => '11',
      ChordSize.thirteenth => '13',
    };

    // If inverted, show slash bass (simple enharmonic naming for now).
    final pcsRootOrder = ChordBuilder.buildChordPcsRootOrder(rootPc: baseRoot, diatonicQuality: chord.type, spec: spec);
    final pcsInv = ChordBuilder.applyInversion(pcsRootOrder, spec.inversion);
    final bassName = pcsInv.isNotEmpty ? TheoryUtils.nameForPc(pcsInv.first, useFlats: useFlats) : '';

    final base = '$rootName$qSuffix$sizeSuffix';
    if (spec.inversion == 0 || bassName.isEmpty) return base;
    return '$base/$bassName';
  }

  String _currentChordHeaderTitle(int tonicPc) => _prettyChordSymbolForIndex(tonicPc, chordIndex: selectedChordIndex, spec: _clampedChordSpecFor(tonicPc));

  String _currentChordSubtitle(int tonicPc, {int? chordIndex, ViewerChordSpec? overrideSpec}) {
    final idx = chordIndex ?? selectedChordIndex;
    final spec = overrideSpec ?? _clampedChordSpecFor(tonicPc);
    final chord = diatonicChords[(idx).clamp(0, diatonicChords.length - 1)];
    final rootPc = _diatonicRootPcForIndex(tonicPc, idx);
    final pcs = ChordBuilder.buildChordPcsRootOrder(rootPc: rootPc, diatonicQuality: chord.type, spec: spec);
    final useFlats = TheoryRepository.getKeyById(widget.keyId).sharps < 0;
    final names = pcs.map((pc) => TheoryUtils.nameForPc(pc, useFlats: useFlats)).toList();
    return names.join('  •  ');
  }

  Future<void> _playScaleUpDown() async {
    try {
      final keyId = widget.keyId;
      final tonicPc = TheoryUtils.pcForKeyId(keyId);
      final id = scaleIds[(selectedScaleIndex).clamp(0, scaleIds.length - 1)];
      final pcs = TheoryUtils.scaleById(id, tonicPc);
      final useFlats = TheoryRepository.getKeyById(keyId).sharps < 0;
      final notes = pcs.map((pc)=> NoteModel(noteName: TheoryUtils.nameForPc(pc, useFlats: useFlats), octave: 4)).toList();
      final engine = AudioEngineService();
      await engine.playScale(notes, ascending: true);
      await engine.playScale(notes, ascending: false);
    } catch (e) {
      debugPrint('Viewer: play scale error: $e');
    }
  }
}

class _ViewerLayoutToggle extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _ViewerLayoutToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LayoutModeChip(
              label: 'Guitar',
              icon: Icons.gesture_rounded,
              selected: value == 0,
              onTap: () => onChanged(0),
            ),
            _LayoutModeChip(
              label: 'Piano',
              icon: Icons.piano_rounded,
              selected: value == 1,
              onTap: () => onChanged(1),
            ),
            _LayoutModeChip(
              label: 'Both',
              icon: Icons.dashboard_customize_rounded,
              selected: value == 2,
              onTap: () => onChanged(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleInstrumentToggle extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _ScaleInstrumentToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LayoutModeChip(
              label: 'Guitar',
              icon: Icons.gesture_rounded,
              selected: value == 0,
              onTap: () => onChanged(0),
            ),
            _LayoutModeChip(
              label: 'Piano',
              icon: Icons.piano_rounded,
              selected: value == 1,
              onTap: () => onChanged(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _LayoutModeChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.tertiary : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChordDiagramPanel extends StatelessWidget {
  final String keyId;
  final List<Chord> chords;
  final int selectedIndex;
  final ValueChanged<int> onSelectChord;
  final ValueChanged<int> onOpenChord;
  final ViewerChordSpec chordSpec;
  final Future<void> Function(int chordIndex) onPlayChordAtIndex;

  const _ChordDiagramPanel({required this.keyId, required this.chords, required this.selectedIndex, required this.onSelectChord, required this.onOpenChord, required this.chordSpec, required this.onPlayChordAtIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gesture_rounded, color: theme.colorScheme.tertiary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Guitar Chords',
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final crossAxisCount = w >= 860 ? 4 : (w >= 560 ? 3 : 2);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                   // Slightly taller tiles to accommodate title + play pill + chart.
                   // The chart itself is also FittedBox-scaled, so this is a safety
                   // net for very small devices.
                   childAspectRatio: 0.78,
                ),
                itemCount: chords.length,
                itemBuilder: (context, i) {
                  final chord = chords[i];
                  final isSelected = i == selectedIndex;

                  final degree = TheoryUtils.romanToDegree(chord.roman);

                  // Build pcs for voicing search
                  final tonicPc = TheoryUtils.pcForKeyId(keyId);
                  final scale = TheoryUtils.majorScalePcs(tonicPc);
                  final chordRootPc = scale[degree % 7];

                  final spec = _clampSpecToChord(chordSpec, rootPc: chordRootPc, quality: chord.type);
                  final pcs = ChordBuilder.buildChordPcsRootOrder(rootPc: chordRootPc, diatonicQuality: chord.type, spec: spec);
                  final voicing = GuitarVoicingLibrary.voicingFor(chordPcsRootOrder: pcs, inversion: spec.inversion);
                  final useFlats = TheoryRepository.getKeyById(keyId).sharps < 0;
                  final symbol = _symbolForChord(keyId: keyId, chord: chord, rootPc: chordRootPc, spec: spec, useFlats: useFlats);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.tertiary.withValues(alpha: theme.brightness == Brightness.dark ? 0.22 : 0.16),
                                blurRadius: 18,
                                spreadRadius: 1,
                                offset: const Offset(0, 10),
                              )
                            ]
                          : const [],
                    ),
                    child: StandardGuitarChordDiagram(
                      chordLabel: symbol,
                      voicing: voicing,
                      showPlayButton: true,
                      onTap: () async {
                        onSelectChord(i);
                        onOpenChord(i);
                      },
                      onPlay: () async {
                        onSelectChord(i);
                        await onPlayChordAtIndex(i);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

ViewerChordSpec _clampSpecToChord(ViewerChordSpec spec, {required int rootPc, required String quality}) {
  final pcs = ChordBuilder.buildChordPcsRootOrder(rootPc: rootPc, diatonicQuality: quality, spec: spec);
  final maxInv = (pcs.length - 1).clamp(0, 6);
  return spec.copyWith(inversion: spec.inversion.clamp(0, maxInv));
}

String _symbolForChord({
  required String keyId,
  required Chord chord,
  required int rootPc,
  required ViewerChordSpec spec,
  required bool useFlats,
}) {
  final effectiveRoot = spec.options.contains(ChordOption.tritoneSub) ? (rootPc + 6) % 12 : rootPc;
  final rootName = TheoryUtils.nameForPc(effectiveRoot, useFlats: useFlats);

  final quality = chord.type.toLowerCase();
  final qSuffix = switch (quality) {
    'minor' => 'm',
    'dim' => 'dim',
    'aug' => 'aug',
    _ => '',
  };

  final sizeSuffix = switch (spec.size) {
    ChordSize.triad => '',
    ChordSize.seventh => _seventhSuffixStatic(spec.seventh, chord.type),
    ChordSize.ninth => '9',
    ChordSize.eleventh => '11',
    ChordSize.thirteenth => '13',
  };

  final pcsRootOrder = ChordBuilder.buildChordPcsRootOrder(rootPc: rootPc, diatonicQuality: chord.type, spec: spec);
  final pcsInv = ChordBuilder.applyInversion(pcsRootOrder, spec.inversion);
  final bassPc = pcsInv.isNotEmpty ? pcsInv.first : effectiveRoot;
  final bassName = TheoryUtils.nameForPc(bassPc, useFlats: useFlats);

  final base = '$rootName$qSuffix$sizeSuffix';
  if (spec.inversion == 0) return base;
  return '$base/$bassName';
}

String _seventhSuffixStatic(SeventhFlavor flavor, String diatonicQuality) {
  switch (flavor) {
    case SeventhFlavor.maj7:
      return 'maj7';
    case SeventhFlavor.dom7:
      return '7';
    case SeventhFlavor.min7:
      return 'm7';
    case SeventhFlavor.auto:
      return (diatonicQuality.toLowerCase() == 'major' || diatonicQuality.toLowerCase() == 'aug') ? 'maj7' : '7';
  }
}

class _GuitarScalePositionsPanel extends StatelessWidget {
  final Set<int> pcs;
  final int rootPc;
  final bool showLabels;

  const _GuitarScalePositionsPanel({required this.pcs, required this.rootPc, required this.showLabels});

  static const int _fretsVisible = 4;

  List<int> _computeStartFrets() {
    // GuitarFretboard renders a 4-fret window. For scale practice we want a few
    // “standard-ish” windows across the neck where the tonic is present.
    //
    // We keep this algorithm fully offline + theory-agnostic:
    // - scan start frets 0..12
    // - keep windows that contain the root on at least one string
    // - pick up to 5 windows, spaced out a bit so they feel like “positions”
    final candidates = <int>[];
    for (int start = 0; start <= 12; start++) {
      var hasRoot = false;
      for (int s = 0; s < TheoryUtils.guitarTuning.length; s++) {
        final openPc = TheoryUtils.guitarTuning[s];
        for (int rf = 0; rf < _fretsVisible; rf++) {
          final pc = (openPc + start + rf) % 12;
          if (pc == rootPc) {
            hasRoot = true;
            break;
          }
        }
        if (hasRoot) break;
      }
      if (hasRoot) candidates.add(start);
    }

    if (candidates.isEmpty) return const [0, 3, 5, 7, 10];

    final picked = <int>[];
    for (final c in candidates) {
      if (picked.isEmpty || c - picked.last >= 2) {
        picked.add(c);
        if (picked.length == 5) break;
      }
    }

    // If we still have fewer than 5, extend past the octave (e.g. +12)
    // so the UI consistently shows “positions”.
    while (picked.length < 5) {
      picked.add(picked.last + 2);
    }
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startFrets = _computeStartFrets();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gesture_rounded, color: theme.colorScheme.tertiary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Guitar Scale Positions',
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Frets 1–12 (positions noted above)',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (int i = 0; i < startFrets.length; i++)
                _PositionPill(label: 'Pos ${i + 1}', detail: 'Fret ${startFrets[i]}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Single full-width fretboard view. We keep the same interval color coding
          // as the rest of the app, but show only frets 1–12.
          GuitarFretboard(
            startFret: 1,
            fretsVisible: 12,
            nutRight: false,
            selectedPcs: pcs,
            rootPc: rootPc,
            showLabels: showLabels,
          ),
        ],
      ),
    );
  }
}

class _PositionPill extends StatelessWidget {
  final String label;
  final String detail;

  const _PositionPill({required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.22)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900)),
            TextSpan(text: '  ', style: theme.textTheme.labelMedium),
            TextSpan(text: detail, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _PianoPanel extends StatelessWidget {
  final Set<int> pcs;
  final int rootPc;
  final bool showLabels;
  final List<int>? voicingOrder;
  final bool forceFixedHeight;

  const _PianoPanel({required this.pcs, required this.rootPc, required this.showLabels, required this.voicingOrder, this.forceFixedHeight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboard = PianoKeyboard(
      selectedPcs: pcs,
      rootPc: rootPc,
      showLabels: showLabels,
      octaves: 2,
      anchorPc: voicingOrder?.isNotEmpty == true ? voicingOrder!.first : null,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.piano_rounded, color: theme.colorScheme.tertiary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text('Piano Keyboard', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (forceFixedHeight) SizedBox(height: 160, child: keyboard) else keyboard,
        ],
      ),
    );
  }
}

class _ControlsBar extends StatelessWidget {
  final bool showScale;
  final ValueChanged<bool> onModeChanged; // false -> chord, true -> scale
  final List<Chord> chords;
  final int selectedChordIndex;
  final ValueChanged<int> onSelectChord;
  final List<String> scaleIds;
  final int selectedScaleIndex;
  final ValueChanged<int> onSelectScale;
  final String keyName;
  final VoidCallback onTapKeyChip;

  const _ControlsBar({
    required this.showScale,
    required this.onModeChanged,
    required this.chords,
    required this.selectedChordIndex,
    required this.onSelectChord,
    required this.scaleIds,
    required this.selectedScaleIndex,
    required this.onSelectScale,
    required this.keyName,
    required this.onTapKeyChip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Use Wrap so the controls gracefully flow on small screens (prevents overflow)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              _ModeChip(label: 'Show Chord', selected: !showScale, onTap: ()=> onModeChanged(false)),
              const SizedBox(width: 8),
              _ModeChip(label: 'Show Scale', selected: showScale, onTap: ()=> onModeChanged(true)),
            ]),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapKeyChip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.dividerColor)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.music_note_rounded, color: theme.colorScheme.secondary, size: 16),
                  const SizedBox(width: 6),
                  Text(keyName, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface), overflow: TextOverflow.ellipsis),
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: theme.colorScheme.onSurface),
                ]),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        if (!showScale)
          _DropdownField<Chord>(
            icon: Icons.library_music_rounded,
            label: 'Chord (in key)',
            value: chords[selectedChordIndex],
            items: chords,
            display: (c) => '${c.roman} • ${c.name} (${c.type})',
            onChanged: (c){
              final idx = chords.indexOf(c);
              onSelectChord(idx < 0 ? 0 : idx);
            },
          )
        else
          _DropdownField<String>(
            icon: Icons.auto_awesome_motion_rounded,
            label: 'Scale',
            value: scaleIds[selectedScaleIndex],
            items: scaleIds,
            display: (id) => TheoryUtils.scaleNames[id]!,
            onChanged: (id){
              final idx = scaleIds.indexOf(id);
              onSelectScale(idx < 0 ? 0 : idx);
            },
          ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.tertiary : theme.scaffoldBackgroundColor,
          border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface)),
        ]),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) display;
  final ValueChanged<T> onChanged;
  const _DropdownField({required this.icon, required this.label, required this.value, required this.items, required this.display, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: theme.dividerColor)),
      child: Row(children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            underline: const SizedBox.shrink(),
            dropdownColor: theme.cardTheme.color,
            items: items.map((e)=> DropdownMenuItem<T>(value: e, child: Text(display(e), overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)))).toList(),
            onChanged: (v){ if (v != null) onChanged(v); },
          ),
        ),
      ]),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<IntervalColors>()!;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _legend(colors.root, 'Root (1) • Teal'),
        _legend(colors.third, '3rd (3) • Light Blue'),
        _legend(colors.fifth, '5th (5) • Gray'),
        _legend(colors.seventh, '7th (7) • Purple'),
        _legend(colors.extensionColor, '2 / 4 / 6 + extensions • Orange'),
      ],
    );
  }

  Widget _legend(Color c, String label){
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label),
    ]);
  }
}

// Key picker sheet extracted to widgets/key_picker_sheet.dart
