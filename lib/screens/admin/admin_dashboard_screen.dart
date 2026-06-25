import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  // ── Clubs ──────────────────────────────────────────────────────────────────

  void _showCreateClubDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create New Club',
            style: TextStyle(fontWeight: FontWeight.w800)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Club Name',
                  prefixIcon: Icon(Icons.groups_rounded)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catCtrl,
              decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_rounded)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.description_rounded),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              final ref = _db.collection('clubs').doc();
              await ref.set({
                'id': ref.id,
                'name': nameCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'category': catCtrl.text.trim().isEmpty
                    ? 'General'
                    : catCtrl.text.trim(),
                'logo_color': 'FF6366F1',
                'member_count': 0,
                'manager_id': null,
                'manager_name': null,
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Club "${nameCtrl.text.trim()}" created!'),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAssignManagerDialog(Map<String, dynamic> club) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Assign Manager — ${club['name']}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
              child: const Text('Cancel')),
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
                  // Check if already managing a clube
              final existingClub = await _db
                  .collection('clubs')
                  .where('manager_id', isEqualTo: userDoc.id)
                  .limit(1)
                  .get();
              if (!mounted) return;
              if (existingClub.docs.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$userName is already managing ${existingClub.docs.first['name']}',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              // Update user role → manager
              await _db
                  .collection('profiles')
                  .doc(userDoc.id)
                  .update({'role': 'manager', 'managed_club_id': club['id']});
              // Update club
              await _db.collection('clubs').doc(club['id'] as String).update({
                'manager_id': userDoc.id,
                'manager_name': userName,
              });
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unassign Manager',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Remove ${club['manager_name']} from managing "${club['name']}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final managerId = club['manager_id'] as String?;
    if (managerId != null && managerId.isNotEmpty) {
      await _db
          .collection('profiles')
          .doc(managerId)
          .update({'role': 'student', 'managed_club_id': FieldValue.delete()});
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Club',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Permanently delete "${club['name']}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.collection('clubs').doc(club['id'] as String).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Club "${club['name']}" deleted'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove User',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove ${user['name']} from UniLink?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
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
    final cs = Theme.of(context).colorScheme;

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
          _ClubsTab(
            db: _db,
            searchCtrl: _searchCtrl,
            showBanner: _showBanner,
            onDismissBanner: () => setState(() => _showBanner = false),
            onCreateClub: _showCreateClubDialog,
            onAssign: _showAssignManagerDialog,
            onUnassign: _unassignManager,
            onDelete: _deleteClub,
          ),
          _UsersTab(
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

// ── Clubs Tab ────────────────────────────────────────────────────────────────

class _ClubsTab extends StatelessWidget {
  final FirebaseFirestore db;
  final TextEditingController searchCtrl;
  final bool showBanner;
  final VoidCallback onDismissBanner;
  final VoidCallback onCreateClub;
  final void Function(Map<String, dynamic>) onAssign;
  final Future<void> Function(Map<String, dynamic>) onUnassign;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  const _ClubsTab({
    required this.db,
    required this.searchCtrl,
    required this.showBanner,
    required this.onDismissBanner,
    required this.onCreateClub,
    required this.onAssign,
    required this.onUnassign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('clubs').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final q = searchCtrl.text.toLowerCase();
        final clubs = docs
            .map((d) => d.data() as Map<String, dynamic>)
            .where((c) =>
                q.isEmpty ||
                (c['name'] as String).toLowerCase().contains(q) ||
                ((c['manager_name'] as String?) ?? '')
                    .toLowerCase()
                    .contains(q))
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary,
                    Color.lerp(cs.primary, Colors.purple, 0.5)!
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Academic Year',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500)),
                      const Text('2025 – 2026',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      Text(
                        'Xiamen University Malaysia',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text('${clubs.length}',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const Text('Clubs',
                          style:
                              TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (showBanner)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Review and reassign club managers for the new academic year.',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                const Color(0xFF92400E).withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: Color(0xFF92400E)),
                      onPressed: onDismissBanner,
                    ),
                  ],
                ),
              ),
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search clubs or managers...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (snap.connectionState == ConnectionState.waiting)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator()))
            else if (clubs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.groups_rounded,
                          size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('No clubs yet. Tap + to create one.',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              )
            else
              ...clubs.map((club) => _ClubTile(
                    club: club,
                    onAssign: () => onAssign(club),
                    onUnassign: () => onUnassign(club),
                    onDelete: () => onDelete(club),
                  )),
          ],
        );
      },
    );
  }
}

