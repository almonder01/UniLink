part of '../event_dashboard_tab.dart';

class _EventInvitesPanel extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool sendingFollowers;
  final bool sendingEmail;
  final VoidCallback onInviteFollowers;
  final VoidCallback onInviteEmail;

  const _EventInvitesPanel({
    required this.emailCtrl,
    required this.sendingFollowers,
    required this.sendingEmail,
    required this.onInviteFollowers,
    required this.onInviteEmail,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
      children: [
        FilledButton.icon(
          onPressed: sendingFollowers ? null : onInviteFollowers,
          icon: sendingFollowers
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.notifications_active_rounded),
          label: const Text('Invite all followers'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Invite by email',
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            suffixIcon: IconButton(
              onPressed: sendingEmail ? null : onInviteEmail,
              icon: sendingEmail
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
          onSubmitted: (_) => onInviteEmail(),
        ),
      ],
    );
  }
}
