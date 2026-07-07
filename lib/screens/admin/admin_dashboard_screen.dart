import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/confirm_action_dialog.dart';
import 'widgets/admin_club_form_dialog.dart';
import 'widgets/clubs_tab.dart';
import 'widgets/users_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Clubs dialogs ──────────────────────────────────────────────────────────

  Future<List<String>> _clubCategories() async {
    final snap = await _db.collection('clubs').get();
    final categories = snap.docs
        .map((doc) => (doc.data()['category'] as String? ?? '').trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories.isEmpty
        ? ['Academic', 'Arts', 'Environment', 'Music', 'Sports', 'Tech']
        : categories;
  }

  void _showCreateClubDialog() {
    _showClubFormDialog();
  }

  void _showEditClubDialog(Map<String, dynamic> club) {
    _showClubFormDialog(club: club);
  }

  Future<void> _showClubFormDialog({Map<String, dynamic>? club}) async {
    final isEditing = club != null;
    final categories = await _clubCategories();
    if (!mounted) return;

    final result = await showDialog<AdminClubFormResult>(
      context: context,
      builder: (_) => AdminClubFormDialog(
        club: club,
        categories: categories,
      ),
    );
    if (result == null) return;

    final data = {
      'name': result.name,
      'description': result.description,
      'category': result.category,
    };

    if (isEditing) {
      await _db.collection('clubs').doc(club['id'] as String).update(data);
    } else {
      final ref = _db.collection('clubs').doc();
      await ref.set({
        'id': ref.id,
        ...data,
        'logo_color': 'FF6366F1',
        'member_count': 0,
        'manager_id': null,
        'manager_name': null,
      });
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        isEditing
            ? 'Club "${result.name}" updated.'
            : 'Club "${result.name}" created!',
      ),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showAssignManagerDialog(Map<String, dynamic> club) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Assign Manager to  ${club['name']}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Student Email',
            prefixIcon: Icon(Icons.mail_outline_rounded),
            hintText: 'student@xmu.edu.my',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(context);

              // Find user by email
              final query = await _db
                  .collection('profiles')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
              if (!mounted) return;
              if (query.docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('No user found with that email.'),
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }

              final userDoc = query.docs.first;
              final userName =
                  userDoc['name'] as String? ?? email.split('@').first;

              // Check if already managing a club
              final existingClub = await _db
                  .collection('clubs')
                  .where('manager_id', isEqualTo: userDoc.id)
                  .limit(1)
                  .get();
              if (!mounted) return;
              if (existingClub.docs.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    '$userName is already managing ${existingClub.docs.first['name']}',
                  ),
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }

              // Check if THIS club already has a manager → unassign them first
              final currentManagerId = club['manager_id'] as String?;
              final currentManagerName = club['manager_name'] as String?;

              if (currentManagerId != null && currentManagerId.isNotEmpty) {
                if (!mounted) return;
                final confirmed = await showConfirmActionDialog(
                  context,
                  title: 'Replace Manager',
                  message: '"${club['name']}" is currently managed by '
                      '$currentManagerName. Replace them with $userName?',
                  confirmLabel: 'Replace',
                  icon: Icons.swap_horiz_rounded,
                  confirmColor: Colors.orange,
                );
                if (!confirmed) return;

                await _db.collection('profiles').doc(currentManagerId).update({
                  'role': 'student',
                  'managed_club_id': FieldValue.delete(),
                });
              }
              // Update user role → manager
              await _db.collection('profiles').doc(userDoc.id).update({
                'role': 'manager',
                'managed_club_id': club['id'],
              });
              // Update club
              await _db
                  .collection('clubs')
                  .doc(club['id'] as String)
                  .update({'manager_id': userDoc.id, 'manager_name': userName});
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text('$userName assigned as manager of ${club['name']}'),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _unassignManager(Map<String, dynamic> club) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Unassign Manager',
      message: 'Remove ${club['manager_name']} from managing '
          '"${club['name']}"?',
      confirmLabel: 'Unassign',
      icon: Icons.manage_accounts_rounded,
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    final managerId = club['manager_id'] as String?;
    if (managerId != null && managerId.isNotEmpty) {
      await _db.collection('profiles').doc(managerId).update({
        'role': 'student',
        'managed_club_id': FieldValue.delete(),
      });
    }
    await _db.collection('clubs').doc(club['id'] as String).update({
      'manager_id': FieldValue.delete(),
      'manager_name': FieldValue.delete(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Manager unassigned'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _deleteClub(Map<String, dynamic> club) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Delete Club',
      message: 'Permanently delete "${club['name']}"?',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    await _db.collection('clubs').doc(club['id'] as String).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Club "${club['name']}" deleted'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Users dialogs ──────────────────────────────────────────────────────────

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Remove User',
      message: 'Remove ${user['name']} from UniLink?',
      confirmLabel: 'Remove',
      icon: Icons.person_remove_alt_1_rounded,
      confirmColor: Colors.red,
    );
    if (!confirmed) return;

    await _db.collection('profiles').doc(user['id'] as String).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${user['name']} removed'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniLink Admin',
            style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.groups_rounded), text: 'Clubs'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ClubsTab(
            db: _db,
            searchCtrl: _searchCtrl,
            showBanner: _showBanner,
            onDismissBanner: () => setState(() => _showBanner = false),
            onCreateClub: _showCreateClubDialog,
            onAssign: _showAssignManagerDialog,
            onEdit: _showEditClubDialog,
            onUnassign: _unassignManager,
            onDelete: _deleteClub,
          ),
          UsersTab(
            db: _db,
            onDelete: _deleteUser,
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) => _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: _showCreateClubDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Club',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
