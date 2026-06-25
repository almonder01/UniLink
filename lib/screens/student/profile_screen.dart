import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/club.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_follow_provider.dart';
import '../../providers/club_provider.dart';
import 'club_detail_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _majorCtrl = TextEditingController();
  bool _editingMajor = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && _majorCtrl.text.isEmpty) {
      _majorCtrl.text = user.major ?? '';
    }
  }

  @override
  void dispose() {
    _majorCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ConfirmSheet(
        title: 'Log out?',
        message: 'You will be returned to the login screen.',
        confirmLabel: 'Log out',
        confirmColor: Colors.red,
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ConfirmSheet(
        title: 'Delete Account?',
        message:
            'This action is permanent and cannot be undone. All your data will be erased.',
        confirmLabel: 'Delete Account',
        confirmColor: Colors.red,
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();
    final followProvider = context.watch<ClubFollowProvider>();
    final allClubs = context.watch<ClubProvider>().clubs;
    final followedIds = followProvider.getFollowedIds(user.id);
    final followedClubs =
        allClubs.where((c) => followedIds.contains(c.id)).toList();

    final initials = user.name.trim().split(' ').length >= 2
        ? '${user.name.trim().split(' ')[0][0]}${user.name.trim().split(' ')[1][0]}'
            .toUpperCase()
        : user.name.substring(0, 2).toUpperCase();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary,
                    Color.lerp(cs.primary, const Color(0xFF8B5CF6), 0.6)!
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 24, 20, 28),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2.5),
                        ),
                        child: Center(
                          child: Image.asset(
                            user.gender == 'female'
                                ? 'assets/images/female.png'
                                : 'assets/images/male.png',
                            width: 52,
                            height: 52,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.edit_rounded,
                              size: 14, color: cs.primary),
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
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.studentId,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Major field
                  const _SectionLabel('Academic Info'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      child: Row(
                        children: [
                          Icon(Icons.school_rounded,
                              size: 20,
                              color: cs.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _editingMajor
                                ? TextField(
                                    controller: _majorCtrl,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your major',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      fillColor: Colors.transparent,
                                    ),
                                    onSubmitted: (_) async {
                                      await context
                                          .read<AuthProvider>()
                                          .updateProfile(
                                              major: _majorCtrl.text);
                                      setState(() => _editingMajor = false);
                                    },
                                  )
                                : Text(
                                    user.major?.isNotEmpty == true
                                        ? user.major!
                                        : 'Tap to add major',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: user.major?.isNotEmpty == true
                                            ? cs.onSurface
                                            : cs.onSurface
                                                .withValues(alpha: 0.4)),
                                  ),
                          ),
                          IconButton(
                            icon: Icon(
                              _editingMajor
                                  ? Icons.check_rounded
                                  : Icons.edit_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                            onPressed: () async {
                              if (_editingMajor) {
                                await context
                                    .read<AuthProvider>()
                                    .updateProfile(major: _majorCtrl.text);
                              }
                              setState(() => _editingMajor = !_editingMajor);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const _SectionLabel('Following'),
                      const SizedBox(width: 8),
                      if (followedClubs.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${followedClubs.length}',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: followedClubs.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            child: Row(
                              children: [
                                Icon(Icons.groups_outlined,
                                    size: 22,
                                    color: cs.onSurface.withValues(alpha: 0.3)),
                                const SizedBox(width: 12),
                                Text(
                                  'No clubs followed yet',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.4)),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0;
                                  i < followedClubs.length;
                                  i++) ...[
                                if (i > 0) const Divider(height: 1, indent: 56),
                                _FollowedClubTile(
                                  club: followedClubs[i],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ClubDetailScreen(
                                          club: followedClubs[i]),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('General'),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen())),
                        ),
                        const Divider(height: 1, indent: 56),
                        _MenuTile(
                          icon: Icons.info_outline_rounded,
                          label: 'About UniLink',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AboutScreen())),
                        ),
                        const Divider(height: 1, indent: 56),
                        _MenuTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Support',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SupportScreen())),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete Account',
                          color: Colors.red,
                          onTap: () => _deleteAccount(context),
                        ),
                        const Divider(height: 1, indent: 56),
                        _MenuTile(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          color: Colors.red,
                          onTap: () => _logout(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _MenuTile(
      {required this.icon, required this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.onSurface;

    return ListTile(
      leading: Icon(icon, color: effectiveColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: effectiveColor),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: cs.onSurface.withValues(alpha: 0.3), size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _FollowedClubTile extends StatelessWidget {
  final ClubModel club;
  final VoidCallback onTap;

  const _FollowedClubTile({required this.club, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final logoColor = Color(int.parse(club.logoColor, radix: 16));
    final initials = club.name.trim().split(' ').length >= 2
        ? '${club.name.trim().split(' ')[0][0]}${club.name.trim().split(' ')[1][0]}'
            .toUpperCase()
        : club.name.substring(0, 2).toUpperCase();

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [logoColor, Color.lerp(logoColor, Colors.black, 0.25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      ),
      title: Text(
        club.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        club.category,
        style:
            TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: cs.onSurface.withValues(alpha: 0.3), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(backgroundColor: confirmColor),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
