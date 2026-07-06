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
  List<PostModel> _posts = [];
  List<EventModel> _events = [];
  List<Map<String, dynamic>> _visibleMembers = [];
  List<Map<String, dynamic>> _visibleFollowers = [];
  int _followerCount = 0;
  bool _canUseRooms = false;
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
    final userId = context.read<AuthProvider>().currentUser?.id;
    final posts = await DatabaseService().getPostsByClub(widget.club.id);
    final events =
        await EventService().getEventsByClub(widget.club.id, userId: userId);
    final members = await _loadVisibleMembers();
    final followers = await _membershipService.followerProfilesForClub(
      widget.club.id,
      publicOnly: false,
    );
    final visibleFollowers = followers
        .where((follower) => follower['showInClubFollowers'] != false)
        .toList();
    final isManager = userId != null && userId == widget.club.managerId;
    final canUseRooms = isManager ||
        (userId != null &&
            await _membershipService.isMember(widget.club.id, userId));
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
    final cs = Theme.of(context).colorScheme;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    final followProvider = context.watch<ClubFollowProvider>();
    final isFollowed = followProvider.isFollowing(userId, widget.club.id);
    final clubColor = Color(int.parse(widget.club.logoColor, radix: 16));
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
                      value: '$_followerCount',
                      label: 'Followers'),
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
                  Tab(text: 'Followers'),
                ],
                isScrollable: true,
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
    return ListView(
      padding: const EdgeInsets.all(20),
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
    );
  }
}

class _PostsTab extends StatelessWidget {
  final List<PostModel> posts;
  final ValueChanged<PostModel> onShare;
  const _PostsTab({required this.posts, required this.onShare});

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
          onShare: () => onShare(posts[i]),
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
  final ValueChanged<EventModel> onShare;
  const _EventsTab({
    required this.events,
    required this.onRegister,
    required this.onShare,
  });

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
        onShare: () => onShare(events[i]),
      ),
    );
  }
}

class _PeopleTab extends StatelessWidget {
  final List<Map<String, dynamic>> people;
  final String emptyMessage;
  final ValueChanged<Map<String, dynamic>> onMessage;
  final Widget? header;

  const _PeopleTab({
    required this.people,
    required this.emptyMessage,
    required this.onMessage,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (header != null) header!,
          SizedBox(
            height: 360,
            child: _EmptyTabState(
              icon: Icons.people_outline_rounded,
              message: emptyMessage,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: people.length + (header == null ? 0 : 1),
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        if (header != null && index == 0) return header!;
        final peopleIndex = header == null ? index : index - 1;
        final person = people[peopleIndex];
        final name = person['name'] as String;
        final gender = person['gender'] as String;
        final role = person['role'] as String?;
        return ListTile(
          leading: UserAvatar(
            photoBase64: person['photoBase64'] as String?,
            gender: gender,
            radius: 20,
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            role == 'Manager'
                ? 'Club manager'
                : (person['major'] as String).isNotEmpty
                    ? person['major'] as String
                    : person['email'] as String,
          ),
          trailing: IconButton(
            tooltip: 'Message',
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => onMessage(person),
          ),
        );
      },
    );
  }
}

class _MembershipRequestBanner extends StatelessWidget {
  final String? status;
  final VoidCallback onRequest;

  const _MembershipRequestBanner({
    required this.status,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = switch (status) {
      'pending' => 'Membership request pending',
      'payment_requested' => 'Payment requested by club manager',
      'approved' => 'Membership approved',
      'rejected' => 'Request rejected',
      _ => 'Request membership',
    };
    final canRequest = status == null || status == 'rejected';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(Icons.how_to_reg_rounded, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.tonal(
              onPressed: canRequest ? onRequest : null,
              child: Text(canRequest ? 'Request' : 'Sent'),
            ),
          ],
        ),
      ),
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
