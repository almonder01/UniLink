import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_follow_provider.dart';
import '../../providers/club_provider.dart';
import '../../services/club_membership_service.dart';
import '../../services/direct_chat_service.dart';
import '../../widgets/identity_avatar.dart';
import '../chat/direct_chats_screen.dart';
import 'club_detail_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'support_screen.dart';
import 'saved_posts_screen.dart';
import 'my_requests_screen.dart';
import 'widgets/confirm_sheet.dart';
import 'widgets/followed_club_tile.dart';
import 'widgets/profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _editingName = false;
  bool _editingMajor = false;
  bool _mediaInitialized = false;
  String? _profilePhotoBase64;
  String? _coverPhotoBase64;

  static const _coverColors = [
    'FF6366F1',
    'FF14B8A6',
    'FFF97316',
    'FF22C55E',
    'FFA855F7',
    'FFEF4444',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && _nameCtrl.text.isEmpty) {
      _nameCtrl.text = user.name;
    }
    if (user != null && _majorCtrl.text.isEmpty) {
      _majorCtrl.text = user.major ?? '';
    }
    if (user != null && !_mediaInitialized) {
      _profilePhotoBase64 = user.photoBase64;
      _coverPhotoBase64 = user.coverImageBase64;
      _mediaInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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

  Color _colorFromHex(String hex) {
    final normalized = hex.length == 8 ? hex : 'FF$hex';
    return Color(int.parse(normalized, radix: 16));
  }

  Future<void> _pickProfilePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 700,
      imageQuality: 72,
    );
    if (file == null) return;
    final encoded = base64Encode(await file.readAsBytes());
    setState(() => _profilePhotoBase64 = encoded);
    if (!mounted) return;
    await context.read<AuthProvider>().updateProfile(photoBase64: encoded);
  }

  Future<void> _removeProfilePhoto() async {
    setState(() => _profilePhotoBase64 = '');
    await context.read<AuthProvider>().updateProfile(photoBase64: '');
  }

  Future<void> _pickCoverPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 70,
    );
    if (file == null) return;
    final encoded = base64Encode(await file.readAsBytes());
    setState(() => _coverPhotoBase64 = encoded);
    if (!mounted) return;
    await context.read<AuthProvider>().updateProfile(coverImageBase64: encoded);
  }

  Future<void> _removeCoverPhoto() async {
    setState(() => _coverPhotoBase64 = '');
    await context.read<AuthProvider>().updateProfile(coverImageBase64: '');
  }

  Future<void> _setCoverColor(String colorHex) async {
    await context.read<AuthProvider>().updateProfile(coverColor: colorHex);
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
    final memberClubIdsFuture =
        ClubMembershipService().memberClubIdsForUser(user.id);
    final coverColor = _colorFromHex(user.coverColor);
    final coverBytes = decodeBase64Image(_coverPhotoBase64);
    final hasCoverPhoto = coverBytes != null;
    final hasProfilePhoto = (_profilePhotoBase64 ?? '').isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                image: hasCoverPhoto
                    ? DecorationImage(
                        image: MemoryImage(coverBytes),
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
                  20, MediaQuery.of(context).padding.top + 24, 20, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasCoverPhoto)
                        IconButton.filledTonal(
                          onPressed: _removeCoverPhoto,
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: 'Remove cover',
                        ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        onPressed: _pickCoverPhoto,
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
                        onTap: _pickProfilePhoto,
                        child: UserAvatar(
                          photoBase64: _profilePhotoBase64,
                          gender: user.gender,
                          radius: 46,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.22),
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
                            onPressed: _pickProfilePhoto,
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
                              onPressed: _removeProfilePhoto,
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
                  if (!hasCoverPhoto) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final colorHex in _coverColors)
                          _CoverColorDot(
                            color: _colorFromHex(colorHex),
                            selected: user.coverColor == colorHex,
                            onTap: () => _setCoverColor(colorHex),
                          ),
                      ],
                    ),
                  ],
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
                  const SectionLabel('Personal Info'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      child: Row(
                        children: [
                          Icon(Icons.badge_rounded,
                              size: 20,
                              color: cs.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _editingName
                                ? TextField(
                                    controller: _nameCtrl,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your name',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      fillColor: Colors.transparent,
                                    ),
                                    onSubmitted: (_) async {
                                      await context
                                          .read<AuthProvider>()
                                          .updateProfile(name: _nameCtrl.text);
                                      setState(() => _editingName = false);
                                    },
                                  )
                                : Text(
                                    user.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                          ),
                          IconButton(
                            icon: Icon(
                              _editingName
                                  ? Icons.check_rounded
                                  : Icons.edit_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                            onPressed: () async {
                              if (_editingName) {
                                await context
                                    .read<AuthProvider>()
                                    .updateProfile(name: _nameCtrl.text);
                              }
                              setState(() => _editingName = !_editingName);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            user.gender == 'female' || user.gender == 'male'
                                ? user.gender
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.people_outline_rounded),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        items: [
                          DropdownMenuItem(
                            value: 'male',
                            child: Row(
                              children: [
                                Icon(Icons.male_rounded, color: cs.primary),
                                const SizedBox(width: 10),
                                const Text('Male'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Row(
                              children: [
                                Icon(Icons.female_rounded, color: cs.primary),
                                const SizedBox(width: 10),
                                const Text('Female'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          await context
                              .read<AuthProvider>()
                              .updateProfile(gender: value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Following ─────────────────────────────────────────────
                  FutureBuilder<List<String>>(
                    future: memberClubIdsFuture,
                    builder: (context, snapshot) {
                      final memberIds = snapshot.data?.toSet() ?? <String>{};
                      if ((user.managedClubId ?? '').isNotEmpty) {
                        memberIds.add(user.managedClubId!);
                      }
                      final memberClubs = allClubs
                          .where((club) => memberIds.contains(club.id))
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SectionLabel('Member Clubs'),
                              const SizedBox(width: 8),
                              if (memberClubs.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${memberClubs.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Card(
                            child: memberClubs.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24, horizontal: 16),
                                    child: Row(
                                      children: [
                                        Icon(Icons.badge_outlined,
                                            size: 22,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.3)),
                                        const SizedBox(width: 12),
                                        Text(
                                          snapshot.connectionState ==
                                                  ConnectionState.waiting
                                              ? 'Loading member clubs...'
                                              : 'No club memberships yet',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (int i = 0;
                                          i < memberClubs.length;
                                          i++) ...[
                                        if (i > 0)
                                          const Divider(height: 1, indent: 56),
                                        FollowedClubTile(
                                          club: memberClubs[i],
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ClubDetailScreen(
                                                  club: memberClubs[i]),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

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
                        StreamBuilder<int>(
                          stream: DirectChatService().unreadTotalStream(user.id),
                          builder: (context, snapshot) => MenuTile(
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
                        MenuTile(
                          icon: Icons.assignment_turned_in_rounded,
                          label: 'My Requests',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyRequestsScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
                        MenuTile(
                          icon: Icons.bookmark_rounded,
                          label: 'Saved Posts',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SavedPostsScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
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

class _CoverColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CoverColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? 0.95 : 0.45),
            width: selected ? 3 : 1.5,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
            : null,
      ),
    );
  }
}
