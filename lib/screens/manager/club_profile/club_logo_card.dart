part of '../club_profile_tab.dart';

class _ClubLogoCard extends StatelessWidget {
  final Color logoColor;
  final Uint8List? logoImage;
  final bool showLogoBackground;
  final String selectedLogoColor;
  final List<String> logoColors;
  final bool canEditLogo;
  final bool loading;
  final bool requesting;
  final DateTime? permissionExpiresAt;
  final bool showRequestButton;
  final VoidCallback onRequestEdit;
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
    required this.canEditLogo,
    required this.loading,
    required this.requesting,
    required this.permissionExpiresAt,
    required this.showRequestButton,
    required this.onRequestEdit,
    required this.onPickLogoImage,
    required this.onRemoveLogoImage,
    required this.onShowLogoBackgroundChanged,
    required this.onLogoColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expiresAt = permissionExpiresAt;
    final statusText = loading
        ? 'Checking edit permission...'
        : canEditLogo && expiresAt != null
            ? 'Logo image unlocked until ${TimeOfDay.fromDateTime(expiresAt).format(context)}'
            : 'Logo image changes need admin permission.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Club Logo',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (showRequestButton)
                  IconButton.filledTonal(
                    tooltip: 'Request edit permission',
                    onPressed: loading || requesting ? null : onRequestEdit,
                    icon: requesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.58),
              ),
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
                  onTap: logoImage == null && canEditLogo
                      ? onPickLogoImage
                      : logoImage != null
                          ? () => showBase64ImagePreview(
                                context,
                                data: base64Encode(logoImage!),
                              )
                          : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: canEditLogo ? onPickLogoImage : null,
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label:
                            Text(logoImage == null ? 'Add logo' : 'Change logo'),
                      ),
                      if (logoImage != null)
                        IconButton.filledTonal(
                          onPressed: canEditLogo ? onRemoveLogoImage : null,
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
              contentPadding: EdgeInsets.zero,
            ),
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
        ),
      ),
    );
  }
}
