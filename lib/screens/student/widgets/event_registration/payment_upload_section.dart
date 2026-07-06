part of '../event_registration_dialog.dart';

class _PaymentUploadSection extends StatelessWidget {
  final EventModel event;
  final String? receiptBase64;
  final VoidCallback onPickReceipt;

  const _PaymentUploadSection({
    required this.event,
    required this.receiptBase64,
    required this.onPickReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.payments_rounded,
                color: Color(0xFF14B8A6),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment required: ${event.feeLabel}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _RegistrationUploadBox(
          data: receiptBase64,
          icon: Icons.upload_file_rounded,
          label: 'Upload transfer receipt',
          onTap: onPickReceipt,
        ),
      ],
    );
  }
}
