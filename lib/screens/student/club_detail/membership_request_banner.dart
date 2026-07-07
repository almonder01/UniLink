part of '../club_detail_screen.dart';

class _MembershipRequestBanner extends StatelessWidget {
  final String? status;
  final VoidCallback onRequest;

  const _MembershipRequestBanner({
    required this.status,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = switch (status) {
      'pending' => 'Membership request pending',
      'payment_requested' => 'Payment requested by club manager',
      'approved' => 'Membership approved',
      'rejected' => 'Request rejected',
      _ => 'Request membership',
    };
    final canRequest = status == null || status == 'rejected';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(Icons.how_to_reg_rounded, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.tonal(
              onPressed: canRequest ? onRequest : null,
              child: Text(canRequest ? 'Request' : 'Sent'),
            ),
          ],
        ),
      ),
    );
  }
}