class _ClubTile extends StatelessWidget {
  final Map<String, dynamic> club;
  final VoidCallback onAssign;
  final VoidCallback onUnassign;
  final VoidCallback onDelete;

  const _ClubTile({
    required this.club,
    required this.onAssign,
    required this.onUnassign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colorHex = (club['logo_color'] as String?) ?? 'FF6366F1';
    final logoColor = Color(int.parse(
        'FF$colorHex'.length > 8 ? colorHex : 'FF$colorHex',
        radix: 16));
    final name = club['name'] as String? ?? '?';
    final words = name.trim().split(' ');
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
    final managerName = club['manager_name'] as String?;
    final hasManager = managerName != null && managerName.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        logoColor,
                        Color.lerp(logoColor, Colors.black, 0.2)!
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          Icon(Icons.manage_accounts_rounded,
                              size: 12,
                              color: cs.onSurface.withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              hasManager ? managerName : 'No manager assigned',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: hasManager
                                      ? cs.onSurface.withValues(alpha: 0.6)
                                      : Colors.orange),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: logoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    (club['category'] as String?) ?? 'General',
                    style: TextStyle(
                        fontSize: 10,
                        color: logoColor,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete club',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onAssign,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_rounded, size: 14),
                        SizedBox(width: 5),
                        Text('Assign Manager'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasManager ? onUnassign : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                      foregroundColor: Colors.red,
                      side: BorderSide(
                          color: hasManager
                              ? Colors.red.withValues(alpha: 0.5)
                              : Colors.grey.withValues(alpha: 0.3)),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_remove_rounded, size: 14),
                        SizedBox(width: 5),
                        Text('Unassign'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Users Tab ────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  final FirebaseFirestore db;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  const _UsersTab({required this.db, required this.onDelete});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: widget.db.collection('profiles').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final q = _searchCtrl.text.toLowerCase();
        final users = docs
            .map((d) => d.data() as Map<String, dynamic>)
            .where((u) =>
                q.isEmpty ||
                (u['name'] as String? ?? '').toLowerCase().contains(q) ||
                (u['email'] as String? ?? '').toLowerCase().contains(q) ||
                (u['student_id'] as String? ?? '').toLowerCase().contains(q))
            .toList()
          ..sort((a, b) => (a['name'] as String? ?? '')
              .compareTo(b['name'] as String? ?? ''));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('${users.length} users',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Expanded(
              child: snap.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? Center(
                          child: Text('No users found.',
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.5))))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: users.length,
                          itemBuilder: (_, i) {
                            final u = users[i];
                            final role = u['role'] as String? ?? 'student';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _roleColor(role).withValues(alpha: 0.15),
                                  child: Text(
                                    ((u['name'] as String?) ?? '?')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                        color: _roleColor(role),
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                title: Text(
                                  (u['name'] as String?) ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${u['email'] ?? ''}  •  ID: ${u['student_id'] ?? '—'}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.55)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _RoleChip(role: role),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.red),
                                      onPressed: () => widget.onDelete(u),
                                      tooltip: 'Remove user',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFEF4444);
      case 'manager':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'admin': (const Color(0xFFEF4444), const Color(0xFFfef2f2)),
      'manager': (const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      'student': (const Color(0xFF6366F1), const Color(0xFFEEF2FF)),
    };
    final (fg, bg) = colors[role] ?? (Colors.grey, Colors.grey.shade100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(role,
          style:
              TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
