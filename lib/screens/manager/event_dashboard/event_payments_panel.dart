part of '../event_dashboard_tab.dart';

class _EventPaymentsPanel extends StatelessWidget {
  final EventModel event;

  const _EventPaymentsPanel({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<EventRegistration>>(
      future: EventService().getRegistrationsForEvent(event.id),
      builder: (context, snapshot) {
        final registrations = snapshot.data ?? const <EventRegistration>[];
        final receipts = registrations
            .where((registration) =>
                (registration.paymentReceiptBase64 ?? '').isNotEmpty)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.payments_rounded),
              title: const Text('Event fee'),
              subtitle: Text(event.feeLabel),
            ),
            _MiniDashboardRow(
              firstLabel: 'Receipts',
              firstValue: '${receipts.length}',
              secondLabel: 'Expected',
              secondValue: event.requiresPayment
                  ? '${registrations.where((r) => r.isActive).length}'
                  : '0',
            ),
            const SizedBox(height: 8),
            if (!event.requiresPayment)
              Text(
                'This event is free. No payment receipts are required.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
              )
            else if (receipts.isEmpty)
              Text(
                'No receipts uploaded yet.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
              )
            else
              ...receipts.take(5).map(
                    (registration) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_rounded),
                      title: Text(registration.userName),
                      subtitle: Text(registration.userEmail),
                      trailing: TextButton(
                        onPressed: () => showBase64ImagePreview(
                          context,
                          data: registration.paymentReceiptBase64!,
                        ),
                        child: const Text('View'),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}
