import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/club.dart';
import '../../models/club_payment_receipt.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/club_payment_service.dart';
import '../../widgets/base64_image.dart';

class ClubPaymentScreen extends StatefulWidget {
  final ClubModel club;

  const ClubPaymentScreen({super.key, required this.club});

  @override
  State<ClubPaymentScreen> createState() => _ClubPaymentScreenState();
}

class _ClubPaymentScreenState extends State<ClubPaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController(text: 'Monthly club payment');
  final _service = ClubPaymentService();
  String _currency = 'RM';
  bool _sendingAll = false;
  bool _sendingOne = false;
  late Future<ClubPaymentStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _service.statsForClub(widget.club.id);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _statsFuture = _service.statsForClub(widget.club.id);
    });
  }

  double? _amount() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return null;
    return amount;
  }

  Future<void> _sendAll(UserModel manager) async {
    final amount = _amount();
    if (amount == null) {
      _showSnack('Enter a valid amount.');
      return;
    }
    final confirmed = await _confirm('Send payment request to all members?');
    if (confirmed != true) return;

    setState(() => _sendingAll = true);
    try {
      await _service.sendMonthlyRequestToMembers(
        club: widget.club,
        manager: manager,
        amount: amount,
        currency: _currency,
        message: _messageCtrl.text,
      );
      _showSnack('Payment request sent to members.');
      _refresh();
    } catch (e) {
      _showSnack('$e');
    } finally {
      if (mounted) setState(() => _sendingAll = false);
    }
  }

  Future<void> _sendOne(UserModel manager) async {
    final amount = _amount();
    final email = _emailCtrl.text.trim();
    if (amount == null) {
      _showSnack('Enter a valid amount.');
      return;
    }
    if (email.isEmpty) {
      _showSnack('Enter the student email.');
      return;
    }
    final confirmed = await _confirm('Send payment request to $email?');
    if (confirmed != true) return;

    setState(() => _sendingOne = true);
    try {
      await _service.sendMonthlyRequestByEmail(
        club: widget.club,
        manager: manager,
        amount: amount,
        currency: _currency,
        message: _messageCtrl.text,
        email: email,
      );
      _emailCtrl.clear();
      _showSnack('Payment request sent.');
      _refresh();
    } catch (e) {
      _showSnack('$e');
    } finally {
      if (mounted) setState(() => _sendingOne = false);
    }
  }

  Future<bool?> _confirm(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final manager = context.watch<AuthProvider>().currentUser;
    if (manager == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Club Payments')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Payment Request',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 92,
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            decoration:
                                const InputDecoration(labelText: 'Currency'),
                            items: const [
                              DropdownMenuItem(value: 'RM', child: Text('RM')),
                              DropdownMenuItem(value: 'USD', child: Text(r'$')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _currency = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration:
                                const InputDecoration(labelText: 'Amount'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _messageCtrl,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _sendingAll ? null : () => _sendAll(manager),
                      icon: _sendingAll
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.groups_rounded),
                      label: const Text('Send to all members'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Send to one member by email',
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed:
                              _sendingOne ? null : () => _sendOne(manager),
                          icon: _sendingOne
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<ClubPaymentStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final stats = snapshot.data;
                if (stats == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PaymentStatsGrid(stats: stats),
                    const SizedBox(height: 18),
                    const Text(
                      'Recent Receipts',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    if (stats.recentReceipts.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            'No receipts uploaded yet.',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.52),
                            ),
                          ),
                        ),
                      )
                    else
                      ...stats.recentReceipts.map(
                        (receipt) => _ReceiptTile(receipt: receipt),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentStatsGrid extends StatelessWidget {
  final ClubPaymentStats stats;

  const _PaymentStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth < 340 ? 1 : 2;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cards = [
          _PaymentStatCard(
            icon: Icons.request_quote_rounded,
            label: 'Requests',
            value: '${stats.requestCount}',
            color: const Color(0xFF6366F1),
          ),
          _PaymentStatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Submitted',
            value: '${stats.submittedReceipts}/${stats.expectedReceipts}',
            color: const Color(0xFF14B8A6),
          ),
          _PaymentStatCard(
            icon: Icons.today_rounded,
            label: 'Today',
            value: '${stats.todayReceipts}',
            color: const Color(0xFFF97316),
          ),
          _PaymentStatCard(
            icon: Icons.calendar_month_rounded,
            label: 'This Month',
            value: '${stats.monthReceipts}',
            color: const Color(0xFF22C55E),
          ),
        ];
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              cards.map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}

class _PaymentStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PaymentStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  final ClubPaymentReceipt receipt;

  const _ReceiptTile({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long_rounded),
        title: Text(
          receipt.userName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(receipt.userEmail),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_full_rounded),
          onPressed: () => showBase64ImagePreview(
            context,
            data: receipt.receiptBase64,
          ),
        ),
      ),
    );
  }
}
