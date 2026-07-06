part of '../post_detail_screen.dart';

class _PostClubRow extends StatelessWidget {
  final PostModel post;
  final Color logoColor;
  final VoidCallback onTap;

  const _PostClubRow({
    required this.post,
    required this.logoColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          ClubAvatar(
            color: logoColor,
            logoBase64: post.clubLogoImageBase64,
            showBackground: post.clubShowLogoBackground,
            size: 40,
            borderRadius: 12,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.clubName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                DateFormat('EEEE, MMMM d, y').format(post.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
