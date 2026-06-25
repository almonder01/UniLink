import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/club.dart';
import '../../models/event.dart';
import '../../models/post.dart';
import '../../services/database_service.dart';
import '../../widgets/event_card.dart';
import '../../widgets/post_card.dart';
import '../student/event_detail_screen.dart';
import '../student/post_detail_screen.dart';
import 'create_event_screen.dart';
import 'create_post_screen.dart';

class ClubManagementScreen extends StatefulWidget {
  final ClubModel club;
  const ClubManagementScreen({super.key, required this.club});

  @override
  State<ClubManagementScreen> createState() => _ClubManagementScreenState();
}

class _ClubManagementScreenState extends State<ClubManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _members = [];
  bool _loadingMembers = false;

  List<PostModel> _posts = [];
  List<EventModel> _events = [];

  final _db = FirebaseFirestore.instance;

  bool _isAddingMember = false;
  final TextEditingController _emailCtrl = TextEditingController();
  int get _currentTab => _tabCtrl.index;

  @override
  void initState() {
    super.initState();

    _tabCtrl = TabController(length: 3, vsync: this);

    _tabCtrl.addListener(() {
      if (mounted && _tabCtrl.indexIsChanging == false) {
        setState(() {});
      }
    });

    _loadMembers();
    _loadPosts();
    _loadEvents();
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(() {});
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ─── Members ──────────────────────────────────────────────────────────────

  Future<void> _loadMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final followsSnap = await _db
          .collection('user_follows')
          .where('club_ids', arrayContains: widget.club.id)
          .get();

      if (followsSnap.docs.isEmpty) {
        if (mounted) setState(() => _members = []);
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

  void _addMemberDialog() {
    _emailCtrl.clear();

    showDialog(
      context: context,
      barrierDismissible: !_isAddingMember,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Member',
            style: TextStyle(fontWeight: FontWeight.w800)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            onPressed:
                _isAddingMember ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed:
                _isAddingMember ? null : () => _handleAddMember(dialogContext),
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
    ).whenComplete(() => _emailCtrl.clear());
  }

  Future<void> _handleAddMember(BuildContext dialogContext) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() => _isAddingMember = true);

    try {
      await _addMemberByEmail(email);
      if (!mounted) return;
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
      if (mounted) setState(() => _isAddingMember = false);
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
      await _db.collection('user_follows').doc(member['uid'] as String).update({
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

  // ─── Posts ────────────────────────────────────────────────────────────────

  Future<void> _loadPosts() async {
    final posts = await DatabaseService().getPostsByClub(widget.club.id);
    if (mounted) setState(() => _posts = posts);
  }

  Future<void> _deletePost(PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('This post will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await DatabaseService().deletePost(post.id);
    if (!mounted) return;
    setState(() => _posts.remove(post));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Post deleted'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _editPost(PostModel post) async {
    final result = await Navigator.push<PostModel>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          club: widget.club,
          existingPost: post,
        ),
      ),
    );
    if (result != null) _loadPosts();
  }

  // ─── Events ───────────────────────────────────────────────────────────────

  Future<void> _loadEvents() async {
    final snap = await _db
        .collection('events')
        .where('clubId', isEqualTo: widget.club.id)
        .get();
    final events = snap.docs.map((d) => EventModel.fromMap(d.data())).toList();
    events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    if (mounted) setState(() => _events = events);
  }

  Future<void> _deleteEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('This event will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _db.collection('events').doc(event.id).delete();
      if (!mounted) return;
      setState(() => _events.remove(event));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Event deleted'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error deleting event: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _editEvent(EventModel event) async {
    final result = await Navigator.push<EventModel>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(
          club: widget.club,
          existingEvent: event,
        ),
      ),
    );
    if (result != null) _loadEvents();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _showPostMenu(BuildContext context, PostModel post) {
    showMenu<String>(
      context: context,
      position: _menuPosition(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: const [
        PopupMenuItem(
            value: 'edit', child: _MenuTile(Icons.edit_outlined, 'Edit')),
        PopupMenuItem(
            value: 'delete',
            child: _MenuTile(Icons.delete_outline_rounded, 'Delete',
                color: Colors.red)),
      ],
    ).then((val) {
      if (val == 'edit') _editPost(post);
      if (val == 'delete') _deletePost(post);
    });
  }

  void _showEventMenu(BuildContext context, EventModel event) {
    showMenu<String>(
      context: context,
      position: _menuPosition(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: const [
        PopupMenuItem(
            value: 'edit', child: _MenuTile(Icons.edit_outlined, 'Edit')),
        PopupMenuItem(
            value: 'delete',
            child: _MenuTile(Icons.delete_outline_rounded, 'Delete',
                color: Colors.red)),
      ],
    ).then((val) {
      if (val == 'edit') _editEvent(event);
      if (val == 'delete') _deleteEvent(event);
    });
  }

  RelativeRect _menuPosition(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return RelativeRect.fromLTRB(size.width - 160, 100, 16, 0);
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (context, _) {
        switch (_tabCtrl.index) {
          case 0:
            return FloatingActionButton(
              onPressed: _addMemberDialog,
              child: const Icon(Icons.person_add_rounded),
            );

          case 1:
            return FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<PostModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(club: widget.club),
                  ),
                );
                if (result != null) _loadPosts();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Post',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            );

          default:
            return FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateEventScreen(club: widget.club),
                  ),
                );
                _loadEvents();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Event',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            );
        }
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colorHex = widget.club.logoColor.length == 8
        ? widget.club.logoColor
        : 'FF${widget.club.logoColor}';
    final logoColor = Color(int.parse(colorHex, radix: 16));
    final initials = widget.club.name.trim().split(' ').length >= 2
        ? '${widget.club.name.trim().split(' ')[0][0]}${widget.club.name.trim().split(' ')[1][0]}'
            .toUpperCase()
        : widget.club.name.substring(0, 2).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    logoColor,
                    Color.lerp(logoColor, Colors.black, 0.2)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.club.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                  Text('Club Management',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.people_rounded, size: 14),
                const SizedBox(width: 4),
                Text('Members (${_members.length})'),
              ]),
            ),
            Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.chat_bubble_rounded, size: 14),
                const SizedBox(width: 4),
                Text('Posts (${_posts.length})'),
              ]),
            ),
            Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.event_rounded, size: 14),
                const SizedBox(width: 4),
                Text('Events (${_events.length})'),
              ]),
            ),
          ],
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Members Tab ──────────────────────────────────────────────────
          _loadingMembers
              ? const Center(child: CircularProgressIndicator())
              : _members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48,
                              color: cs.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text('No members yet. Tap + to add one.',
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.4))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMembers,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _members.length,
                        itemBuilder: (_, i) {
                          final m = _members[i];
                          final isManager = m['role'] == 'Manager';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _avatarColor(m['name'] as String, i),
                              child: Text(
                                _initials(m['name'] as String),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                            title: Text(m['name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
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
                                    icon: const Icon(
                                        Icons.person_remove_outlined,
                                        color: Colors.red,
                                        size: 20),
                                    onPressed: () => _removeMember(m),
                                  ),
                          );
                        },
                      ),
                    ),

          // ── Posts Tab ────────────────────────────────────────────────────
          _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text('No posts yet. Tap + to create one.',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _posts.length,
                  itemBuilder: (ctx, i) {
                    final post = _posts[i];
                    return Stack(
                      children: [
                        PostCard(
                          post: post,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: post),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: _ThreeDotButton(
                            onTap: () => _showPostMenu(ctx, post),
                          ),
                        ),
                      ],
                    );
                  },
                ),

          // ── Events Tab ───────────────────────────────────────────────────
          _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_outlined,
                          size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text('No events yet. Tap + to create one.',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (ctx, i) {
                    final event = _events[i];
                    return Stack(
                      children: [
                        EventCard(
                          event: event,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(event: event),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: _ThreeDotButton(
                            onTap: () => _showEventMenu(ctx, event),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }
}

class _ThreeDotButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ThreeDotButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.more_vert_rounded,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuTile(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
