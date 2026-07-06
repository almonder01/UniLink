import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import 'base64_image.dart';
import 'identity_avatar.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coverColor = Color(int.parse(event.coverColor, radix: 16));
    final logoColor = event.clubLogoColor != null
        ? Color(int.parse(event.clubLogoColor!, radix: 16))
        : cs.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      coverColor,
                      Color.lerp(coverColor, Colors.orange.shade900, 0.4)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (event.coverImageBase64 != null) ...[
                      Base64Image(data: event.coverImageBase64!),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: Icon(
                        Icons.confirmation_number_rounded,
                        size: 90,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    const Positioned(
                      left: 12,
                      top: 12,
                      child: _EventTypeChip(),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _DateBadge(date: event.eventDate),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClubAvatar(
                        color: logoColor,
                        logoBase64: event.clubLogoImageBase64,
                        showBackground: event.clubShowLogoBackground,
                        size: 30,
                        borderRadius: 9,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.clubName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              DateFormat('EEE, MMM d - h:mm a')
                                  .format(event.eventDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const _EventTagChip(),
                      event.isRegistered
                          ? const _RegisteredChip()
                          : FilledButton.tonal(
                              onPressed: onRegister,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Register'),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            DateFormat('d').format(date),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTypeChip extends StatelessWidget {
  const _EventTypeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_rounded, size: 11, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'EVENT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTagChip extends StatelessWidget {
  const _EventTagChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_rounded, size: 12, color: Color(0xFFF97316)),
          SizedBox(width: 4),
          Text(
            'Event',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFF97316),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisteredChip extends StatelessWidget {
  const _RegisteredChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF22C55E)),
          SizedBox(width: 4),
          Text(
            'Registered',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF22C55E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
