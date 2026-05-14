import 'package:flutter/material.dart';
import 'package:musicbyteai/theme.dart';

/// A consistent page header used across the app.
///
/// This mirrors the header style established on Engineer Reference:
/// - Title: `headlineMedium` + bold
/// - Subtitle: `bodyMedium` in secondary color
/// - Trailing: optional circular on-card surface with a hairline border
class LuxuryPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  /// Convenience option for the common trailing circular icon.
  final IconData? trailingIcon;

  const LuxuryPageHeader({super.key, required this.title, required this.subtitle, this.trailing, this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget trailingWidget = trailing ??
        (trailingIcon == null
            ? const SizedBox.shrink()
            : _LuxuryHeaderIcon(
                icon: trailingIcon!,
              ));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
          ],
        ),
        trailingWidget,
      ],
    );
  }
}

class _LuxuryHeaderIcon extends StatelessWidget {
  final IconData icon;
  const _LuxuryHeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Icon(icon, color: theme.colorScheme.tertiary, size: 24),
    );
  }
}
