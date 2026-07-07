import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/club.dart';
import '../../models/club_payment_receipt.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/club_payment_service.dart';
import '../../widgets/base64_image.dart';

part 'club_payment/monthly_payment_request_card.dart';
part 'club_payment/payment_stat_card.dart';
part 'club_payment/payment_stats_grid.dart';
part 'club_payment/receipt_tile.dart';

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
            _MonthlyPaymentRequestCard(
              amountCtrl: _amountCtrl,
              emailCtrl: _emailCtrl,
              messageCtrl: _messageCtrl,
              currency: _currency,
              sendingAll: _sendingAll,
              sendingOne: _sendingOne,
              onCurrencyChanged: (value) => setState(() => _currency = value),
              onSendAll: () => _sendAll(manager),
              onSendOne: () => _sendOne(manager),
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
