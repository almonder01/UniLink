import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../widgets/identity_avatar.dart';
import 'role_chip.dart';

class UsersTab extends StatefulWidget {
  final FirebaseFirestore db;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  const UsersTab({
    super.key,
    required this.db,
    required this.onDelete,
  });

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
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
            // ── Search ───────────────────────────────────────────────────────
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
                  Text(
                    '${users.length} users',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: snap.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? Center(
                          child: Text(
                            'No users found.',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: users.length,
                          itemBuilder: (_, i) {
                            final u = users[i];
                            final role = u['role'] as String? ?? 'student';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: UserAvatar(
                                  photoBase64:
                                      u['photo_base64'] as String? ?? '',
                                  gender: u['gender'] as String? ?? 'male',
                                  radius: 20,
                                  backgroundColor:
                                      _roleColor(role).withValues(alpha: 0.15),
                                ),
                                title: Text(
                                  (u['name'] as String?) ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${u['email'] ?? ''}  •  ID: ${u['student_id'] ?? '—'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RoleChip(role: role),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Colors.red,
                                      ),
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
}
