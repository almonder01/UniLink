import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDateTimeCard extends StatelessWidget {
  final TextEditingController locationCtrl;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const EventDateTimeCard({
    super.key,
    required this.locationCtrl,
    required this.selectedDate,
    required this.selectedTime,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_rounded),
                hintText: 'e.g. Block B, Auditorium',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a location'
                  : null,
            ),
            const SizedBox(height: 12),
            // Date picker
            InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 20,
                        color: selectedDate != null
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate != null
                          ? DateFormat('EEEE, MMMM d, y').format(selectedDate!)
                          : 'Select Date',
                      style: TextStyle(
                          fontSize: 14,
                          color: selectedDate != null
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.45),
                          fontWeight: selectedDate != null
                              ? FontWeight.w500
                              : FontWeight.w400),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Time picker
            InkWell(
              onTap: onPickTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 20,
                        color: selectedTime != null
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 12),
                    Text(
                      selectedTime != null
                          ? selectedTime!.format(context)
                          : 'Select Time',
                      style: TextStyle(
                          fontSize: 14,
                          color: selectedTime != null
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.45),
                          fontWeight: selectedTime != null
                              ? FontWeight.w500
                              : FontWeight.w400),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
