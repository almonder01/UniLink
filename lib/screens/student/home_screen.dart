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

part 'home/load_more_event_card.dart';
part 'home/greeting_card.dart';
part 'home/empty_feed.dart';
part 'home/home_events_section.dart';
part 'home/home_posts_section.dart';
part 'home/home_app_bar.dart';
part 'home/home_feed_prioritizer.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final followProvider = context.watch<ClubFollowProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    context.watch<ClubProvider>(); // rebuild when clubs load
    final hasUnread = context.watch<NotificationProvider>().unreadCount > 0;
    final userId = user?.id ?? '';
    final followedIds = followProvider.getFollowedIds(userId);
    final prioritizer = _HomeFeedPrioritizer(_memberClubIds);
    final filteredPosts = prioritizer.posts(
      _dbPosts,
      followedIds,
      themeProvider.postFeedPriority,
    );
    final events = prioritizer.events(
      _dbEvents,
      followedIds,
      themeProvider.eventFeedPriority,
    );
    final shownPosts = filteredPosts.take(_visiblePostCount).toList();
    final shownEvents = events.take(_visibleEventCount).toList();
    final hasMorePosts = filteredPosts.length > shownPosts.length;
    final hasMoreEvents = events.length > shownEvents.length;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final eventCardWidth = screenWidth < 360 ? screenWidth - 48 : 320.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final eventCarouselHeight = textScale > 1.1 ? 360.0 : 330.0;


    return Scaffold(
      appBar: _HomeAppBar(hasUnread: hasUnread),
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

            _HomeEventsSection(
              events: shownEvents,
              hasMore: hasMoreEvents,
              cardWidth: eventCardWidth,
              carouselHeight: eventCarouselHeight,
              onLoadMore: () => setState(() {
                _visibleEventCount += 10;
              }),
              onOpenEvent: (event) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(event: event),
                ),
              ),
              onRegister: _registerForEvent,
              onShare: _shareEvent,
              onClubTap: _openClub,
            ),
        

            _HomePostsSection(
              posts: shownPosts,
              hasMore: hasMorePosts,
              hasAnyClubContext:
                  followedIds.isNotEmpty || _memberClubIds.isNotEmpty,
              userId: userId,
              savedPostIds: _savedPostIds,
              onLoadMore: () => setState(() {
                _visiblePostCount += 10;
              }),
              onOpenPost: _openPostDetail,
              onLike: _toggleLike,
              onComment: _showComments,
              onSave: _toggleSaved,
              onShare: _sharePost,
              onClubTap: _openClub,
            ),
        
          ],
        ),
      ),
    );
  }
}
