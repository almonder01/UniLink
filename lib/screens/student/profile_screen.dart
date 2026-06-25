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
import 'widgets/confirm_sheet.dart';
import 'widgets/followed_club_tile.dart';
import 'widgets/profile_widgets.dart';

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
      builder: (_) => const ConfirmSheet(
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
      builder: (_) => const ConfirmSheet(
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary,
                    Color.lerp(cs.primary, const Color(0xFF8B5CF6), 0.6)!,
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

          // ── Body ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Academic Info ─────────────────────────────────────────
                  const SectionLabel('Academic Info'),
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

                  // ── Following ─────────────────────────────────────────────
                  Row(
                    children: [
                      const SectionLabel('Following'),
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
                                    color:
                                        cs.onSurface.withValues(alpha: 0.3)),
                                const SizedBox(width: 12),
                                Text(
                                  'No clubs followed yet',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: cs.onSurface
                                          .withValues(alpha: 0.4)),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0;
                                  i < followedClubs.length;
                                  i++) ...[
                                if (i > 0)
                                  const Divider(height: 1, indent: 56),
                                FollowedClubTile(
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

                  // ── General ───────────────────────────────────────────────
                  const SectionLabel('General'),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        MenuTile(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen())),
                        ),
                        const Divider(height: 1, indent: 56),
                        MenuTile(
                          icon: Icons.info_outline_rounded,
                          label: 'About UniLink',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AboutScreen())),
                        ),
                        const Divider(height: 1, indent: 56),
                        MenuTile(
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

                  // ── Danger zone ───────────────────────────────────────────
                  Card(
                    child: Column(
                      children: [
                        MenuTile(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete Account',
                          color: Colors.red,
                          onTap: () => _deleteAccount(context),
                        ),
                        const Divider(height: 1, indent: 56),
                        MenuTile(
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
