part of '../club_profile_tab.dart';

class _ClubLogoCard extends StatelessWidget {
  final Color logoColor;
  final Uint8List? logoImage;
  final bool showLogoBackground;
  final String selectedLogoColor;
  final List<String> logoColors;
  final VoidCallback onPickLogoImage;
  final VoidCallback onRemoveLogoImage;
  final ValueChanged<bool> onShowLogoBackgroundChanged;
  final ValueChanged<String> onLogoColorChanged;

  const _ClubLogoCard({
    required this.logoColor,
    required this.logoImage,
    required this.showLogoBackground,
    required this.selectedLogoColor,
    required this.logoColors,
    required this.onPickLogoImage,
    required this.onRemoveLogoImage,
    required this.onShowLogoBackgroundChanged,
    required this.onLogoColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Club Logo',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ClubAvatar(
                  color: logoColor,
                  logoBase64:
                      logoImage == null ? null : base64Encode(logoImage!),
                  showBackground: showLogoBackground,
                  size: 72,
                  borderRadius: 18,
                  onTap: logoImage == null
                      ? onPickLogoImage
                      : () => showBase64ImagePreview(
                            context,
                            data: base64Encode(logoImage!),
                          ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: onPickLogoImage,
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label:
                            Text(logoImage == null ? 'Add logo' : 'Change logo'),
                      ),
                      if (logoImage != null)
                        IconButton.filledTonal(
                          onPressed: onRemoveLogoImage,
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: 'Remove logo',
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: showLogoBackground,
              onChanged: onShowLogoBackgroundChanged,
              title: const Text(
                'Show logo background',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Controls the colored shape behind the logo'),
              contentPadding: EdgeInsets.zero,
            ),
            if (showLogoBackground) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final colorHex in logoColors)
                    _LogoColorDot(
                      color: Color(int.parse(colorHex, radix: 16)),
                      selected: selectedLogoColor == colorHex,
                      onTap: () => onLogoColorChanged(colorHex),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
