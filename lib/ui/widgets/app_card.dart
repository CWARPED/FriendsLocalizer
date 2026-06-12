import 'package:flutter/material.dart';
import '../theme.dart';

/// Carte arrondie douce (fond `card` du thème). [onTap] la rend cliquable.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final radius = BorderRadius.circular(14);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(color: p.card, borderRadius: radius),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: card),
    );
  }
}

/// Petit intitulé de section en majuscules atténuées.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: p.textMuted,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
