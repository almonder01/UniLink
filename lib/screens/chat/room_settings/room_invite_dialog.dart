part of '../club_room_settings_screen.dart';

class _RoomInviteDialog extends StatefulWidget {
  final String roomName;

  const _RoomInviteDialog({required this.roomName});

  @override
  State<_RoomInviteDialog> createState() => _RoomInviteDialogState();
}

class _RoomInviteDialogState extends State<_RoomInviteDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Invite to ${widget.roomName}'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'Student email',
          prefixIcon: Icon(Icons.mail_outline_rounded),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Send Invite'),
        ),
      ],
    );
  }
}
