import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'club_tile.dart';

class ClubsTab extends StatelessWidget {
  final FirebaseFirestore db;
  final TextEditingController searchCtrl;
  final bool showBanner;
  final VoidCallback onDismissBanner;
  final VoidCallback onCreateClub;
  final void Function(Map<String, dynamic>) onAssign;
  final Future<void> Function(Map<String, dynamic>) onUnassign;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  const ClubsTab({
    super.key,
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
            // ── Header card ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary,
                    Color.lerp(cs.primary, Colors.purple, 0.5)!,
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
                      const Text(
                        'Academic Year',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        '2025 – 2026',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Xiamen University Malaysia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        '${clubs.length}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Clubs',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Warning banner ───────────────────────────────────────────────
            if (showBanner)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                  ),
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
                          color: const Color(0xFF92400E).withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
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

            // ── Search ───────────────────────────────────────────────────────
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search clubs or managers...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // ── List ─────────────────────────────────────────────────────────
            if (snap.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (clubs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.groups_rounded,
                          size: 48,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'No clubs yet. Tap + to create one.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...clubs.map(
                (club) => ClubTile(
                  club: club,
                  onAssign: () => onAssign(club),
                  onUnassign: () => onUnassign(club),
                  onDelete: () => onDelete(club),
                ),
              ),
          ],
        );
      },
    );
  }
}
