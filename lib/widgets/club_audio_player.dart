import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class ClubAudioPlayer extends StatefulWidget {
  final String url;
  final String title;
  final String subtitle;
  final bool autoPlay;
  final bool compact;

  const ClubAudioPlayer({
    super.key,
    required this.url,
    required this.title,
    this.subtitle = 'Background music',
    this.autoPlay = true,
    this.compact = false,
  });

  @override
  State<ClubAudioPlayer> createState() => _ClubAudioPlayerState();
}

class _ClubAudioPlayerState extends State<ClubAudioPlayer> {
  final _player = AudioPlayer();
  bool _loading = true;
  late bool _playRequested;
  String? _error;

  @override
  void initState() {
    super.initState();
    _playRequested = widget.autoPlay;
    _prepare();
  }

  @override
  void didUpdateWidget(covariant ClubAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loading = true;
      _error = null;
      _playRequested = widget.autoPlay;
      _player.stop().catchError((_) {});
      _prepare();
      return;
    }
    if (oldWidget.autoPlay != widget.autoPlay) {
      _playRequested = widget.autoPlay;
      if (widget.autoPlay) {
        _player.play().catchError((_) {});
      } else {
        _player.pause().catchError((_) {});
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    try {
      await _player.setUrl(widget.url);
      if (_playRequested) await _player.play();
    } catch (e) {
      _error = 'Could not load audio';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    try {
      if (_player.playing) {
        _playRequested = false;
        await _player.pause();
      } else {
        _playRequested = true;
        await _player.play();
      }
    } catch (_) {
      // Taps during loading or after a load failure should not crash the UI.
    }
  }

  Future<void> _stop() async {
    _playRequested = false;
    try {
      await _player.seek(Duration.zero);
      await _player.stop();
    } catch (_) {
      // Stop remains visually available even if the audio is not ready yet.
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : const EdgeInsets.all(12);
    final iconSize = widget.compact ? 34.0 : 42.0;
    final iconRadius = widget.compact ? 11.0 : 13.0;
    return Material(
      color: cs.surface.withValues(alpha: 0.96),
      elevation: widget.compact ? 8 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(widget.compact ? 14 : 16),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: widget.compact
              ? cs.surfaceContainerHighest.withValues(alpha: 0.72)
              : cs.primaryContainer.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(widget.compact ? 14 : 16),
          border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(iconRadius),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: cs.primary,
                size: widget.compact ? 19 : 24,
              ),
            ),
            SizedBox(width: widget.compact ? 8 : 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (!widget.compact)
                    Text(
                      _error ??
                          (_loading ? 'Loading audio...' : widget.subtitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            StreamBuilder<bool>(
              stream: _player.playingStream,
              initialData: _player.playing,
              builder: (context, snapshot) {
                final playing = snapshot.data ?? false;
                return IconButton.filledTonal(
                  onPressed: _toggle,
                  visualDensity: widget.compact
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Stop music',
              onPressed: _stop,
              visualDensity: widget.compact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              icon: const Icon(Icons.stop_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
