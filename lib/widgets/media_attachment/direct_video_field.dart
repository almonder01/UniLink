part of '../media_attachment_fields.dart';

class _DirectVideoField extends StatelessWidget {
  final TextEditingController controller;
  final String? pendingName;
  final VoidCallback onPick;
  final String previewTitle;
  final bool compactPreview;

  const _DirectVideoField({
    super.key,
    required this.controller,
    required this.pendingName,
    required this.onPick,
    required this.previewTitle,
    required this.compactPreview,
  });

  @override
  Widget build(BuildContext context) {
    final url = controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Uploaded/direct video link',
            hintText: 'Upload below or paste video URL',
            prefixIcon: Icon(Icons.movie_creation_rounded),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty || pendingName != null || _isHttpUrl(text)) {
              return null;
            }
            return 'Enter a valid video link';
          },
        ),
        const SizedBox(height: 8),
        _PickFileButton(
          icon: Icons.upload_file_rounded,
          label: 'Choose video file',
          pendingName: pendingName,
          onPressed: onPick,
        ),
        if (url.isNotEmpty) ...[
          const SizedBox(height: 12),
          VideoMediaPreview(
            url: url,
            type: 'video',
            title: previewTitle,
            compact: compactPreview,
          ),
        ],
      ],
    );
  }
}
