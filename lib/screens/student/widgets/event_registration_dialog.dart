import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/event.dart';

Future<bool> showEventRegistrationDialog(
  BuildContext context, {
  required EventModel event,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _EventRegistrationDialog(event: event),
  );
  return result == true;
}

class _EventRegistrationDialog extends StatelessWidget {
  final EventModel event;

  const _EventRegistrationDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.confirmation_number_rounded,
              color: Color(0xFFF97316),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Registration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: DateFormat('EEE, MMM d, y').format(event.eventDate),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: DateFormat('h:mm a').format(event.eventDate),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.location_on_rounded,
            label: event.location,
          ),
          const SizedBox(height: 12),
          Text(
            'Do you want to register for this event?',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: cs.onSurface.withValues(alpha: 0.48)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}
