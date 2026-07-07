import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/club.dart';
import '../../providers/auth_provider.dart';
import '../../screens/chat/direct_chat_screen.dart';
import '../../services/club_membership_service.dart';
import '../../services/direct_chat_service.dart';
import '../../widgets/identity_avatar.dart';
import 'manager_action_banner.dart';
import 'membership_requests_screen.dart';

part 'members/empty_members_state.dart';
part 'members/member_tile.dart';
part 'members/members_header.dart';

class MembersTab extends StatefulWidget {
  final ClubModel club;
  final ValueChanged<int>? onCountChanged;

  const MembersTab({super.key, required this.club, this.onCountChanged});

  @override
  State<MembersTab> createState() => MembersTabState();
}

class MembersTabState extends State<MembersTab> {
  final _db = FirebaseFirestore.instance;
  final _membershipService = ClubMembershipService();
  final _directChatService = DirectChatService();

  List<Map<String, dynamic>> _members = [];
  bool _loadingMembers = false;
  bool _isAddingMember = false;
  final TextEditingController _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _reportCount() {
    widget.onCountChanged?.call(_members.length);
  }

  Future<void> _loadMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final members = await _membershipService.memberProfilesForClub(
        widget.club,
        publicOnly: false,
      );
      if (mounted) setState(() => _members = members);
      _reportCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load members: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  void showAddMemberDialog() {
    _emailCtrl.clear();

    showDialog(
      context: context,
      barrierDismissible: !_isAddingMember,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add Member',
              style: TextStyle(fontWeight: FontWeight.w800)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Student Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isAddingMember
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isAddingMember
                  ? null
                  : () => _handleAddMember(dialogContext, setDialogState),
              child: _isAddingMember
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _emailCtrl.clear());
  }

  Future<void> _handleAddMember(
      BuildContext dialogContext, void Function(void Function()) setDialogState) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() => _isAddingMember = true);
    setDialogState(() {});

    try {
      await _addMemberByEmail(email);
      if (!mounted || !dialogContext.mounted) return;
      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$email added successfully!'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted && dialogContext.mounted) {
        setState(() => _isAddingMember = false);
        setDialogState(() {});
      }
    }
  }

  Future<void> _addMemberByEmail(String email) async {
    final currentUserId =
        context.read<AuthProvider>().currentUser?.id ?? widget.club.managerId ?? '';
    final profileSnap = await _db
        .collection('profiles')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (profileSnap.docs.isEmpty) {
      throw Exception('No student found with that email.');
    }

    final profileDoc = profileSnap.docs.first;
    final uid = profileDoc.id;

    if (_members.any((m) => m['uid'] == uid)) {
      throw Exception('This student is already a member.');
    }

    await _membershipService.addMember(
      club: widget.club,
      profileDoc: profileDoc,
      addedBy: currentUserId,
    );

    await _loadMembers();
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    if (member['uid'] == widget.club.managerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Club manager cannot be removed.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member['name']} from ${widget.club.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _membershipService.removeMember(
        clubId: widget.club.id,
        userId: member['uid'] as String,
      );

      await _loadMembers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${member['name']} removed.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error removing member: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Color _avatarColor(String name, int index) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF3B82F6),
      Color(0xFFA855F7),
    ];
    return colors[index % colors.length];
  }

  Future<void> _openDirectChat(Map<String, dynamic> member) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || member['uid'] == user.id) return;

    try {
      final chatId = await _directChatService.startChat(
        currentUser: user,
        target: member,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DirectChatScreen(
            chatId: chatId,
            title: member['name'] as String? ?? 'Chat',
            user: user,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return Column(
        children: [
          _MembersHeader(club: widget.club),
          const Expanded(child: _EmptyMembersState()),
        ],
      );
    }

    return Column(
      children: [
        _MembersHeader(club: widget.club),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMembers,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _members.length,
              itemBuilder: (_, i) {
                final m = _members[i];
                final isManager = m['role'] == 'Manager';
                final currentUserId = context.read<AuthProvider>().currentUser?.id;
                return _MemberTile(
                  member: m,
                  avatarColor: _avatarColor(m['name'] as String, i),
                  isManager: isManager,
                  canMessage: m['uid'] != currentUserId,
                  onMessage: () => _openDirectChat(m),
                  onRemove: () => _removeMember(m),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
