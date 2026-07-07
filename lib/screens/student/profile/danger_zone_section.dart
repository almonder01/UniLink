part of '../profile_screen.dart';

class _DangerZoneSection extends StatelessWidget {
  final VoidCallback onDeleteAccount;
  final VoidCallback onLogout;

  const _DangerZoneSection({
    required this.onDeleteAccount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ProfileMenuTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete Account',
            color: Colors.red,
            onTap: onDeleteAccount,
          ),
          const Divider(height: 1, indent: 56),
          ProfileMenuTile(
            icon: Icons.logout_rounded,
            label: 'Logout',
            color: Colors.red,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
