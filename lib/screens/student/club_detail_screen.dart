import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/club.dart';
import '../../models/event.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_follow_provider.dart';
import '../../screens/chat/club_room_chat_screen.dart';
import '../../screens/chat/direct_chat_screen.dart';
import '../../screens/chat/share_to_chat_sheet.dart';
import '../../services/club_membership_service.dart';
import '../../services/club_room_service.dart';
import '../../services/database_service.dart';
import '../../services/direct_chat_service.dart';
import '../../services/event_service.dart';
import '../../services/membership_request_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/club_audio_player.dart';
import '../../widgets/direct_video_preview.dart';
import '../../widgets/event_card.dart';
import '../../widgets/identity_avatar.dart';
import '../../widgets/media_gallery.dart';
import '../../widgets/post_card.dart';
import '../../widgets/video_media_preview.dart';
import '../../widgets/youtube_video_preview.dart';
import 'event_detail_screen.dart';
import 'post_detail_screen.dart';
import 'widgets/event_registration_dialog.dart';

part 'club_detail/stat_item.dart';
part 'club_detail/stat_divider.dart';
part 'club_detail/tab_bar_delegate.dart';
part 'club_detail/about_tab.dart';
part 'club_detail/posts_tab.dart';
part 'club_detail/events_tab.dart';
part 'club_detail/people_tab.dart';
part 'club_detail/membership_request_banner.dart';
part 'club_detail/empty_tab_state.dart';
part 'club_detail/club_detail_header_slivers.dart';

class ClubDetailScreen extends StatefulWidget {
  final ClubModel club;
  const ClubDetailScreen({super.key, required this.club});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<PostModel> _posts = [];
  List<EventModel> _events = [];
  List<Map<String, dynamic>> _visibleMembers = [];
  List<Map<String, dynamic>> _visibleFollowers = [];
  int _followerCount = 0;
  bool _canUseRooms = false;
  bool _loadingData = true;
  bool _openedBackgroundPreview = false;
  String? _membershipRequestStatus;
  final _membershipService = ClubMembershipService();
  final _roomService = ClubRoomService();
  final _directChatService = DirectChatService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      final isManager = userId != null && userId == widget.club.managerId;
      final postsFuture = DatabaseService().getPostsByClub(widget.club.id);
      final eventsFuture =
          EventService().getEventsByClub(widget.club.id, userId: userId);
      final membersFuture = _loadVisibleMembers();
      final followersFuture = _membershipService.followerProfilesForClub(
        widget.club.id,
        publicOnly: false,
      );
      final isMemberFuture = userId == null || isManager
          ? Future.value(false)
          : _membershipService.isMember(widget.club.id, userId);

