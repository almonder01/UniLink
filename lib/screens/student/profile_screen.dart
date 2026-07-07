import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/club.dart';
import '../../models/user.dart';
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

part 'profile/cover_color_dot.dart';
part 'profile/danger_zone_section.dart';
part 'profile/editable_profile_field.dart';
part 'profile/gender_field_card.dart';
part 'profile/general_menu_section.dart';
part 'profile/member_clubs_section.dart';
part 'profile/profile_club_list.dart';
part 'profile/profile_header.dart';

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
    final hasProfilePhoto = (_profilePhotoBase64 ?? '').isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              user: user,
              coverColor: coverColor,
              coverBytes: coverBytes,
              profilePhotoBase64: _profilePhotoBase64,
              hasProfilePhoto: hasProfilePhoto,
              coverColors: _coverColors,
              colorFromHex: _colorFromHex,
              onPickCoverPhoto: _pickCoverPhoto,
              onRemoveCoverPhoto: _removeCoverPhoto,
              onPickProfilePhoto: _pickProfilePhoto,
              onRemoveProfilePhoto: _removeProfilePhoto,
              onCoverColorSelected: _setCoverColor,
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
                  _EditableProfileField(
                    icon: Icons.badge_rounded,
                    editing: _editingName,
                    controller: _nameCtrl,
                    displayText: user.name,
                    hintText: 'Enter your name',
                    onSubmit: () async {
                      await context
                          .read<AuthProvider>()
                          .updateProfile(name: _nameCtrl.text);
                      setState(() => _editingName = false);
                    },
                    onToggle: () async {
                      if (_editingName) {
                        await context
                            .read<AuthProvider>()
                            .updateProfile(name: _nameCtrl.text);
                      }
                      setState(() => _editingName = !_editingName);
                    },
                  ),
                  const SizedBox(height: 24),
        

                  const SectionLabel('Academic Info'),
                  const SizedBox(height: 10),
                  _EditableProfileField(
                    icon: Icons.school_rounded,
                    editing: _editingMajor,
                    controller: _majorCtrl,
                    displayText: user.major?.isNotEmpty == true
                        ? user.major!
                        : 'Tap to add major',
                    hintText: 'Enter your major',
                    displayColor: user.major?.isNotEmpty == true
                        ? cs.onSurface
                        : cs.onSurface.withValues(alpha: 0.4),
                    onSubmit: () async {
                      await context
                          .read<AuthProvider>()
                          .updateProfile(major: _majorCtrl.text);
                      setState(() => _editingMajor = false);
                    },
                    onToggle: () async {
                      if (_editingMajor) {
                        await context
                            .read<AuthProvider>()
                            .updateProfile(major: _majorCtrl.text);
                      }
                      setState(() => _editingMajor = !_editingMajor);
                    },
                  ),
                  const SizedBox(height: 10),
                  _GenderFieldCard(
                    gender: user.gender,
                    onChanged: (value) async {
                      await context
                          .read<AuthProvider>()
                          .updateProfile(gender: value);
                    },
                  ),
                  const SizedBox(height: 24),
        

                  _MemberClubsSection(
                    memberClubIdsFuture: memberClubIdsFuture,
                    allClubs: allClubs,
                    user: user,
                  ),
                  const SizedBox(height: 24),
        

                  _ProfileClubList(
                    title: 'Following',
                    clubs: followedClubs,
                    emptyIcon: Icons.groups_outlined,
                    emptyText: 'No clubs followed yet',
                  ),
                  const SizedBox(height: 24),
        

                  const SectionLabel('General'),
                  const SizedBox(height: 10),
                  _GeneralMenuSection(user: user),
                  const SizedBox(height: 14),
        

                  _DangerZoneSection(
                    onDeleteAccount: () => _deleteAccount(context),
                    onLogout: () => _logout(context),
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

