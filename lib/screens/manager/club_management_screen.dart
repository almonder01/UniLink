import 'package:flutter/material.dart';
import '../../models/club.dart';
import '../../widgets/identity_avatar.dart';
import '../student/club_detail_screen.dart';
import 'club_payment_screen.dart';
import 'club_profile_tab.dart';
import 'events_tab.dart';
import 'members_tab.dart';
import 'posts_tab.dart';

class ClubManagementScreen extends StatefulWidget {
  final ClubModel club;
  const ClubManagementScreen({super.key, required this.club});

  @override
  State<ClubManagementScreen> createState() => _ClubManagementScreenState();
}

class _ClubManagementScreenState extends State<ClubManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late ClubModel _club;

  final _membersKey = GlobalKey<MembersTabState>();
  final _postsKey = GlobalKey<PostsTabState>();
  final _eventsKey = GlobalKey<EventsTabState>();

  int _memberCount = 0;
  int _postCount = 0;
  int _eventCount = 0;

  @override
  void initState() {
    super.initState();
    _club = widget.club;
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted && !_tabCtrl.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _openClubPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubDetailScreen(club: _club)),
    );
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (context, _) {
        switch (_tabCtrl.index) {
          case 0:
            return const SizedBox.shrink();

          case 1:
            return FloatingActionButton(
              onPressed: () => _membersKey.currentState?.showAddMemberDialog(),
              child: const Icon(Icons.person_add_rounded),
            );

          case 2:
            return FloatingActionButton.extended(
              onPressed: () => _postsKey.currentState?.createNewPost(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Post',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            );

          case 3:
            return FloatingActionButton.extended(
              onPressed: () => _eventsKey.currentState?.createNewEvent(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Event',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            );

          default:
            return FloatingActionButton.extended(
              onPressed: () => _eventsKey.currentState?.createNewEvent(),
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
    final colorHex =
        _club.logoColor.length == 8 ? _club.logoColor : 'FF${_club.logoColor}';
    final logoColor = Color(int.parse(colorHex, radix: 16));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Tooltip(
          message: 'View club page',
          child: InkWell(
            onTap: _openClubPreview,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  ClubAvatar(
                    color: logoColor,
                    logoBase64: _club.logoImageBase64,
                    showBackground: _club.showLogoBackground,
                    size: 36,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_club.name,
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
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Club payments',
            icon: const Icon(Icons.payments_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClubPaymentScreen(club: _club),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: [
            const Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.tune_rounded, size: 14),
                SizedBox(width: 4),
                Text('Profile'),
              ]),
            ),
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.people_rounded, size: 14),
                const SizedBox(width: 4),
                Text('Members ($_memberCount)'),
              ]),
            ),
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.chat_bubble_rounded, size: 14),
                const SizedBox(width: 4),
                Text('Posts ($_postCount)'),
              ]),
            ),
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.event_rounded, size: 14),
                const SizedBox(width: 4),
                Text('Events ($_eventCount)'),
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
          ClubProfileTab(
            club: _club,
            onChanged: (club) => setState(() => _club = club),
          ),
          MembersTab(
            key: _membersKey,
            club: _club,
            onCountChanged: (count) {
              if (mounted) setState(() => _memberCount = count);
            },
          ),
          PostsTab(
            key: _postsKey,
            club: _club,
            onCountChanged: (count) {
              if (mounted) setState(() => _postCount = count);
            },
          ),
          EventsTab(
            key: _eventsKey,
            club: _club,
            onCountChanged: (count) {
              if (mounted) setState(() => _eventCount = count);
            },
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }
}
