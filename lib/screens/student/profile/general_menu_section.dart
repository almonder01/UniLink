part of '../profile_screen.dart';

class _GeneralMenuSection extends StatelessWidget {
  final UserModel user;

  const _GeneralMenuSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          StreamBuilder<int>(
            stream: DirectChatService().unreadTotalStream(user.id),
            builder: (context, snapshot) => ProfileMenuTile(
              icon: Icons.mark_chat_unread_rounded,
              label: 'Messages',
              showDot: (snapshot.data ?? 0) > 0,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DirectChatsScreen(user: user),
                ),
              ),
            ),
          ),
          const Divider(height: 1, indent: 56),
          ProfileMenuTile(
            icon: Icons.assignment_turned_in_rounded,
            label: 'My Requests',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
            ),
          ),
          const Divider(height: 1, indent: 56),
          ProfileMenuTile(
            icon: Icons.bookmark_rounded,
            label: 'Saved Posts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
            ),
          ),
          const Divider(height: 1, indent: 56),
          ProfileMenuTile(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const Divider(height: 1, indent: 56),
          ProfileMenuTile(
            icon: Icons.info_outline_rounded,
            label: 'About UniLink',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          const Divider(height: 1, indent: 56),
          ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
