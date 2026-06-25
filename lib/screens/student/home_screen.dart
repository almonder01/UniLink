import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_follow_provider.dart';
import '../../providers/club_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/event_card.dart';
import '../../widgets/post_card.dart';
import '../../widgets/unilink_logo.dart';
import 'notifications_screen.dart';
import 'post_detail_screen.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PostModel> _dbPosts = [];
  List<EventModel> _dbEvents = [];
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final posts = await DatabaseService().getAllPosts();
    final snap = await FirebaseFirestore.instance.collection('events').get();
    final events = snap.docs.map((d) => EventModel.fromMap(d.data())).toList();
    events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    if (mounted) {
      setState(() {
        _dbPosts = posts;
        _dbEvents = events;
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    await _loadFeed();
    if (mounted) setState(() => _refreshing = false);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().currentUser;
    final followProvider = context.watch<ClubFollowProvider>();
    context.watch<ClubProvider>(); // rebuild when clubs load
    final hasUnread = context.watch<NotificationProvider>().unreadCount > 0;
    final userId = user?.id ?? '';
    final followedIds = followProvider.getFollowedIds(userId);
    final filteredPosts =
        _dbPosts.where((p) => followedIds.contains(p.clubId)).toList();
    final events =
        _dbEvents.where((e) => followedIds.contains(e.clubId)).toList();

    // // Interleave filtered posts + events from followed clubs into one feed
    // final List<dynamic> feed = [];
    // for (int i = 0; i < filteredPosts.length || i < events.length; i++) {
    //   if (i < filteredPosts.length) feed.add(filteredPosts[i]);
    //   if (i < events.length) feed.add(events[i]);
    // }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const UnilinkLogo(size: LogoSize.medium),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
              ),
              if (hasUnread)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            _GreetingCard(
              greeting: _greeting(),
              name: user?.name.split(' ').first ?? 'there',
              date: DateFormat('EEEE, MMMM d').format(DateTime.now()),
            ),

            // Events Section
            if (events.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];

                    return SizedBox(
                      width: 320,
                      child: EventCard(
                        event: event,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(event: event),
                          ),
                        ),
                        onRegister: () {
                          setState(
                            () => event.isRegistered = !event.isRegistered,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),

            Text(
              followedIds.isEmpty ? 'Discover clubs' : 'From your clubs',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            if (filteredPosts.isEmpty)
              _EmptyFeed()
            else
              ...filteredPosts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PostCard(
                    post: post,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: post),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String greeting;
  final String name;
  final String date;

  const _GreetingCard(
      {required this.greeting, required this.name, required this.date});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            Color.lerp(cs.primary, const Color(0xFF8B5CF6), 0.6)!
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $name!',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.dynamic_feed_rounded,
              size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Your feed is empty',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow some clubs to see their\nposts and events here',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
