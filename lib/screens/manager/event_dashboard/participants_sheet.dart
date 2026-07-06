part of '../event_dashboard_tab.dart';

class _ParticipantsSheet extends StatefulWidget {
  final ClubModel club;
  final EventModel event;
  final Future<void> Function() onChanged;

  const _ParticipantsSheet({
    required this.club,
    required this.event,
    required this.onChanged,
  });

  @override
  State<_ParticipantsSheet> createState() => _ParticipantsSheetState();
}
