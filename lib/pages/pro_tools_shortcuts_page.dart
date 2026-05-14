import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/data/pro_tools_shortcuts.dart';
import 'package:musicbyteai/models/shortcut_model.dart';
import 'package:musicbyteai/theme.dart';

enum ShortcutPlatform { mac, windows }

class ProToolsShortcutsPage extends StatefulWidget {
  const ProToolsShortcutsPage({super.key});

  @override
  State<ProToolsShortcutsPage> createState() => _ProToolsShortcutsPageState();
}

class _ProToolsShortcutsPageState extends State<ProToolsShortcutsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  ShortcutPlatform _platform = ShortcutPlatform.mac;
  final Set<String> _selectedCategories = <String>{};
  final Set<String> _selectedFunctionTypes = <String>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() => setState(() {
        _selectedCategories.clear();
        _selectedFunctionTypes.clear();
      });

  List<ShortcutModel> _applyFilters(List<ShortcutModel> items) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return items.where((s) {
      final matchesQuery = q.isEmpty ||
          s.command.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.tags.any((t) => t.toLowerCase().contains(q));

      final catOk = _selectedCategories.isEmpty || _selectedCategories.contains(s.primaryCategory);
      final typeOk = _selectedFunctionTypes.isEmpty || _selectedFunctionTypes.contains(s.functionType);

      return matchesQuery && catOk && typeOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _applyFilters(proToolsShortcuts);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
        ),
        title: Text('Pro Tools Shortcuts', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset filters',
            onPressed: _resetFilters,
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchAndPlatformBar(
                controller: _searchCtrl,
                platform: _platform,
                onPlatformChanged: (p) => setState(() => _platform = p),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _FilterChips(
                title: 'Category',
                options: kDefaultCategories,
                selected: _selectedCategories,
                onToggled: (label, sel) => setState(() {
                  sel ? _selectedCategories.add(label) : _selectedCategories.remove(label);
                }),
              ),
              const SizedBox(height: 8),
              _FilterChips(
                title: 'Function Type',
                options: kDefaultFunctionTypes,
                selected: _selectedFunctionTypes,
                onToggled: (label, sel) => setState(() {
                  sel ? _selectedFunctionTypes.add(label) : _selectedFunctionTypes.remove(label);
                }),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? _EmptyState(platform: _platform)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final s = items[index];
                          final shortcut = _platform == ShortcutPlatform.mac ? s.shortcutMac : s.shortcutWindows;
                          return _ShortcutCard(item: s, shortcut: shortcut);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchAndPlatformBar extends StatelessWidget {
  final TextEditingController controller;
  final ShortcutPlatform platform;
  final ValueChanged<ShortcutPlatform> onPlatformChanged;
  final ValueChanged<String> onChanged;
  const _SearchAndPlatformBar({
    required this.controller,
    required this.platform,
    required this.onPlatformChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: theme.dividerColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: theme.colorScheme.secondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      hintText: 'Search commands, descriptions, or tags…',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                      border: InputBorder.none,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: Icon(Icons.close_rounded, color: theme.colorScheme.secondary),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _PlatformToggle(value: platform, onChanged: onPlatformChanged),
      ],
    );
  }
}

class _PlatformToggle extends StatelessWidget {
  final ShortcutPlatform value;
  final ValueChanged<ShortcutPlatform> onChanged;
  const _PlatformToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          _SegButton(
            label: 'Mac',
            icon: Icons.laptop_mac_rounded,
            selected: value == ShortcutPlatform.mac,
            onTap: () => onChanged(ShortcutPlatform.mac),
          ),
          _SegButton(
            label: 'Windows',
            icon: Icons.window_rounded,
            selected: value == ShortcutPlatform.windows,
            onTap: () => onChanged(ShortcutPlatform.windows),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  final String label; final IconData icon; final bool selected; final VoidCallback onTap;
  const _SegButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Icon(icon, size: 16, color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            )),
          ]),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String title; final List<String> options; final Set<String> selected; final void Function(String, bool) onToggled;
  const _FilterChips({required this.title, required this.options, required this.selected, required this.onToggled});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(title, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
        ),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((label) {
            final isSelected = selected.contains(label);
            return ChoiceChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(label, style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                )),
              ),
              selected: isSelected,
              onSelected: (v) => onToggled(label, v),
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.scaffoldBackgroundColor,
              side: BorderSide(color: theme.dividerColor),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final ShortcutModel item; final String shortcut;
  const _ShortcutCard({required this.item, required this.shortcut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.keyboard_rounded, size: 18, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.command, style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold,
                ), overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(shortcut, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              _TagChip(label: item.primaryCategory, icon: Icons.category_rounded),
              _TagChip(label: item.functionType, icon: Icons.tune_rounded),
              ...item.tags.map((t) => _TagChip(label: t, icon: Icons.tag_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label; final IconData icon; const _TagChip({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: theme.colorScheme.secondary),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ShortcutPlatform platform; const _EmptyState({required this.platform});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_alt_rounded, size: 32, color: theme.colorScheme.tertiary),
            const SizedBox(height: 12),
            Text('No shortcuts to show yet', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Waiting for dataset… I\'ll append incoming chunks to the in-memory list.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
