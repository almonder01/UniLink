import 'package:flutter/material.dart';

class MediaAssetNameDialog extends StatefulWidget {
  final String initialName;

  const MediaAssetNameDialog({
    super.key,
    required this.initialName,
  });

  @override
  State<MediaAssetNameDialog> createState() => _MediaAssetNameDialogState();
}

class _MediaAssetNameDialogState extends State<MediaAssetNameDialog> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename media'),
      content: TextField(
        controller: _nameCtrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Display name',
          prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, name);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
