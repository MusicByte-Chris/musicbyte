import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import 'package:musicbyteai/widgets/responsive_centered.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
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
                    border: Border.all(color: theme.colorScheme.tertiary),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(Icons.memory_rounded, color: theme.colorScheme.tertiary, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  "MusicByte",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  "Version 1.03 (Build 120)",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              "The Utility Focus",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            const _InfoTile(
              icon: Icons.offline_bolt_rounded,
              title: "Offline First",
              description: "Zero network calls. Your reference data is stored locally for instant access in the studio or on stage.",
            ),
            const _InfoTile(
              icon: Icons.straighten_rounded,
              title: "Pro Engineering",
              description: "Built by audio engineers for audio engineers. No gamification, just high-precision utility tools.",
            ),
            const _InfoTile(
              icon: Icons.privacy_tip_rounded,
              title: "Privacy Centric",
              description: "No accounts, no tracking, and no ads. Your practice logs and settings stay on your device.",
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
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
                      Icon(Icons.workspace_premium_rounded, color: theme.colorScheme.tertiary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "License Information",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                     "MusicByte is free for your first year of professional use. After 365 days, a one-time purchase of \$4.99 unlocks lifetime access.",
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.push('/upgrade'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.tertiary,
                      side: BorderSide(color: theme.colorScheme.tertiary),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text("Support the Project (Tip Jar)"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text(
              "Credits & Legal",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            const Column(
              children: [
                _ActionRow(icon: Icons.person_outline_rounded, label: "Built by Musicians & Engineers"),
                _ActionRow(icon: Icons.description_outlined, label: "Terms of Service"),
                _ActionRow(icon: Icons.gavel_rounded, label: "Privacy Policy"),
                _ActionRow(icon: Icons.code_rounded, label: "Open Source Licenses"),
              ],
            ),

            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text("Handcrafted for the Audio Community", style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                  Text("© 2024 MusicByte", style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoTile({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: theme.colorScheme.tertiary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.secondary, size: 20),
              const SizedBox(width: 16),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 20),
        ],
      ),
    );
  }
}
