import 'package:flutter/material.dart';
import '../../models/club.dart';
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

  final _membersKey = GlobalKey<MembersTabState>();
  final _postsKey = GlobalKey<PostsTabState>();
  final _eventsKey = GlobalKey<EventsTabState>();

  int _memberCount = 0;
  int _postCount = 0;
  int _eventCount = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted && !_tabCtrl.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (context, _) {
        switch (_tabCtrl.index) {
          case 0:
            return FloatingActionButton(
              onPressed: () => _membersKey.currentState?.showAddMemberDialog(),
              child: const Icon(Icons.person_add_rounded),
            );

          case 1:
            return FloatingActionButton.extended(
              onPressed: () => _postsKey.currentState?.createNewPost(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Post',
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
    final colorHex = widget.club.logoColor.length == 8
        ? widget.club.logoColor
        : 'FF${widget.club.logoColor}';
    final logoColor = Color(int.parse(colorHex, radix: 16));
    final initials = widget.club.name.trim().split(' ').length >= 2
        ? '${widget.club.name.trim().split(' ')[0][0]}${widget.club.name.trim().split(' ')[1][0]}'
            .toUpperCase()
        : widget.club.name.substring(0, 2).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    logoColor,
                    Color.lerp(logoColor, Colors.black, 0.2)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.club.name,
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
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.people_rounded, size: 14),
                const SizedBox(width: 4),
                Text('Members ($_memberCount)'),
              ]),
            ),
            Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.chat_bubble_rounded, size: 14),
                const SizedBox(width: 4),
                Text('Posts ($_postCount)'),
              ]),
            ),
            Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
          MembersTab(
            key: _membersKey,
            club: widget.club,
            onCountChanged: (count) {
              if (mounted) setState(() => _memberCount = count);
            },
          ),
          PostsTab(
            key: _postsKey,
            club: widget.club,
            onCountChanged: (count) {
              if (mounted) setState(() => _postCount = count);
            },
          ),
          EventsTab(
            key: _eventsKey,
            club: widget.club,
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