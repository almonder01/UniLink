import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/post.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _liked = false;
  bool _bookmarked = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coverColor = Color(int.parse(widget.post.coverColor, radix: 16));
    final logoColor = widget.post.clubLogoColor != null
        ? Color(int.parse(widget.post.clubLogoColor!, radix: 16))
        : cs.primary;

    final initials = widget.post.clubName.trim().split(' ').length >= 2
        ? '${widget.post.clubName.trim().split(' ')[0][0]}${widget.post.clubName.trim().split(' ')[1][0]}'
            .toUpperCase()
        : widget.post.clubName.substring(0, 2).toUpperCase();

    final sampleColors = [
      const Color(0xFF6366F1),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
      const Color(0xFFA855F7),
      const Color(0xFF10B981),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: coverColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      coverColor,
                      Color.lerp(coverColor, Colors.black, 0.5)!
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF14B8A6).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 5),
                            Text('POST',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Club row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: logoColor,
                        child: Text(initials,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.post.clubName,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(
                            DateFormat('EEEE, MMMM d, y')
                                .format(widget.post.createdAt),
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.post.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.post.description,
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: cs.onSurface.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 24),
                  // Photo gallery
                  const Text(
                    'Photos',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sampleColors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => Container(
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              sampleColors[i],
                              Color.lerp(sampleColors[i], Colors.black, 0.25)!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(Icons.image_rounded,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Divider(color: cs.onSurface.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionBtn(
                        icon: _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: 'Like',
                        color: _liked ? Colors.red : null,
                        onTap: () => setState(() => _liked = !_liked),
                      ),
                      _ActionBtn(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        onTap: () {},
                      ),
                      _ActionBtn(
                        icon: _bookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        label: 'Save',
                        color: _bookmarked ? cs.primary : null,
                        onTap: () => setState(() => _bookmarked = !_bookmarked),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionBtn(
      {required this.icon, required this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.onSurface.withValues(alpha: 0.55);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: effectiveColor, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: effectiveColor,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
