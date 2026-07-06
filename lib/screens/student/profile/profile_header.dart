part of '../profile_screen.dart';

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final Color coverColor;
  final Uint8List? coverBytes;
  final String? profilePhotoBase64;
  final bool hasProfilePhoto;
  final List<String> coverColors;
  final Color Function(String hex) colorFromHex;
  final VoidCallback onPickCoverPhoto;
  final VoidCallback onRemoveCoverPhoto;
  final VoidCallback onPickProfilePhoto;
  final VoidCallback onRemoveProfilePhoto;
  final ValueChanged<String> onCoverColorSelected;

  const _ProfileHeader({
    required this.user,
    required this.coverColor,
    required this.coverBytes,
    required this.profilePhotoBase64,
    required this.hasProfilePhoto,
    required this.coverColors,
    required this.colorFromHex,
    required this.onPickCoverPhoto,
    required this.onRemoveCoverPhoto,
    required this.onPickProfilePhoto,
    required this.onRemoveProfilePhoto,
    required this.onCoverColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoverPhoto = coverBytes != null;

    return Container(
      decoration: BoxDecoration(
        image: hasCoverPhoto
            ? DecorationImage(
                image: MemoryImage(coverBytes!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.32),
                  BlendMode.darken,
                ),
              )
            : null,
        gradient: LinearGradient(
          colors: [
            coverColor,
            Color.lerp(coverColor, const Color(0xFF111827), 0.35)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 24,
        20,
        28,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasCoverPhoto)
                IconButton.filledTonal(
                  onPressed: onRemoveCoverPhoto,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Remove cover',
                ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: onPickCoverPhoto,
                icon: const Icon(Icons.photo_camera_rounded),
                tooltip: 'Change cover',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onPickProfilePhoto,
                child: UserAvatar(
                  photoBase64: profilePhotoBase64,
                  gender: user.gender,
                  radius: 46,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  borderColor: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton.filled(
                    padding: EdgeInsets.zero,
                    onPressed: onPickProfilePhoto,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                  ),
                ),
              ),
              if (hasProfilePhoto)
                Positioned(
                  left: -2,
                  top: -2,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      onPressed: onRemoveProfilePhoto,
                      icon: const Icon(Icons.close_rounded, size: 15),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.studentId,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          if (!hasCoverPhoto) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final colorHex in coverColors)
                  _CoverColorDot(
                    color: colorFromHex(colorHex),
                    selected: user.coverColor == colorHex,
                    onTap: () => onCoverColorSelected(colorHex),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
