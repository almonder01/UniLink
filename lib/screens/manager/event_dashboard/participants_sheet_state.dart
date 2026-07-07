part of '../event_dashboard_tab.dart';

class _ParticipantsSheetState extends State<_ParticipantsSheet> {
  late Future<List<EventRegistration>> _registrationsFuture;

  @override
  void initState() {
    super.initState();
    _registrationsFuture =
        EventService().getRegistrationsForEvent(widget.event.id);
  }

  Future<void> _setAttendance(
    EventRegistration registration,
    bool attended,
  ) async {
    await EventService().setAttendance(
      registration: registration,
      attended: attended,
    );
    await widget.onChanged();
    setState(() {
      _registrationsFuture =
          EventService().getRegistrationsForEvent(widget.event.id);
    });
  }

  Future<void> _changeStatus(
    EventRegistration registration,
    String status,
  ) async {
    final message = await showDialog<String>(
      context: context,
      builder: (_) => _RegistrationStatusDialog(
        title: _statusDialogTitle(status),
        subtitle: '${registration.userName} - ${registration.eventTitle}',
        initialMessage: _defaultStatusMessage(registration, status),
      ),
    );
    if (!mounted) return;
    if (message == null) return;

    await EventService().updateRegistrationStatus(
      registration: registration,
      status: status,
      message: message,
    );
    await widget.onChanged();
    setState(() {
      _registrationsFuture =
          EventService().getRegistrationsForEvent(widget.event.id);
    });
  }

  Future<void> _approvePending(List<EventRegistration> registrations) async {
    if (registrations.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve pending requests?'),
        content: Text('Approve ${registrations.length} registration request(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    for (final registration in registrations) {
      await EventService().updateRegistrationStatus(
        registration: registration,
        status: 'approved',
        message: 'Your registration for ${registration.eventTitle} has been approved.',
      );
    }
    await widget.onChanged();
    if (!mounted) return;
    setState(() {
      _registrationsFuture =
          EventService().getRegistrationsForEvent(widget.event.id);
    });
  }

  String _statusDialogTitle(String status) {
    return switch (status) {
      'approved' => 'Approve registration?',
      'rejected' => 'Reject registration?',
      'cancelled' => 'Cancel registration?',
      _ => 'Update registration?',
    };
  }

  String _defaultStatusMessage(
    EventRegistration registration,
    String status,
  ) {
    return switch (status) {
      'approved' =>
        'Your registration for ${registration.eventTitle} has been approved.',
      'rejected' =>
        'Your registration for ${registration.eventTitle} has been rejected.',
      'cancelled' =>
        'Your registration for ${registration.eventTitle} has been cancelled.',
      _ => 'Your registration for ${registration.eventTitle} was updated.',
    };
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EventSettingsSheet(
        club: widget.club,
        event: widget.event,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Participants and attendance',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Event settings',
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_rounded),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<EventRegistration>>(
                future: _registrationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final registrations =
                      snapshot.data ?? const <EventRegistration>[];
                  if (registrations.isEmpty) {
                    return const Center(child: Text('No registrations yet.'));
                  }
                  final pending = registrations
                      .where((registration) => registration.isPending)
                      .toList();
                  final approved = registrations
                      .where((registration) => registration.isApproved)
                      .toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                    children: [
                      _ParticipantSummaryCard(
                        approvedCount: approved.length,
                        pendingCount: pending.length,
                        onApprovePending: pending.isEmpty
                            ? null
                            : () => _approvePending(pending),
                      ),
                      if (pending.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const _SheetSectionLabel('Pending requests'),
                        const SizedBox(height: 8),
                        ...pending.map(
                          (registration) => _PendingRegistrationTile(
                            registration: registration,
                            onApprove: () =>
                                _changeStatus(registration, 'approved'),
                            onReject: () =>
                                _changeStatus(registration, 'rejected'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const _SheetSectionLabel('Attendance'),
                      const SizedBox(height: 8),
                      if (approved.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Text(
                              'No approved participants yet.',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        )
                      else
                        ...approved.map(
                          (registration) => _RegistrationManagerCard(
                            registration: registration,
                            onAttendanceChanged: (value) =>
                                _setAttendance(registration, value),
                            onApprove: null,
                            onReject: null,
                            onCancel: () =>
                                _changeStatus(registration, 'cancelled'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
