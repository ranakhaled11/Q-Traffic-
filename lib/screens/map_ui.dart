import 'dart:ui';
import 'package:flutter/material.dart';

class MapGlassPill extends StatelessWidget {
  final Widget child;
  const MapGlassPill({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            border: Border.all(color: Colors.white.withOpacity(0.45)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}

class MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;
  final double weight;

  const MapIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xff111827),
    this.size = 20,
    this.weight = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: size,
            color: color,
            weight: weight,
          ),
        ),
      ),
    );
  }
}

class BottomCardShell extends StatelessWidget {
  final Widget child;
  const BottomCardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            color: Color(0x1A000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AddressTextStyle {
  static const Color ink = Color(0xff111827);
  static const Color sub = Color(0xff6B7280);

  static const label = TextStyle(
    fontSize: 12,
    color: sub,
    fontWeight: FontWeight.w600,
  );

  static const value = TextStyle(
    fontSize: 14,
    color: ink,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const title = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: ink,
  );

  static const meta = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: sub,
  );
}

class AddressLine extends StatelessWidget {
  final String label;
  final Widget content;
  final Widget? trailing;

  const AddressLine({
    super.key,
    required this.label,
    required this.content,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Text(label, style: AddressTextStyle.label),
        ),
        const SizedBox(width: 8),
        Expanded(child: content),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          trailing!,
        ]
      ],
    );
  }
}
