import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../widgets/app_search_field.dart';
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
part 'home/home_filter_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  _HomeContentFilter _contentFilter = _HomeContentFilter.all;
  _HomeDateFilter _dateFilter = _HomeDateFilter.anytime;
  _HomeMediaFilter _mediaFilter = _HomeMediaFilter.any;
  List<PostModel> _dbPosts = [];
  List<EventModel> _dbEvents = [];
  Set<String> _savedPostIds = {};
  Set<String> _memberClubIds = {};
  QueryDocumentSnapshot<Map<String, dynamic>>? _postCursor;
  QueryDocumentSnapshot<Map<String, dynamic>>? _eventCursor;
  bool _hasMorePosts = false;
  bool _hasMoreEvents = false;
  bool _loadingFeed = true;
  bool _loadingMorePosts = false;
  bool _loadingMoreEvents = false;

  static const _feedPageSize = 10;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _loadFeed();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() => _loadingFeed = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      final postsFuture = DatabaseService().getRecentPostsPage(
        limit: _feedPageSize,
      );
      final eventsFuture = EventService().getUpcomingEventsPage(
        userId: userId,
        limit: _feedPageSize,
      );
      final memberClubIdsFuture = userId == null
          ? Future.value(<String>{})
          : ClubMembershipService()
              .memberClubIdsForUser(userId)
              .then((ids) => ids.toSet());
      final savedIdsFuture = userId == null
          ? Future.value(<String>{})
          : SavedPostService().getSavedPostIds(userId);

      final posts = await postsFuture;
      final events = await eventsFuture;
      final memberClubIds = await memberClubIdsFuture;
      final savedIds = await savedIdsFuture;
      if (mounted) {
        setState(() {
          _dbPosts = posts.posts;
          _dbEvents = events.events;
          _postCursor = posts.cursor;
          _eventCursor = events.cursor;
          _hasMorePosts = posts.hasMore;
          _hasMoreEvents = events.hasMore;
          _memberClubIds = memberClubIds;
          _savedPostIds = savedIds;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load feed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingFeed = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMorePosts || !_hasMorePosts) return;
    setState(() => _loadingMorePosts = true);
    try {
      final page = await DatabaseService().getRecentPostsPage(
        limit: _feedPageSize,
        startAfter: _postCursor,
      );
      if (!mounted) return;
      setState(() {
        _dbPosts = [..._dbPosts, ...page.posts];
        _postCursor = page.cursor;
        _hasMorePosts = page.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load more posts: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingMorePosts = false);
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_loadingMoreEvents || !_hasMoreEvents) return;
    setState(() => _loadingMoreEvents = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      final page = await EventService().getUpcomingEventsPage(
        userId: userId,
        limit: _feedPageSize,
        startAfter: _eventCursor,
      );
      if (!mounted) return;
      setState(() {
        _dbEvents = [..._dbEvents, ...page.events];
        _eventCursor = page.cursor;
        _hasMoreEvents = page.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load more events: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingMoreEvents = false);
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

  bool _postMatchesSearch(PostModel post, String query) {
    if (query.isEmpty) return true;
    final searchable = [
      post.title,
      post.description,
      post.clubName,
      if ((post.youtubeUrl ?? '').trim().isNotEmpty) 'youtube video',
      if ((post.videoUrl ?? '').trim().isNotEmpty) 'video',
      if ((post.audioUrl ?? '').trim().isNotEmpty) 'music audio',
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }

  bool _eventMatchesSearch(EventModel event, String query) {
    if (query.isEmpty) return true;
    final searchable = [
      event.title,
      event.description,
      event.clubName,
      event.location,
      event.feeLabel,
      DateFormat('EEEE MMMM d yyyy h:mm a').format(event.eventDate),
      if (event.hasVideo) 'video',
      if (event.hasAudio) 'music audio',
      if (event.hasExternalForm) 'form',
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }

  bool _postMatchesFilters(PostModel post) {
    if (_contentFilter == _HomeContentFilter.events) return false;
    if (!_matchesDateFilter(post.createdAt)) return false;
    return switch (_mediaFilter) {
      _HomeMediaFilter.any => true,
      _HomeMediaFilter.video =>
        (post.youtubeUrl ?? '').trim().isNotEmpty ||
            (post.videoUrl ?? '').trim().isNotEmpty,
      _HomeMediaFilter.music => (post.audioUrl ?? '').trim().isNotEmpty,
    };
  }

  bool _eventMatchesFilters(EventModel event) {
    if (_contentFilter == _HomeContentFilter.posts) return false;
    if (!_matchesDateFilter(event.eventDate)) return false;
    return switch (_mediaFilter) {
      _HomeMediaFilter.any => true,
      _HomeMediaFilter.video => event.hasVideo,
      _HomeMediaFilter.music => event.hasAudio,
    };
  }

  bool _matchesDateFilter(DateTime date) {
    final now = DateTime.now();
    return switch (_dateFilter) {
      _HomeDateFilter.anytime => true,
      _HomeDateFilter.today => _isSameDay(date, now),
      _HomeDateFilter.thisWeek => _weekStart(date) == _weekStart(now),
      _HomeDateFilter.thisMonth =>
        date.year == now.year && date.month == now.month,
    };
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  void _clearHomeFilters() {
    setState(() {
      _contentFilter = _HomeContentFilter.all;
      _dateFilter = _HomeDateFilter.anytime;
      _mediaFilter = _HomeMediaFilter.any;
    });
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
    final searchQuery = _searchCtrl.text.trim().toLowerCase();
    final prioritizedPosts = prioritizer.posts(
      _dbPosts,
      followedIds,
      themeProvider.postFeedPriority,
    );
    final prioritizedEvents = prioritizer.events(
      _dbEvents,
      followedIds,
      themeProvider.eventFeedPriority,
    );
    final filteredPosts = prioritizedPosts
        .where((post) => _postMatchesSearch(post, searchQuery))
        .where(_postMatchesFilters)
        .toList();
    final events = prioritizedEvents
        .where((event) => _eventMatchesSearch(event, searchQuery))
        .where(_eventMatchesFilters)
        .toList();
    final hasActiveFilters = searchQuery.isNotEmpty ||
        _contentFilter != _HomeContentFilter.all ||
        _dateFilter != _HomeDateFilter.anytime ||
        _mediaFilter != _HomeMediaFilter.any;
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
            const SizedBox(height: 12),
            AppSearchField(
              controller: _searchCtrl,
              hintText: 'Search events or posts...',
            ),
            const SizedBox(height: 10),
            _HomeFilterBar(
              contentFilter: _contentFilter,
              dateFilter: _dateFilter,
              mediaFilter: _mediaFilter,
              hasActiveFilters: hasActiveFilters,
              onContentChanged: (value) =>
                  setState(() => _contentFilter = value),
              onDateChanged: (value) => setState(() => _dateFilter = value),
              onMediaChanged: (value) => setState(() => _mediaFilter = value),
              onClear: () {
                _searchCtrl.clear();
                _clearHomeFilters();
                FocusScope.of(context).unfocus();
              },
            ),

            _HomeEventsSection(
              events: events,
              hasMore: _hasMoreEvents,
              isLoadingMore: _loadingMoreEvents,
              isSearching: hasActiveFilters,
              cardWidth: eventCardWidth,
              carouselHeight: eventCarouselHeight,
              onLoadMore: _loadMoreEvents,
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
        

            if (!hasActiveFilters ||
                filteredPosts.isNotEmpty ||
                events.isEmpty ||
                _loadingFeed)
              _HomePostsSection(
                posts: filteredPosts,
                hasMore: _hasMorePosts,
                isLoadingMore: _loadingMorePosts,
                isInitialLoading: _loadingFeed,
                hasAnyClubContext:
                    followedIds.isNotEmpty || _memberClubIds.isNotEmpty,
                isSearching: hasActiveFilters,
                userId: userId,
                savedPostIds: _savedPostIds,
                onLoadMore: _loadMorePosts,
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
