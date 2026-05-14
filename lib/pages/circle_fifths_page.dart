import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/data/theory_repository.dart';
import 'package:musicbyteai/models/music_theory.dart';
import 'package:musicbyteai/services/key_context_service.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/widgets/responsive_centered.dart';
import 'package:musicbyteai/widgets/luxury_page_header.dart';

String _minorShortLabel(String relativeMinorName) {
  // Examples: 'A Minor' -> 'Am', 'F♯ Minor' -> 'F♯m'
  final root = relativeMinorName.split(' ').first;
  return '${root}m';
}

class CircleOfFifthsPage extends StatefulWidget {
  const CircleOfFifthsPage({super.key});

  @override
  State<CircleOfFifthsPage> createState() => _CircleOfFifthsPageState();
}

class _CircleOfFifthsPageState extends State<CircleOfFifthsPage> {
  final PageController _pageController = PageController(viewportFraction: 0.85, initialPage: 1000 * 12);
  bool _showRadialMenu = false;
  int _selectedIndex = 0;
  int? _hoveredIndex;
  int? _hoveredMinorIndex;
  bool _pendingPageSync = false;

  @override
  void initState() {
    super.initState();
    // After first frame, jump to the key currently selected in the active context
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncToActiveKey());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _syncToActiveKey() async {
    try {
      final ctx = await KeyContextService.instance.load();
      final keys = TheoryRepository.circleOfFifths;
      final idx = keys.indexWhere((k) => k.id == ctx.selectedKeyId);
      final clampedIndex = idx >= 0 ? idx : 0;

      if (mounted) setState(() => _selectedIndex = clampedIndex);

      final base = 1000 * keys.length;
      final target = base + clampedIndex;
      if (!mounted) return;
      // Important: this page uses the PageController only in the mobile layout.
      // On wide layouts there is no PageView, so calling jumpToPage would assert.
      if (_pageController.hasClients) {
        _pageController.jumpToPage(target);
      } else {
        _pendingPageSync = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_pendingPageSync && _pageController.hasClients) {
            _pendingPageSync = false;
            try {
              _pageController.jumpToPage(target);
            } catch (e) {
              debugPrint('CircleOfFifthsPage: delayed page sync failed: $e');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('CircleOfFifthsPage: failed to sync with active key: $e');
    }
  }

  Future<void> _selectKey(int index) async {
    final keys = TheoryRepository.circleOfFifths;
    final clamped = index.clamp(0, keys.length - 1);
    setState(() => _selectedIndex = clamped);
    // Persist best-effort; don't block UI/navigation on storage I/O.
    try {
      // ignore: discarded_futures
      KeyContextService.instance.setSelectedKey(keys[clamped].id);
    } catch (e) {
      debugPrint('CircleOfFifthsPage: failed to persist selected key: $e');
    }
  }

  Future<void> _openKeyDetailsByIndex(int index) async {
    final keys = TheoryRepository.circleOfFifths;
    final clamped = index.clamp(0, keys.length - 1);
    await _selectKey(clamped);
    if (!mounted) return;
    context.push('/key/${keys[clamped].id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = TheoryRepository.circleOfFifths;
    final isWide = ResponsiveCentered.isWide(context);
    final selectedKey = keys[_selectedIndex.clamp(0, keys.length - 1)];

    if (isWide) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: ResponsiveCentered(
            maxWidth: 1200,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CircleHeader(
                  subtitle: 'Click a key to explore relationships',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Open key details',
                        onPressed: () => context.push('/key/${selectedKey.id}'),
                        icon: Icon(Icons.open_in_new_rounded, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _DesktopKeyDetailsPanel(
                          keyData: selectedKey,
                          onViewKey: () => context.push('/key/${selectedKey.id}'),
                          onOpenViewer: () => context.push('/viewer?key=${Uri.encodeComponent(selectedKey.id)}&tab=chord'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _CircleWheelPanel(
                          keys: keys,
                          selectedIndex: _selectedIndex,
                          hoveredIndex: _hoveredIndex,
                          onHoverChanged: (idx) => setState(() => _hoveredIndex = idx),
                          hoveredMinorIndex: _hoveredMinorIndex,
                          onMinorHoverChanged: (idx) => setState(() => _hoveredMinorIndex = idx),
                          onSelect: (idx) => _openKeyDetailsByIndex(idx),
                          onSelectRelativeMinor: (majorIdx) {
                            final major = keys[majorIdx];
                            final minorId = TheoryRepository.relativeMinorIdForMajor(major.id);
                            context.push('/viewer?key=${Uri.encodeComponent(minorId)}&tab=scale');
                          },
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

    // Mobile layout (phone-first): keep the swipeable cards.
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CircleHeader(
                  subtitle: 'Swipe to explore harmonic relationships',
                  trailing: const SizedBox.shrink(),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      final idx = page % keys.length;
                      _selectKey(idx);
                    },
                    itemBuilder: (context, index) {
                      final keyData = keys[index % keys.length];
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = _pageController.page! - index;
                            value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
                          }
                          return Center(
                            child: SizedBox(
                              height: Curves.easeOut.transform(value) * 500,
                              width: Curves.easeOut.transform(value) * 350,
                              child: child,
                            ),
                          );
                        },
                        child: _KeyCard(keyData: keyData),
                      );
                    },
                  ),
                ),
                // Indicator dots (decorative)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 24, height: 4, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 4),
                      Container(width: 8, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 4),
                      Container(width: 8, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),

            // Radial Menu Overlay (mobile quick select)
            if (_showRadialMenu)
              Stack(
                children: [
                  // Background dismiss layer (kept separate so it can't steal taps from nodes).
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _showRadialMenu = false),
                      child: Container(color: Colors.black.withValues(alpha: 0.7)),
                    ),
                  ),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(keys.length, (index) {
                          final angle = (index * (360 / keys.length) - 90) * (math.pi / 180);
                          final radius = 140.0;
                          final x = math.cos(angle) * radius;
                          final y = math.sin(angle) * radius;
                          return Align(
                            alignment: Alignment(x / 160, y / 250),
                            child: _RadialNode(
                              label: keys[index].name.split(' ').first,
                              style: _RadialNodeStyle.major,
                              onTap: () {
                                // Close overlay first so it can't remain in the
                                // hit-test stack during navigation.
                                setState(() => _showRadialMenu = false);
                                Future.microtask(() {
                                  if (!context.mounted) return;
                                  context.push('/key/${keys[index].id}');
                                });
                              },
                            ),
                          );
                        }),

                        // Inner ring: relative minors
                        ...List.generate(keys.length, (index) {
                          final angle = (index * (360 / keys.length) - 90) * (math.pi / 180);
                          final radius = 92.0;
                          final x = math.cos(angle) * radius;
                          final y = math.sin(angle) * radius;
                          return Align(
                            alignment: Alignment(x / 160, y / 250),
                            child: _RadialNode(
                              label: _minorShortLabel(keys[index].relativeMinor),
                              style: _RadialNodeStyle.minor,
                              onTap: () {
                                final minorId = TheoryRepository.relativeMinorIdForMajor(keys[index].id);
                                setState(() => _showRadialMenu = false);
                                Future.microtask(() {
                                  if (!context.mounted) return;
                                  context.push('/viewer?key=${Uri.encodeComponent(minorId)}&tab=scale');
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: _showRadialMenu
          ? null
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _showRadialMenu = true),
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Quick Select'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
    );
  }
}

class _CircleHeader extends StatelessWidget {
  final String subtitle;
  final Widget trailing;

  const _CircleHeader({required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LuxuryPageHeader(title: 'Circle of Fifths', subtitle: subtitle, trailing: trailing),
    );
  }
}

class _DesktopKeyDetailsPanel extends StatelessWidget {
  final KeyData keyData;
  final VoidCallback onViewKey;
  final VoidCallback onOpenViewer;

  const _DesktopKeyDetailsPanel({required this.keyData, required this.onViewKey, required this.onOpenViewer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tonicTriad = TheoryUtils.spelledChordTonesInKey(keyId: keyData.id, chordType: 'Major', degreeIndex: 0);
    final spelledScale = TheoryUtils.spelledMajorScaleForKey(keyData.id);
    final leadingTone = spelledScale.length >= 7 ? spelledScale[6] : '-';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  keyData.name,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  keyData.accidentalsCountString,
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(keyData.signatureDesc, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricTile(label: 'Relative Minor', value: keyData.relativeMinor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(label: 'Mode', value: keyData.mode),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tonic Triad (1–3–5)', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _ChipLike(value: tonicTriad.isNotEmpty ? tonicTriad[0] : '-', emphasized: true),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _ChipLike(value: tonicTriad.length > 1 ? tonicTriad[1] : '-')),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _ChipLike(value: tonicTriad.length > 2 ? tonicTriad[2] : '-')),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text('Leading tone (7)', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    _ChipLike(value: leadingTone, emphasized: true),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onViewKey,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Key Details'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenViewer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  icon: Icon(Icons.piano_rounded, color: theme.colorScheme.onSurface),
                  label: const Text('Chord/Scale'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ChipLike extends StatelessWidget {
  final String value;
  final bool emphasized;

  const _ChipLike({required this.value, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = emphasized ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final fg = emphasized ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6))),
      child: Text(value, style: theme.textTheme.labelLarge?.copyWith(color: fg, fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600)),
    );
  }
}

class _CircleWheelPanel extends StatelessWidget {
  final List<KeyData> keys;
  final int selectedIndex;
  final int? hoveredIndex;
  final ValueChanged<int?> onHoverChanged;
  final int? hoveredMinorIndex;
  final ValueChanged<int?> onMinorHoverChanged;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onSelectRelativeMinor;

  const _CircleWheelPanel({
    required this.keys,
    required this.selectedIndex,
    required this.hoveredIndex,
    required this.onHoverChanged,
    required this.hoveredMinorIndex,
    required this.onMinorHoverChanged,
    required this.onSelect,
    required this.onSelectRelativeMinor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(constraints.maxWidth, constraints.maxHeight);
          final majorRadius = size * 0.36;
          final minorRadius = size * 0.24;
          return Center(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // subtle rings
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: _WheelRingsPainter(color: theme.dividerColor.withValues(alpha: 0.8)),
                    ),
                  ),
                  // center label
                  Container(
                    width: size * 0.30,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.8)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Selected', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        Text(
                          keys[selectedIndex].name.split(' ').first,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '↻ fifths / ↺ fourths',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // IMPORTANT (web/desktop hit-testing): Each node is visually
                  // translated far away from center. If the translating widget is
                  // inside a small-sized Stack, the nodes can *paint* outside but
                  // not receive pointer events because hit-testing is clipped to
                  // the parent's bounds. Using Positioned.fill ensures the parent
                  // covers the whole wheel, so translated children remain hittable.
                  ...List.generate(keys.length, (index) {
                    final angle = (index * (360 / keys.length) - 90) * (math.pi / 180);
                    final mx = math.cos(angle) * majorRadius;
                    final my = math.sin(angle) * majorRadius;
                    final sx = math.cos(angle) * minorRadius;
                    final sy = math.sin(angle) * minorRadius;
                    final isSelected = index == selectedIndex;
                    final isHovered = hoveredIndex == index;
                    final isMinorHovered = hoveredMinorIndex == index;

                    return Positioned.fill(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Transform.translate(
                              offset: Offset(mx, my),
                              child: _WheelNode(
                                label: keys[index].name.split(' ').first,
                                isSelected: isSelected,
                                isHovered: isHovered,
                                size: 56,
                                style: _WheelNodeStyle.major,
                                onEnter: () => onHoverChanged(index),
                                onExit: () => onHoverChanged(null),
                                onTap: () => onSelect(index),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Transform.translate(
                              offset: Offset(sx, sy),
                              child: _WheelNode(
                                label: _minorShortLabel(keys[index].relativeMinor),
                                isSelected: false,
                                isHovered: isMinorHovered,
                                size: 46,
                                style: _WheelNodeStyle.minor,
                                onEnter: () => onMinorHoverChanged(index),
                                onExit: () => onMinorHoverChanged(null),
                                onTap: () => onSelectRelativeMinor(index),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _WheelNodeStyle { major, minor }

class _WheelNode extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isHovered;
  final double size;
  final _WheelNodeStyle style;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onTap;

  const _WheelNode({
    required this.label,
    required this.isSelected,
    required this.isHovered,
    required this.size,
    required this.style,
    required this.onEnter,
    required this.onExit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMinor = style == _WheelNodeStyle.minor;
    final bg = isSelected
        ? theme.colorScheme.primary
        : (isMinor ? theme.colorScheme.surfaceContainerHighest : theme.scaffoldBackgroundColor);
    final fg = isSelected
        ? theme.colorScheme.onPrimary
        : (isMinor ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface);
    final border = isSelected
        ? theme.colorScheme.primary
        : (isMinor ? theme.dividerColor.withValues(alpha: 0.65) : theme.dividerColor.withValues(alpha: 0.9));

    return MouseRegion(
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // On Flutter web/desktop, relying on the default hit-test behavior can
        // make taps feel “dead” if the pointer lands on transparent pixels or
        // if transforms/layout cause subtle hit-test gaps. Make the whole
        // circle area consistently clickable.
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint('CircleOfFifthsPage: wheel node tapped: $label');
          onTap();
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          scale: isSelected
              ? 1.10
              : (isHovered
                  ? 1.06
                  : 1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: isSelected ? 2 : 1),
              boxShadow: [
                if (isHovered || isSelected)
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Text(
              label,
              style: (isMinor ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)?.copyWith(color: fg, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelRingsPainter extends CustomPainter {
  final Color color;

  _WheelRingsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.shortestSide * 0.42;
    final inner = size.shortestSide * 0.22;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = color;
    canvas.drawCircle(center, outer, ringPaint);
    canvas.drawCircle(center, inner, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelRingsPainter oldDelegate) => oldDelegate.color != color;
}

class _KeyCard extends StatelessWidget {
  final KeyData keyData;

  const _KeyCard({required this.keyData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tonicTriad = TheoryUtils.spelledChordTonesInKey(keyId: keyData.id, chordType: 'Major', degreeIndex: 0);
    final spelledScale = TheoryUtils.spelledMajorScaleForKey(keyData.id);
    final leadingTone = spelledScale.length >= 7 ? spelledScale[6] : '-';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                keyData.sharps == 0 ? Icons.radio_button_unchecked : Icons.music_note,
                size: 150,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                keyData.name,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                keyData.mode,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Relative Minor", style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                      const SizedBox(height: 4),
                      Text(keyData.relativeMinor, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Accidentals", style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                      const SizedBox(height: 4),
                      Text(keyData.accidentalsCountString, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Signature", style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                  const SizedBox(height: 4),
                  Text(keyData.signatureDesc, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
                ],
              ),
              
              const Spacer(),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tonic Triad (1–3–5)",
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(tonicTriad.isNotEmpty ? tonicTriad[0] : '-', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        Text(tonicTriad.length > 1 ? tonicTriad[1] : '-', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
                        Text(tonicTriad.length > 2 ? tonicTriad[2] : '-', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '7th (Leading tone)',
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Text(
                            leadingTone,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/key/${keyData.id}'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text("View Key Details"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _RadialNodeStyle { major, minor }

class _RadialNode extends StatelessWidget {
  final String label;
  final _RadialNodeStyle style;
  final VoidCallback onTap;

  const _RadialNode({required this.label, required this.style, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMinor = style == _RadialNodeStyle.minor;
    final bg = isMinor ? theme.colorScheme.surfaceContainerHighest : theme.cardTheme.color;
    final borderColor = isMinor ? theme.dividerColor.withValues(alpha: 0.8) : theme.colorScheme.primary;
    final fg = isMinor ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface;
    final size = isMinor ? 42.0 : 48.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: isMinor ? 1 : 1.4),
          boxShadow: [
            BoxShadow(color: theme.shadowColor.withValues(alpha: 0.22), blurRadius: 6, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(
          label,
          style: (isMinor ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)?.copyWith(color: fg, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
