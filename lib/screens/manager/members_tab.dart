import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/club.dart';
import '../../widgets/identity_avatar.dart';

class MembersTab extends StatefulWidget {
  final ClubModel club;
  final ValueChanged<int>? onCountChanged;

  const MembersTab({super.key, required this.club, this.onCountChanged});

  @override
  State<MembersTab> createState() => MembersTabState();
}

class MembersTabState extends State<MembersTab> {
  final _db = FirebaseFirestore.instance;

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
      final followsSnap = await _db
          .collection('user_follows')
          .where('club_ids', arrayContains: widget.club.id)
          .get();

      if (followsSnap.docs.isEmpty) {
        if (mounted) setState(() => _members = []);
        _reportCount();
        return;
      }

      final uids = followsSnap.docs.map((d) => d.id).toList();
      final List<Map<String, dynamic>> members = [];

      const chunkSize = 10;
      for (var i = 0; i < uids.length; i += chunkSize) {
        final chunk = uids.sublist(i, (i + chunkSize).clamp(0, uids.length));
        final profilesSnap = await _db
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in profilesSnap.docs) {
          final d = doc.data();
          final isManager = doc.id == widget.club.managerId;
          members.add({
            'uid': doc.id,
            'name': d['name'] as String? ?? 'Unknown',
            'email': d['email'] as String? ?? '',
            'photoBase64': d['photo_base64'] as String? ?? '',
            'gender': d['gender'] as String? ?? 'male',
            'role': isManager ? 'Manager' : 'Member',
          });
        }
      }

      members.sort((a, b) {
        if (a['role'] == 'Manager') return -1;
        if (b['role'] == 'Manager') return 1;
        return (a['name'] as String).compareTo(b['name'] as String);
      });

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

    await _db.collection('user_follows').doc(uid).set(
      {
        'club_ids': FieldValue.arrayUnion([widget.club.id])
      },
      SetOptions(merge: true),
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
      await _db
          .collection('user_follows')
          .doc(member['uid'] as String)
          .update({
        'club_ids': FieldValue.arrayRemove([widget.club.id]),
      });

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('No members yet. Tap + to add one.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _members.length,
        itemBuilder: (_, i) {
          final m = _members[i];
          final isManager = m['role'] == 'Manager';
          return ListTile(
            leading: UserAvatar(
              photoBase64: m['photoBase64'] as String?,
              gender: m['gender'] as String?,
              radius: 20,
              backgroundColor: _avatarColor(m['name'] as String, i),
            ),
            title: Text(m['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(m['email'] as String),
            trailing: isManager
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('You',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.w700)),
                  )
                : IconButton(
                    icon: const Icon(Icons.person_remove_outlined,
                        color: Colors.red, size: 20),
                    onPressed: () => _removeMember(m),
                  ),
          );
        },
      ),
    );
  }
}
