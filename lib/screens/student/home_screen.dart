import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_follow_provider.dart';
import '../../providers/club_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/club_membership_service.dart';
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
import 'club_detail_screen.dart';
import '../chat/share_to_chat_sheet.dart';
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
  Set<String> _memberClubIds = {};
  int _visiblePostCount = 10;
  int _visibleEventCount = 10;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final posts = await DatabaseService().getRecentPosts(limit: 60);
    final events = await EventService().getUpcomingEvents(
      userId: userId,
      limit: 60,
    );
    final memberClubIds = userId == null
        ? <String>{}
        : (await ClubMembershipService().memberClubIdsForUser(userId)).toSet();
    final savedIds = userId == null
        ? <String>{}
        : await SavedPostService().getSavedPostIds(userId);
    if (mounted) {
      setState(() {
        _dbPosts = posts;
        _dbEvents = events;
        _memberClubIds = memberClubIds;
        _savedPostIds = savedIds;
        _visiblePostCount = 10;
        _visibleEventCount = 10;
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
    if (event.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This event is full.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final submission = await showEventRegistrationDialog(
      context,
      event: event,
    );
    if (submission == null || !mounted) return;

    try {
      await EventService().registerForEvent(
        event: event,
        user: user,
        paymentReceiptBase64: submission.paymentReceiptBase64,
        requirementTextResponse: submission.requirementTextResponse,
        requirementFileBase64: submission.requirementFileBase64,
      );
      if (!mounted) return;
      final status =
          event.requiresPayment || event.hasRegistrationRequirement
              ? 'pending'
              : 'approved';
      setState(() {
        final index = _dbEvents.indexWhere((item) => item.id == event.id);
        if (index != -1) {
          _dbEvents[index] = event.copyWith(
            isRegistered: true,
            registrationStatus: status,
          );
        } else {
          event.isRegistered = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            event.requiresPayment
                    || event.hasRegistrationRequirement
                ? 'Registration submitted for approval.'
                : "You're registered!",
          ),
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

  Future<void> _sharePost(PostModel post) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await ShareToChatSheet.showPost(context, post: post, user: user);
  }

  Future<void> _shareEvent(EventModel event) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await ShareToChatSheet.showEvent(context, event: event, user: user);
  }

  void _openClub(String clubId) {
    final club = context.read<ClubProvider>().getById(clubId);
    if (club == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubDetailScreen(club: club)),
    );
  }

  int _priorityForClub(
    String clubId,
    Set<String> followedIds,
    String mode,
  ) {
    final isMember = _memberClubIds.contains(clubId);
    final isFollowed = followedIds.contains(clubId);
    if (mode == 'recent') return 0;
    if (mode == 'followed_first') {
      if (isFollowed) return 0;
      if (isMember) return 1;
      return 2;
    }
    if (isMember) return 0;
    if (isFollowed) return 1;
    return 2;
  }

  List<PostModel> _prioritizedPosts(
    Set<String> followedIds,
    String mode,
  ) {
    final visibleClubIds = {...followedIds, ..._memberClubIds};
    final posts =
        _dbPosts.where((post) => visibleClubIds.contains(post.clubId)).toList();
    posts.sort((a, b) {
      final priority = _priorityForClub(a.clubId, followedIds, mode)
          .compareTo(_priorityForClub(b.clubId, followedIds, mode));
      if (priority != 0) return priority;
      return b.createdAt.compareTo(a.createdAt);
    });
    return posts;
  }

  List<EventModel> _prioritizedEvents(
    Set<String> followedIds,
    String mode,
  ) {
    final visibleClubIds = {...followedIds, ..._memberClubIds};
    final events = _dbEvents
        .where((event) => visibleClubIds.contains(event.clubId))
        .toList();
    events.sort((a, b) {
      final priority = _priorityForClub(a.clubId, followedIds, mode)
          .compareTo(_priorityForClub(b.clubId, followedIds, mode));
      if (priority != 0) return priority;
      return a.eventDate.compareTo(b.eventDate);
    });
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().currentUser;
    final followProvider = context.watch<ClubFollowProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    context.watch<ClubProvider>(); // rebuild when clubs load
    final hasUnread = context.watch<NotificationProvider>().unreadCount > 0;
    final userId = user?.id ?? '';
    final followedIds = followProvider.getFollowedIds(userId);
    final filteredPosts =
        _prioritizedPosts(followedIds, themeProvider.postFeedPriority);
    final events =
        _prioritizedEvents(followedIds, themeProvider.eventFeedPriority);
    final shownPosts = filteredPosts.take(_visiblePostCount).toList();
    final shownEvents = events.take(_visibleEventCount).toList();
    final hasMorePosts = filteredPosts.length > shownPosts.length;
    final hasMoreEvents = events.length > shownEvents.length;
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
            if (shownEvents.isNotEmpty) ...[
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
                  itemCount: shownEvents.length + (hasMoreEvents ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == shownEvents.length) {
                      return _LoadMoreEventCard(
                        width: eventCardWidth,
                        onTap: () => setState(() {
                          _visibleEventCount += 10;
                        }),
                      );
                    }
                    final event = shownEvents[index];

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
                        onShare: () => _shareEvent(event),
                        onClubTap: () => _openClub(event.clubId),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),

            Text(
              followedIds.isEmpty && _memberClubIds.isEmpty
                  ? 'Discover clubs'
                  : 'From your clubs',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            if (shownPosts.isEmpty)
              _EmptyFeed()
            else
              ...[
                ...shownPosts.map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PostCard(
                      post: post,
                      isLiked: post.likedUserIds.contains(userId),
                      isSaved: _savedPostIds.contains(post.id),
                      onLike: () => _toggleLike(post),
                      onComment: () => _showComments(post),
                      onSave: () => _toggleSaved(post),
                      onShare: () => _sharePost(post),
                      onClubTap: () => _openClub(post.clubId),
                      onTap: () => _openPostDetail(post),
                    ),
                  ),
                ),
                if (hasMorePosts)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _visiblePostCount += 10;
                      }),
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Load more posts'),
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _LoadMoreEventCard extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const _LoadMoreEventCard({required this.width, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.expand_more_rounded, color: cs.primary, size: 30),
                const SizedBox(height: 8),
                Text(
                  'Load more events',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
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
