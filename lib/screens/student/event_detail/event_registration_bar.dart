part of '../event_detail_screen.dart';

class _EventRegistrationBar extends StatelessWidget {
  final EventModel event;
  final bool isRegistered;
  final String? registrationStatus;
  final VoidCallback onRegister;
  final VoidCallback onShare;

  const _EventRegistrationBar({
    required this.event,
    required this.isRegistered,
    required this.registrationStatus,
    required this.onRegister,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = registrationStatus == 'pending';
    final statusColor =
        isPending ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: isRegistered
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPending
                              ? Icons.hourglass_top_rounded
                              : Icons.check_circle_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPending ? 'Pending approval' : "You're registered!",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : FilledButton.icon(
                    onPressed: event.isFull ? null : onRegister,
                    icon: const Icon(
                      Icons.confirmation_number_rounded,
                      size: 20,
                    ),
                    label: Text(event.isFull ? 'Event Full' : 'Register Now'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            onPressed: onShare,
            icon: const Icon(Icons.send_rounded),
            tooltip: 'Share',
          ),
        ],
      ),
    );
  }
}
