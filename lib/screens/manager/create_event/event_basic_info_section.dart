part of '../create_event_screen.dart';

class _EventBasicInfoSection extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;

  const _EventBasicInfoSection({
    required this.titleCtrl,
    required this.descCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        TextFormField(
          controller: titleCtrl,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            hintText: 'Event title...',
            border: InputBorder.none,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
        ),
        Divider(color: cs.onSurface.withValues(alpha: 0.1)),
        const SizedBox(height: 10),
        TextFormField(
          controller: descCtrl,
          maxLines: null,
          minLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 15, height: 1.65),
          decoration: InputDecoration(
            hintText: 'Describe this event...',
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (v) => (v == null || v.trim().length < 10)
              ? 'Please add a description (min 10 chars)'
              : null,
        ),
      ],
    );
  }
}
