import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

String? youtubeVideoIdFromUrl(String? url) {
  final raw = url?.trim();
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  if (host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first;
  }
  if (host.contains('youtube.com') || host.contains('youtube-nocookie.com')) {
    final watchId = uri.queryParameters['v'];
    if (watchId != null && watchId.isNotEmpty) return watchId;
    final segments = uri.pathSegments;
    final embedIndex = segments.indexWhere(
      (segment) => segment == 'embed' || segment == 'shorts',
    );
    if (embedIndex != -1 && embedIndex + 1 < segments.length) {
      return segments[embedIndex + 1];
    }
  }
  return null;
}

String? youtubeThumbnailUrl(String? url) {
  final id = youtubeVideoIdFromUrl(url);
  if (id == null) return null;
  return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

class YouTubeVideoPreview extends StatelessWidget {
  final String url;
  final String title;
  final String subtitle;
  final double borderRadius;
  final bool compact;
  final bool enableTap;

  const YouTubeVideoPreview({
    super.key,
    required this.url,
    this.title = 'YouTube video',
    this.subtitle = 'Watch in UniLink',
    this.borderRadius = 16,
    this.compact = false,
    this.enableTap = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final thumb = youtubeThumbnailUrl(url);

    return InkWell(
      onTap: enableTap
          ? () => showYouTubePreviewDialog(context, url: url, title: title)
          : null,
      borderRadius: BorderRadius.circular(borderRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AspectRatio(
          aspectRatio: 16 / (compact ? 7 : 9),
          child: Container(
            color: cs.surfaceContainerHighest,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (thumb != null)
                  Image.network(
                    thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const _VideoFallback(icon: Icons.smart_display_rounded),
                  )
                else
                  const _VideoFallback(icon: Icons.smart_display_rounded),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.58),
                        Colors.black.withValues(alpha: 0.12),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: compact ? 48 : 58,
                    height: compact ? 48 : 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFFFF0000),
                      size: 34,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!compact)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoFallback extends StatelessWidget {
  final IconData icon;

  const _VideoFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.primary.withValues(alpha: 0.16),
      child: Icon(icon, color: cs.primary, size: 44),
    );
  }
}

Future<void> showYouTubePreviewDialog(
  BuildContext context, {
  required String url,
  required String title,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _YouTubePlayerDialog(url: url, title: title),
  );
}

class _YouTubePlayerDialog extends StatefulWidget {
  final String url;
  final String title;

  const _YouTubePlayerDialog({
    required this.url,
    required this.title,
  });

  @override
  State<_YouTubePlayerDialog> createState() => _YouTubePlayerDialogState();
}

class _YouTubePlayerDialogState extends State<_YouTubePlayerDialog> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = youtubeVideoIdFromUrl(widget.url);
    if (videoId == null) return;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: false,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = _controller;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (controller == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Invalid YouTube link',
                    style: TextStyle(
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: YoutubePlayer(controller: controller),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
