import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musicbyteai/theme.dart';
import 'package:musicbyteai/widgets/responsive_centered.dart';

class UpgradePage extends StatelessWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ResponsiveCentered(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
            Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: [
                      BoxShadow(color: theme.shadowColor.withValues(alpha: 0.1), blurRadius: 10),
                    ],
                  ),
                  child: Icon(Icons.favorite_rounded, color: theme.colorScheme.primary, size: 42),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tip Jar',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'A small tip helps keep MusicByte improving.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Support the Developer",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  "MusicByte is built by a solo engineer. If you find it useful, consider leaving a tip.",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: _TipButton(emoji: "☕", amount: "\$2", label: "Coffee")),
                SizedBox(width: 16),
                Expanded(child: _TipButton(emoji: "🎸", amount: "\$5", label: "Strings")),
                SizedBox(width: 16),
                Expanded(child: _TipButton(emoji: "⚡", amount: "\$10", label: "Power Up")),
              ],
            ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipButton extends StatelessWidget {
  final String emoji;
  final String amount;
  final String label;

  const _TipButton({required this.emoji, required this.amount, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            amount,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}
