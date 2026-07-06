import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/club.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_follow_provider.dart';
import '../../services/database_service.dart';
import '../../services/event_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/event_card.dart';
import '../../widgets/identity_avatar.dart';
import '../../widgets/media_gallery.dart';
import '../../widgets/post_card.dart';
import 'event_detail_screen.dart';
import 'post_detail_screen.dart';
import 'widgets/event_registration_dialog.dart';

class ClubDetailScreen extends StatefulWidget {
  final ClubModel club;
  const ClubDetailScreen({super.key, required this.club});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _posts = [];
  List<EventModel> _events = [];
  List<Map<String, dynamic>> _visibleMembers = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final posts = await DatabaseService().getPostsByClub(widget.club.id);
    final events =
        await EventService().getEventsByClub(widget.club.id, userId: userId);
    final members = await _loadVisibleMembers();
    if (mounted) {
      setState(() {
        _posts = posts;
        _events = events;
        _visibleMembers = members;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadVisibleMembers() async {
    final db = FirebaseFirestore.instance;
    final followsSnap = await db
        .collection('user_follows')
        .where('club_ids', arrayContains: widget.club.id)
        .get();
    if (followsSnap.docs.isEmpty) return [];

    final uids = followsSnap.docs.map((doc) => doc.id).toList();
    final members = <Map<String, dynamic>>[];
    const chunkSize = 10;
    for (var i = 0; i < uids.length; i += chunkSize) {
      final chunk = uids.sublist(i, (i + chunkSize).clamp(0, uids.length));
      final profilesSnap = await db
          .collection('profiles')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in profilesSnap.docs) {
        final data = doc.data();
        if (data['show_in_club_members'] == false) continue;
        members.add({
          'name': data['name'] as String? ?? 'Student',
          'email': data['email'] as String? ?? '',
          'major': data['major'] as String? ?? '',
          'gender': data['gender'] as String? ?? 'male',
          'photoBase64': data['photo_base64'] as String? ?? '',
        });
      }
    }
    members.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return members;
  }

  Future<void> _registerForEvent(EventModel event) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || event.isRegistered) return;

    final confirmed = await showEventRegistrationDialog(
      context,
      event: event,
    );
    if (!confirmed || !mounted) return;

    try {
      await EventService().registerForEvent(event: event, user: user);
      if (!mounted) return;
      setState(() => event.isRegistered = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're registered!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    final followProvider = context.watch<ClubFollowProvider>();
    final isFollowed = followProvider.isFollowing(userId, widget.club.id);
    final clubColor = Color(int.parse(widget.club.logoColor, radix: 16));
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: clubColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      clubColor,
                      Color.lerp(clubColor, Colors.black, 0.45)!
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.club.imageBase64 != null &&
                        widget.club.imageBase64!.isNotEmpty) ...[
                      Base64Image(data: widget.club.imageBase64!),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.black.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.1,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (widget.club.imageBase64 != null &&
                        widget.club.imageBase64!.isNotEmpty)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => showBase64ImagePreview(
                            context,
                            data: widget.club.imageBase64!,
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ClubAvatar(
                              color: clubColor,
                              logoBase64: widget.club.logoImageBase64,
                              showBackground: widget.club.showLogoBackground,
                              size: 76,
                              borderRadius: 20,
                              onTap: widget.club.logoImageBase64 == null ||
                                      widget.club.logoImageBase64!.isEmpty
                                  ? null
                                  : () => showBase64ImagePreview(
                                        context,
                                        data: widget.club.logoImageBase64!,
                                      ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.club.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: isFollowed
                    ? OutlinedButton(
                        onPressed: () =>
                            followProvider.unfollow(userId, widget.club.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side:
                              const BorderSide(color: Colors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Following'),
                      )
                    : FilledButton(
                        onPressed: () =>
                            followProvider.follow(userId, widget.club.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: clubColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Follow'),
                      ),
              ),
            ],
          ),
          // Stats bar
          SliverToBoxAdapter(
            child: Container(
              color: cs.surface,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                      value: '${widget.club.memberCount}', label: 'Members'),
                  _Divider(),
                  _StatItem(value: '${_posts.length}', label: 'Posts'),
                  _Divider(),
                  _StatItem(value: '${_events.length}', label: 'Events'),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Posts'),
                  Tab(text: 'Events'),
                  Tab(text: 'Members'),
                ],
                isScrollable: false,
                indicatorColor: cs.primary,
                labelColor: cs.primary,
                labelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _AboutTab(club: widget.club, clubColor: clubColor),
            _PostsTab(posts: _posts),
            _EventsTab(events: _events, onRegister: _registerForEvent),
            _MembersTab(members: _visibleMembers),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 32, width: 1, color: Colors.grey.withValues(alpha: 0.2));
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => 46;
  @override
  double get minExtent => 46;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _AboutTab extends StatelessWidget {
  final ClubModel club;
  final Color clubColor;
  const _AboutTab({required this.club, required this.clubColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (club.managerName != null) ...[
            Row(
              children: [
                Icon(Icons.manage_accounts_rounded,
                    size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  'Managed by ${club.managerName}',
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: clubColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              club.category,
              style: TextStyle(
                  fontSize: 12, color: clubColor, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'About',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            club.description,
            style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: cs.onSurface.withValues(alpha: 0.75)),
          ),
          if (club.galleryBase64List.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Photos',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            MediaGallery(images: club.galleryBase64List),
          ],
        ],
      ),
    );
  }
}

class _PostsTab extends StatelessWidget {
  final List<dynamic> posts;
  const _PostsTab({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyTabState(
          icon: Icons.chat_bubble_outline_rounded, message: 'No posts yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PostCard(
          post: posts[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: posts[i])),
          ),
        ),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  final List<EventModel> events;
  final ValueChanged<EventModel> onRegister;
  const _EventsTab({required this.events, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyTabState(
          icon: Icons.event_outlined, message: 'No events yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (_, i) => EventCard(
        event: events[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: events[i])),
        ),
        onRegister: () => onRegister(events[i]),
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final List<Map<String, dynamic>> members;

  const _MembersTab({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const _EmptyTabState(
        icon: Icons.people_outline_rounded,
        message: 'No public members yet',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: members.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final member = members[index];
        final name = member['name'] as String;
        final gender = member['gender'] as String;
        return ListTile(
          leading: UserAvatar(
            photoBase64: member['photoBase64'] as String?,
            gender: gender,
            radius: 20,
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            (member['major'] as String).isNotEmpty
                ? member['major'] as String
                : member['email'] as String,
          ),
          trailing: Icon(
            gender == 'female' ? Icons.female_rounded : Icons.male_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyTabState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
