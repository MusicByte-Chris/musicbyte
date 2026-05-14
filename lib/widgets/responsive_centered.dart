import 'package:flutter/material.dart';

/// Centers content on large screens with a max width and adaptive padding.
///
/// Useful for making phone-first pages feel natural on desktop/tablet, while
/// still allowing full-bleed backgrounds if the parent provides them.
class ResponsiveCentered extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveCentered({super.key, required this.child, this.maxWidth = 980, this.padding = EdgeInsets.zero});

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontal = width >= 1200 ? 48.0 : (width >= 900 ? 32.0 : 20.0);
        final effectivePadding = padding.add(EdgeInsets.symmetric(horizontal: horizontal));
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: effectivePadding, child: child),
          ),
        );
      },
    );
  }
}
