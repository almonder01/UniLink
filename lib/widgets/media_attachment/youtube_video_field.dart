part of '../media_attachment_fields.dart';

class _YouTubeVideoField extends StatelessWidget {
  final TextEditingController controller;
  final String previewTitle;
  final bool compactPreview;

  const _YouTubeVideoField({
    required this.controller,
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
            labelText: 'YouTube video link',
            hintText: 'https://youtu.be/...',
            prefixIcon: Icon(Icons.smart_display_rounded),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty || youtubeVideoIdFromUrl(text) != null) {
              return null;
            }
            return 'Enter a valid YouTube link';
          },
        ),
        if (url.isNotEmpty && youtubeVideoIdFromUrl(url) != null) ...[
          const SizedBox(height: 12),
          YouTubeVideoPreview(
            url: url,
            title: previewTitle,
            compact: compactPreview,
          ),
        ],
      ],
    );
  }
}
