part of '../club_payment_screen.dart';

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
