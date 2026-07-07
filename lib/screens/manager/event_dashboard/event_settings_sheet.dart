part of '../event_dashboard_tab.dart';

class _EventSettingsSheet extends StatefulWidget {
  final ClubModel club;
  final EventModel event;

  const _EventSettingsSheet({
    required this.club,
    required this.event,
  });

  @override
  State<_EventSettingsSheet> createState() => _EventSettingsSheetState();
}
