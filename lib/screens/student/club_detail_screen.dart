import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/club.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_follow_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/event_card.dart';
import '../../widgets/post_card.dart';
import 'event_detail_screen.dart';

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
    final posts = await DatabaseService().getPostsByClub(widget.club.id);
    final snap = await FirebaseFirestore.instance
        .collection('events')
        .where('clubId', isEqualTo: widget.club.id)
        .get();
    final events = snap.docs.map((d) => EventModel.fromMap(d.data())).toList();
    events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    if (mounted) {
      setState(() {
        _posts = posts;
        _events = events;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    final followProvider = context.watch<ClubFollowProvider>();
    final isFollowed = followProvider.isFollowing(userId, widget.club.id);
    final clubColor = Color(int.parse(widget.club.logoColor, radix: 16));
    final initials = widget.club.name.trim().split(' ').length >= 2
        ? '${widget.club.name.trim().split(' ')[0][0]}${widget.club.name.trim().split(' ')[1][0]}'
            .toUpperCase()
        : widget.club.name.substring(0, 2).toUpperCase();

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
                  children: [
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
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0.1)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
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
            _EventsTab(events: _events),
            _MembersTab(),
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
      itemBuilder: (_, i) => PostCard(post: posts[i]),
    );
  }
}

class _EventsTab extends StatelessWidget {
  final List<EventModel> events;
  const _EventsTab({required this.events});

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
        onRegister: () => events[i].isRegistered = !events[i].isRegistered,
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _EmptyTabState(
      icon: Icons.people_outline_rounded,
      message: 'No members yet',
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
