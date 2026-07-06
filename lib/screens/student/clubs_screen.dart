import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/club.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_follow_provider.dart';
import '../../providers/club_provider.dart';
import '../../widgets/club_card.dart';
import 'club_detail_screen.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  static const _categories = [
    'All',
    'Tech',
    'Sports',
    'Arts',
    'Academic',
    'Environment',
    'Music'
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<ClubFollowProvider>().loadFollowsIfNeeded(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClubModel> _filtered(List<ClubModel> clubs) {
    final query = _searchCtrl.text.toLowerCase();
    return clubs.where((c) {
      final matchCat =
          _selectedCategory == 'All' || c.category == _selectedCategory;
      final matchSearch = query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query);
      return matchCat && matchSearch;
    }).toList();
  }

  void _toggleFollow(ClubModel club, String userId) {
    final provider = context.read<ClubFollowProvider>();
    if (provider.isFollowing(userId, club.id)) {
      provider.unfollow(userId, club.id);
    } else {
      provider.follow(userId, club.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    final followProvider = context.watch<ClubFollowProvider>();
    final clubProvider = context.watch<ClubProvider>();
    final filtered = _filtered(clubProvider.clubs);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover Clubs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search clubs...',
              leading: const Icon(Icons.search_rounded),
              trailing: _searchCtrl.text.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ]
                  : null,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: cs.primary.withValues(alpha: 0.15),
                  checkmarkColor: cs.primary,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.65),
                  ),
                  side: BorderSide(
                    color: selected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: clubProvider.loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 52,
                                color: cs.onSurface.withValues(alpha: 0.25)),
                            const SizedBox(height: 12),
                            Text(
                              'No clubs found',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withValues(alpha: 0.45)),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 12.0;
                          const horizontalPadding = 32.0;
                          final contentWidth =
                              constraints.maxWidth - horizontalPadding;
                          final columns = contentWidth < 340 ? 1 : 2;
                          final cardWidth =
                              (contentWidth - spacing * (columns - 1)) /
                                  columns;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                            child: Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: filtered.map((club) {
                                return SizedBox(
                                  width: cardWidth,
                                  child: ClubCard(
                                    club: club,
                                    isFollowed: followProvider.isFollowing(
                                      userId,
                                      club.id,
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ClubDetailScreen(club: club),
                                      ),
                                    ),
                                    onFollowToggle: () =>
                                        _toggleFollow(club, userId),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
