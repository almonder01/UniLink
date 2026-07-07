import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DirectVideoPreview extends StatelessWidget {
  final String url;
  final String title;
  final String subtitle;
  final double borderRadius;
  final bool compact;

  const DirectVideoPreview({
    super.key,
    required this.url,
    required this.title,
    this.subtitle = 'Watch in UniLink',
    this.borderRadius = 16,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => showDirectVideoDialog(context, url: url, title: title),
      borderRadius: BorderRadius.circular(borderRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AspectRatio(
          aspectRatio: 16 / (compact ? 7 : 9),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.85),
                  cs.secondary.withValues(alpha: 0.72),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Icon(
                  Icons.movie_creation_rounded,
                  size: compact ? 54 : 72,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Center(
                  child: Container(
                    width: compact ? 48 : 58,
                    height: compact ? 48 : 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: cs.primary,
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

Future<void> showDirectVideoDialog(
  BuildContext context, {
  required String url,
  required String title,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DirectVideoDialog(url: url, title: title),
  );
}

class _DirectVideoDialog extends StatefulWidget {
  final String url;
  final String title;

  const _DirectVideoDialog({
    required this.url,
    required this.title,
  });

  @override
  State<_DirectVideoDialog> createState() => _DirectVideoDialogState();
}

class _DirectVideoDialogState extends State<_DirectVideoDialog> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialize;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialize = _controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _togglePlayback() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: FutureBuilder<void>(
                  future: _initialize,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ColoredBox(
                          color: cs.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }
                    if (_controller.value.hasError) {
                      return AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ColoredBox(
                          color: cs.errorContainer,
                          child: Center(
                            child: Text(
                              'Could not load video',
                              style: TextStyle(color: cs.onErrorContainer),
                            ),
                          ),
                        ),
                      );
                    }
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        if (!_controller.value.isPlaying)
                          IconButton.filled(
                            onPressed: _togglePlayback,
                            icon: const Icon(Icons.play_arrow_rounded),
                            iconSize: 34,
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _controller.value.isInitialized
                        ? _togglePlayback
                        : null,
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_controller.value.isInitialized)
                    Expanded(
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
