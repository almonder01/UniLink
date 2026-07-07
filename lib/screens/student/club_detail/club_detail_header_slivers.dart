part of '../club_detail_screen.dart';

class _ClubDetailHeaderSlivers {
  final ClubModel club;
  final Color clubColor;
  final bool isFollowed;
  final VoidCallback onFollow;
  final VoidCallback onUnfollow;
  final int followerCount;
  final int postCount;
  final int eventCount;
  final TabController tabCtrl;

  const _ClubDetailHeaderSlivers({
    required this.club,
    required this.clubColor,
    required this.isFollowed,
    required this.onFollow,
    required this.onUnfollow,
    required this.followerCount,
    required this.postCount,
    required this.eventCount,
    required this.tabCtrl,
  });

  List<Widget> build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return [
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
                  Color.lerp(clubColor, Colors.black, 0.45)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (club.imageBase64 != null && club.imageBase64!.isNotEmpty) ...[
                  Base64Image(data: club.imageBase64!),
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
                if (club.imageBase64 != null && club.imageBase64!.isNotEmpty)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showBase64ImagePreview(
                        context,
                        data: club.imageBase64!,
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
                          logoBase64: club.logoImageBase64,
                          showBackground: club.showLogoBackground,
                          size: 76,
                          borderRadius: 20,
                          onTap: club.logoImageBase64 == null ||
                                  club.logoImageBase64!.isEmpty
                              ? null
                              : () => showBase64ImagePreview(
                                    context,
                                    data: club.logoImageBase64!,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          club.name,
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
                    onPressed: onUnfollow,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Following'),
                  )
                : FilledButton(
                    onPressed: onFollow,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: clubColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Follow'),
                  ),
          ),
        ],
      ),
      SliverToBoxAdapter(
        child: Container(
          color: cs.surface,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(value: '$followerCount', label: 'Followers'),
              _Divider(),
              _StatItem(value: '$postCount', label: 'Posts'),
              _Divider(),
              _StatItem(value: '$eventCount', label: 'Events'),
            ],
          ),
        ),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: _TabBarDelegate(
          TabBar(
            controller: tabCtrl,
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
    ];
  }
}
