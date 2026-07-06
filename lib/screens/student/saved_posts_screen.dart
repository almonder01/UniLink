import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../services/saved_post_service.dart';
import '../../widgets/post_card.dart';
import 'club_detail_screen.dart';
import 'post_detail_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final _searchCtrl = TextEditingController();
  List<PostModel> _posts = [];
  bool _loading = true;
  String _selectedClubId = 'all';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _loadSavedPosts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPosts() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    final posts = await SavedPostService().getSavedPosts(user.id);
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  List<PostModel> get _filteredPosts {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _posts.where((post) {
      final matchesClub =
          _selectedClubId == 'all' || post.clubId == _selectedClubId;
      final matchesSearch = query.isEmpty ||
          post.title.toLowerCase().contains(query) ||
          post.description.toLowerCase().contains(query) ||
          post.clubName.toLowerCase().contains(query);
      return matchesClub && matchesSearch;
    }).toList();
  }

  List<PostModel> get _clubFilters {
    final seen = <String>{};
    final clubs = <PostModel>[];
    for (final post in _posts) {
      if (seen.add(post.clubId)) clubs.add(post);
    }
    clubs.sort((a, b) => a.clubName.compareTo(b.clubName));
    return clubs;
  }

  Future<void> _unsave(PostModel post) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final oldPosts = [..._posts];
    setState(() => _posts.removeWhere((p) => p.id == post.id));

    try {
      await SavedPostService().unsavePost(user.id, post.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _posts = oldPosts);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove saved post: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openPost(PostModel post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
    if (mounted) await _loadSavedPosts();
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
    final cs = Theme.of(context).colorScheme;
    final filteredPosts = _filteredPosts;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Posts')),
      body: RefreshIndicator(
        onRefresh: _loadSavedPosts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            SearchBar(
              controller: _searchCtrl,
              hintText: 'Search saved posts...',
              leading: const Icon(Icons.search_rounded),
              trailing: _searchCtrl.text.isEmpty
                  ? null
                  : [
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ],
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _clubFilters.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final isAll = index == 0;
                  final clubPost = isAll ? null : _clubFilters[index - 1];
                  final id = isAll ? 'all' : clubPost!.clubId;
                  final selected = _selectedClubId == id;
                  return FilterChip(
                    label: Text(isAll ? 'All clubs' : clubPost!.clubName),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedClubId = id),
                    selectedColor: cs.primary.withValues(alpha: 0.15),
                    checkmarkColor: cs.primary,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 90),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_posts.isEmpty)
              const _EmptySavedPosts(
                icon: Icons.bookmark_border_rounded,
                title: 'No saved posts yet',
                message: 'Save posts from your feed to revisit them here.',
              )
            else if (filteredPosts.isEmpty)
              const _EmptySavedPosts(
                icon: Icons.search_off_rounded,
                title: 'No matches',
                message: 'Try another search or club filter.',
              )
            else
              ...filteredPosts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PostCard(
                    post: post,
                    isSaved: true,
                    onSave: () => _unsave(post),
                    onClubTap: () => _openClub(post.clubId),
                    onTap: () => _openPost(post),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptySavedPosts extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptySavedPosts({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 90),
      child: Column(
        children: [
          Icon(icon, size: 58, color: cs.onSurface.withValues(alpha: 0.22)),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: cs.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.42),
            ),
          ),
        ],
      ),
    );
  }
}
