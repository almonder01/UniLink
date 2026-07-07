part of '../club_payment_screen.dart';

class _MonthlyPaymentRequestCard extends StatelessWidget {
  final TextEditingController amountCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController messageCtrl;
  final String currency;
  final bool sendingAll;
  final bool sendingOne;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onSendAll;
  final VoidCallback onSendOne;

  const _MonthlyPaymentRequestCard({
    required this.amountCtrl,
    required this.emailCtrl,
    required this.messageCtrl,
    required this.currency,
    required this.sendingAll,
    required this.sendingOne,
    required this.onCurrencyChanged,
    required this.onSendAll,
    required this.onSendOne,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Payment Request',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 92,
                  child: DropdownButtonFormField<String>(
                    initialValue: currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: const [
                      DropdownMenuItem(value: 'RM', child: Text('RM')),
                      DropdownMenuItem(value: 'USD', child: Text(r'$')),
                    ],
                    onChanged: (value) {
                      if (value != null) onCurrencyChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageCtrl,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: sendingAll ? null : onSendAll,
              icon: sendingAll
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
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Send to one member by email',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: sendingOne ? null : onSendOne,
                  icon: sendingOne
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