      final posts = await postsFuture;
      final events = await eventsFuture;
      final members = await membersFuture;
      final followers = await followersFuture;
      final isMember = await isMemberFuture;
      final visibleFollowers = followers
          .where((follower) => follower['showInClubFollowers'] != false)
          .toList();
      final canUseRooms = isManager || (userId != null && isMember);
      final membershipRequest = userId == null || canUseRooms
          ? null
          : await MembershipRequestService().getRequest(
              clubId: widget.club.id,
              userId: userId,
            );
      if (mounted) {
        setState(() {
          _posts = posts;
          _events = events;
          _visibleMembers = members;
          _visibleFollowers = visibleFollowers;
          _followerCount = followers.length;
          _canUseRooms = canUseRooms;
          _membershipRequestStatus = membershipRequest?.status;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load club details: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadVisibleMembers() async {
    return _membershipService.memberProfilesForClub(
      widget.club,
      publicOnly: true,
    );
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
        final index = _events.indexWhere((item) => item.id == event.id);
        if (index != -1) {
          _events[index] = event.copyWith(
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

  Future<void> _openDirectChat(Map<String, dynamic> person) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || person['uid'] == user.id) return;

    try {
      final chatId = await _directChatService.startChat(
        currentUser: user,
        target: person,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DirectChatScreen(
            chatId: chatId,
            title: person['name'] as String? ?? 'Chat',
            user: user,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

  Future<void> _requestMembership() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await MembershipRequestService().requestMembership(
      club: widget.club,
      user: user,
    );
    if (!mounted) return;
    setState(() => _membershipRequestStatus = 'pending');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membership request sent.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openRoomFull() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final room = await _roomService.ensureDefaultRoom(
      club: widget.club,
      createdBy: user.id,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubRoomChatScreen(
          room: room,
          club: widget.club,
          user: user,
        ),
      ),
    );
  }

  Future<void> _openRoomSheet() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final room = await _roomService.ensureDefaultRoom(
      club: widget.club,
      createdBy: user.id,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.72,
        child: ClubRoomChatPanel(
          room: room,
          club: widget.club,
          user: user,
          onOpenFull: () {
            Navigator.pop(sheetContext);
            _openRoomFull();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    final autoPlayClubMedia =
        context.watch<AuthProvider>().currentUser?.showClubBackgroundMedia ??
            true;
    final followProvider = context.watch<ClubFollowProvider>();
    final isFollowed = followProvider.isFollowing(userId, widget.club.id);
    final clubColor = Color(int.parse(widget.club.logoColor, radix: 16));
    if (autoPlayClubMedia &&
        widget.club.backgroundVideoAutoOpen &&
        !_openedBackgroundPreview &&
        (widget.club.backgroundVideoUrl ?? '').trim().isNotEmpty) {
      _openedBackgroundPreview = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final url = widget.club.backgroundVideoUrl!.trim();
        if (widget.club.backgroundVideoType == 'youtube' ||
            youtubeVideoIdFromUrl(url) != null) {
          showYouTubePreviewDialog(
            context,
            url: url,
            title: '${widget.club.name} background',
          );
        } else {
          showDirectVideoDialog(
            context,
            url: url,
            title: '${widget.club.name} background',
          );
        }
      });
    }
    final showAudioBar =
        (widget.club.backgroundMusicUrl ?? '').trim().isNotEmpty &&
            widget.club.backgroundMusicType != 'youtube';
    return Scaffold(
      floatingActionButton: _canUseRooms
          ? GestureDetector(
              onDoubleTap: _openRoomFull,
              child: FloatingActionButton(
                heroTag: 'club-room-${widget.club.id}',
                onPressed: _openRoomSheet,
                child: const Icon(Icons.forum_rounded),
              ),
            )
          : null,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (_, __) => _ClubDetailHeaderSlivers(
              club: widget.club,
              clubColor: clubColor,
              isFollowed: isFollowed,
              onFollow: () => followProvider.follow(userId, widget.club.id),
              onUnfollow: () => followProvider.unfollow(userId, widget.club.id),
              followerCount: _followerCount,
              postCount: _posts.length,
              eventCount: _events.length,
              tabCtrl: _tabCtrl,
            ).build(context),
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _AboutTab(
                  club: widget.club,
                  clubColor: clubColor,
                ),
                _PostsTab(posts: _posts, onShare: _sharePost),
                _EventsTab(
                  events: _events,
                  onRegister: _registerForEvent,
                  onShare: _shareEvent,
                ),
                _PeopleTab(
                  people: _visibleMembers,
                  emptyMessage: 'No public members yet',
                  onMessage: _openDirectChat,
                  header: _canUseRooms
                      ? null
                      : _MembershipRequestBanner(
                          status: _membershipRequestStatus,
                          onRequest: _requestMembership,
                        ),
                ),
                _PeopleTab(
                  people: _visibleFollowers,
                  emptyMessage: 'No public followers yet',
                  onMessage: _openDirectChat,
                ),
              ],
            ),
          ),
          if (_loadingData)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (showAudioBar)
            Positioned(
              left: 12,
              right: _canUseRooms ? 86 : 12,
              bottom: 10 + MediaQuery.paddingOf(context).bottom,
              child: ClubAudioPlayer(
                url: widget.club.backgroundMusicUrl!.trim(),
                title: '${widget.club.name} music',
                autoPlay:
                    autoPlayClubMedia && widget.club.backgroundMusicAutoPlay,
                compact: true,
              ),
            ),
        ],
      ),
    );
  }
}
