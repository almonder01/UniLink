part of '../event_dashboard_tab.dart';

class _EventSettingsSheetState extends State<_EventSettingsSheet> {
  final _emailCtrl = TextEditingController();
  bool _sendingFollowers = false;
  bool _sendingEmail = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _inviteFollowers() async {
    setState(() => _sendingFollowers = true);
    try {
      await NotificationService().sendEventInviteToFollowers(
        club: widget.club,
        eventId: widget.event.id,
        eventTitle: widget.event.title,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation sent to followers.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingFollowers = false);
    }
  }

  Future<void> _inviteEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _sendingEmail = true);
    try {
      await NotificationService().sendEventInviteByEmail(
        club: widget.club,
        eventId: widget.event.id,
        eventTitle: widget.event.title,
        email: email,
      );
      _emailCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Event Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              widget.event.title,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            DefaultTabController(
              length: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.payments_rounded), text: 'Payments'),
                      Tab(icon: Icon(Icons.send_rounded), text: 'Invites'),
                      Tab(icon: Icon(Icons.folder_copy_rounded), text: 'Docs'),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _EventPaymentsPanel(event: widget.event),
                        _EventInvitesPanel(
                          emailCtrl: _emailCtrl,
                          sendingFollowers: _sendingFollowers,
                          sendingEmail: _sendingEmail,
                          onInviteFollowers: _inviteFollowers,
                          onInviteEmail: _inviteEmail,
                        ),
                        _EventDocumentsPanel(event: widget.event),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
