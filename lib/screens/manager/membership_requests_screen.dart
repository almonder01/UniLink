import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/club.dart';
import '../../models/club_membership_request.dart';
import '../../providers/auth_provider.dart';
import '../../services/club_payment_service.dart';
import '../../services/membership_request_service.dart';

class MembershipRequestsScreen extends StatelessWidget {
  final ClubModel club;

  const MembershipRequestsScreen({super.key, required this.club});

  Future<void> _approve(
    BuildContext context,
    ClubMembershipRequest request,
  ) async {
    final manager = context.read<AuthProvider>().currentUser;
    if (manager == null) return;
    await MembershipRequestService().approve(
      club: club,
      request: request,
      managerId: manager.id,
    );
  }

  Future<void> _reject(ClubMembershipRequest request) async {
    await MembershipRequestService().reject(club: club, request: request);
  }

  Future<void> _requestPayment(
    BuildContext context,
    ClubMembershipRequest request,
  ) async {
    final manager = context.read<AuthProvider>().currentUser;
    if (manager == null) return;
    final result = await showDialog<_PaymentRequestInput>(
      context: context,
      builder: (_) => const _PaymentRequestDialog(),
    );
    if (result == null) return;
    await ClubPaymentService().sendMonthlyRequestByEmail(
      club: club,
      manager: manager,
      amount: result.amount,
      currency: result.currency,
      message: result.message,
      email: request.userEmail,
    );
    await MembershipRequestService().markPaymentRequested(request);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Membership Requests')),
      body: StreamBuilder<List<ClubMembershipRequest>>(
        stream: MembershipRequestService().requestsForClub(club.id),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? const <ClubMembershipRequest>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No membership requests yet',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _RequestCard(
                request: request,
                onApprove: request.status == 'approved'
                    ? null
                    : () => _approve(context, request),
                onReject: request.status == 'rejected'
                    ? null
                    : () => _reject(request),
                onRequestPayment: request.status == 'approved'
                    ? null
                    : () => _requestPayment(context, request),
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ClubMembershipRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRequestPayment;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onRequestPayment,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (request.status) {
      'approved' => ('Approved', const Color(0xFF22C55E)),
      'rejected' => ('Rejected', const Color(0xFFEF4444)),
      'payment_requested' => ('Payment requested', const Color(0xFFF59E0B)),
      _ => ('Pending', const Color(0xFF6366F1)),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.person_rounded, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.userName,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(
                        request.userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: onRequestPayment,
                  icon: const Icon(Icons.payments_rounded, size: 18),
                  label: const Text('Request payment'),
                ),
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRequestInput {
  final double amount;
  final String currency;
  final String message;

  const _PaymentRequestInput({
    required this.amount,
    required this.currency,
    required this.message,
  });
}

class _PaymentRequestDialog extends StatefulWidget {
  const _PaymentRequestDialog();

  @override
  State<_PaymentRequestDialog> createState() => _PaymentRequestDialogState();
}

class _PaymentRequestDialogState extends State<_PaymentRequestDialog> {
  final _amountCtrl = TextEditingController();
  final _messageCtrl =
      TextEditingController(text: 'Membership payment before joining');
  String _currency = 'RM';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    Navigator.of(context).pop(
      _PaymentRequestInput(
        amount: amount,
        currency: _currency,
        message: _messageCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _currency,
                items: const [
                  DropdownMenuItem(value: 'RM', child: Text('RM')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _currency = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Send'),
        ),
      ],
    );
  }
}
