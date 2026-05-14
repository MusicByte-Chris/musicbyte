import 'package:flutter/material.dart';
import 'package:musicbyteai/data/theory_repository.dart';
import 'package:musicbyteai/theme.dart';

/// Reusable bottom sheet to pick a root key from the Circle of Fifths list
class KeyPickerSheet extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;
  const KeyPickerSheet({super.key, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = TheoryRepository.circleOfFifths;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.of(context).padding.bottom),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.music_note_rounded, color: theme.colorScheme.tertiary, size: 18),
              const SizedBox(width: 8),
              Text('Pick Root', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ]),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.6),
              itemBuilder: (context, index) {
                final k = keys[index];
                final isSelected = k.id == selectedId;
                return _KeyChoice(label: k.name, selected: isSelected, onTap: () => onSelect(k.id));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _KeyChoice({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected ? theme.colorScheme.tertiary : theme.scaffoldBackgroundColor;
    final fg = selected ? theme.colorScheme.surface : theme.colorScheme.onSurface;
    final bd = selected ? Colors.transparent : theme.dividerColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: bd)),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg), overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
