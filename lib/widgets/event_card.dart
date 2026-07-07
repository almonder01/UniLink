import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import 'base64_image.dart';
import 'identity_avatar.dart';

part 'event_card/small_action_button.dart';
part 'event_card/date_badge.dart';
part 'event_card/event_type_chip.dart';
part 'event_card/event_tag_chip.dart';
part 'event_card/event_fee_chip.dart';
part 'event_card/event_capacity_chip.dart';
part 'event_card/full_chip.dart';
part 'event_card/registration_state_chip.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;
  final VoidCallback? onShare;
  final VoidCallback? onClubTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onRegister,
    this.onShare,
    this.onClubTap,
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
                  InkWell(
                    onTap: onClubTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
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
                      if (event.requiresPayment)
                        _EventFeeChip(label: event.feeLabel),
                      if (event.hasCapacityLimit)
                        _EventCapacityChip(
                          registered: event.registeredCount,
                          max: event.maxParticipants!,
                          isFull: event.isFull,
                        ),
                      event.isRegistered
                          ? _RegistrationStateChip(
                              status: event.registrationStatus,
                            )
                          : event.isFull
                              ? const _FullChip()
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
                      if (onShare != null)
                        _SmallActionButton(
                          icon: Icons.send_rounded,
                          label: 'Share',
                          onTap: onShare!,
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
