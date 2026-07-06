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
import '../../services/event_service.dart';
import '../../services/post_interaction_service.dart';
import '../../services/saved_post_service.dart';
import '../../widgets/event_card.dart';
import '../../widgets/post_comment_sheet.dart';
import '../../widgets/post_card.dart';
import '../../widgets/unilink_logo.dart';
import 'notifications_screen.dart';
import 'post_detail_screen.dart';
import 'event_detail_screen.dart';
import 'widgets/event_registration_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PostModel> _dbPosts = [];
  List<EventModel> _dbEvents = [];
  Set<String> _savedPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final posts = await DatabaseService().getAllPosts();
    final events = await EventService().getAllEvents(userId: userId);
    final savedIds = userId == null
        ? <String>{}
        : await SavedPostService().getSavedPostIds(userId);
    if (mounted) {
      setState(() {
        _dbPosts = posts;
        _dbEvents = events;
        _savedPostIds = savedIds;
      });
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    await _loadFeed();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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

  void _replacePost(PostModel updatedPost) {
    setState(() {
      final index = _dbPosts.indexWhere((post) => post.id == updatedPost.id);
      if (index != -1) _dbPosts[index] = updatedPost;
    });
  }

  void _incrementCommentCount(String postId) {
    setState(() {
      final index = _dbPosts.indexWhere((post) => post.id == postId);
      if (index == -1) return;
      final current = _dbPosts[index];
      _dbPosts[index] =
          current.copyWith(commentCount: current.commentCount + 1);
    });
  }

  Future<void> _toggleLike(PostModel post) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final wasLiked = post.likedUserIds.contains(user.id);
    final updatedLikedIds = [...post.likedUserIds];
    if (wasLiked) {
      updatedLikedIds.remove(user.id);
    } else {
      updatedLikedIds.add(user.id);
    }

    final nextLikeCount = post.likeCount + (wasLiked ? -1 : 1);
    final updatedPost = post.copyWith(
      likedUserIds: updatedLikedIds,
      likeCount: nextLikeCount < 0 ? 0 : nextLikeCount,
    );
    _replacePost(updatedPost);

    try {
      await PostInteractionService().toggleLike(
        postId: post.id,
        userId: user.id,
        currentlyLiked: wasLiked,
      );
    } catch (e) {
      if (!mounted) return;
      _replacePost(post);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Like failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showComments(PostModel post) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PostCommentSheet(
        post: post,
        user: user,
        onCommentAdded: () => _incrementCommentCount(post.id),
      ),
    );
    await _loadFeed();
  }

  Future<void> _toggleSaved(PostModel post) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final wasSaved = _savedPostIds.contains(post.id);
    setState(() {
      if (wasSaved) {
        _savedPostIds.remove(post.id);
      } else {
        _savedPostIds.add(post.id);
      }
    });

    try {
      await SavedPostService().toggleSaved(
        userId: user.id,
        postId: post.id,
        currentlySaved: wasSaved,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedPostIds.add(post.id);
        } else {
          _savedPostIds.remove(post.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openPostDetail(PostModel post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
      ),
    );
    if (mounted) await _loadFeed();
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final eventCardWidth = screenWidth < 360 ? screenWidth - 48 : 320.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final eventCarouselHeight = textScale > 1.1 ? 360.0 : 330.0;

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
                height: eventCarouselHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];

                    return SizedBox(
                      width: eventCardWidth,
                      child: EventCard(
                        event: event,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(event: event),
                          ),
                        ),
                        onRegister: () => _registerForEvent(event),
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
                    isLiked: post.likedUserIds.contains(userId),
                    isSaved: _savedPostIds.contains(post.id),
                    onLike: () => _toggleLike(post),
                    onComment: () => _showComments(post),
                    onSave: () => _toggleSaved(post),
                    onTap: () => _openPostDetail(post),
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
