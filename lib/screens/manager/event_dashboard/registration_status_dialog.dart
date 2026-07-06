part of '../event_dashboard_tab.dart';

class _RegistrationStatusDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String initialMessage;

  const _RegistrationStatusDialog({
    required this.title,
    required this.subtitle,
    required this.initialMessage,
  });

  @override
  State<_RegistrationStatusDialog> createState() =>
      _RegistrationStatusDialogState();
}
