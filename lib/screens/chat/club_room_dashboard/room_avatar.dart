part of '../club_room_dashboard_screen.dart';

class _RoomAvatar extends StatelessWidget {
  final ClubRoom room;
  final double size;

  const _RoomAvatar({required this.room, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final image = room.imageBase64;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Container(
        width: size,
        height: size,
        color: cs.primary.withValues(alpha: 0.12),
        child: image == null || image.isEmpty
            ? Icon(Icons.forum_rounded, color: cs.primary, size: size * 0.42)
            : Base64Image(data: image),
      ),
    );
  }
}
