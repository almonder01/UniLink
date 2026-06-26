import 'package:flutter/material.dart';

class ColorSwatchPicker extends StatelessWidget {
  static const eventSwatches = [
    'FFFF6B35',
    'FFF97316',
    'FFEF4444',
    'FFEC4899',
    'FFA855F7',
    'FF6366F1',
    'FF3B82F6',
    'FF14B8A6',
    'FF10B981',
    'FF22C55E',
  ];

  static const postSwatches = [
    'FF6366F1',
    'FF8B5CF6',
    'FF3B82F6',
    'FF14B8A6',
    'FF10B981',
    'FF22C55E',
    'FFF59E0B',
    'FFEF4444',
    'FFEC4899',
    'FFFF6B35',
  ];

  final String selectedColor;
  final ValueChanged<String> onColorSelected;
  final List<String> swatches;
  final String label;

  const ColorSwatchPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.swatches = eventSwatches,
    this.label = 'Event Accent Color',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: swatches.map((hex) {
            final c = Color(int.parse(hex, radix: 16));
            final selected = selectedColor == hex;
            return GestureDetector(
              onTap: () => onColorSelected(hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? cs.onSurface : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: c.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}