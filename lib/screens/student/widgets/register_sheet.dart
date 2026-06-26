import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/event.dart';

class RegisterSheet extends StatelessWidget {
  final EventModel event;
  const RegisterSheet({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.confirmation_number_rounded,
                color: Color(0xFFF97316), size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            'Register for Event',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          // Event info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                SheetInfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: DateFormat('EEEE, MMMM d, y').format(event.eventDate),
                ),
                const SizedBox(height: 6),
                SheetInfoRow(
                  icon: Icons.schedule_rounded,
                  label: DateFormat('h:mm a').format(event.eventDate),
                ),
                const SizedBox(height: 6),
                SheetInfoRow(
                  icon: Icons.location_on_rounded,
                  label: event.location,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SheetInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const SheetInfoRow({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
