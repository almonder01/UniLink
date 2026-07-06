part of '../event_detail_screen.dart';

class _EventDetailContent extends StatelessWidget {
  final EventModel event;
  final Color logoColor;
  final VoidCallback onClubTap;
  final VoidCallback onCopyExternalForm;

  const _EventDetailContent({
    required this.event,
    required this.logoColor,
    required this.onClubTap,
    required this.onCopyExternalForm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onClubTap,
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  ClubAvatar(
                    color: logoColor,
                    logoBase64: event.clubLogoImageBase64,
                    showBackground: event.clubShowLogoBackground,
                    size: 40,
                    borderRadius: 12,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.clubName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Organized by ${event.clubName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              event.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat('MMM d, y').format(event.eventDate),
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InfoChip(
                    icon: Icons.schedule_rounded,
                    label: DateFormat('h:mm a').format(event.eventDate),
                    color: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InfoChip(
              icon: Icons.location_on_rounded,
              label: event.location,
              color: const Color(0xFF22C55E),
              expand: true,
            ),
            if (event.hasCapacityLimit) ...[
              const SizedBox(height: 10),
              InfoChip(
                icon: Icons.groups_rounded,
                label:
                    '${event.registeredCount}/${event.maxParticipants} registered',
                color: const Color(0xFF6366F1),
                expand: true,
              ),
            ],
            if (event.requiresPayment) ...[
              const SizedBox(height: 10),
              InfoChip(
                icon: Icons.payments_rounded,
                label: 'Payment required: ${event.feeLabel}',
                color: const Color(0xFF14B8A6),
                expand: true,
              ),
            ],
            if (event.hasExternalForm) ...[
              const SizedBox(height: 10),
              _ExternalFormPanel(
                url: event.externalFormUrl!.trim(),
                onCopy: onCopyExternalForm,
              ),
            ],
            if (event.latitude != null && event.longitude != null) ...[
              const SizedBox(height: 12),
              EventMapPreview(
                latitude: event.latitude!,
                longitude: event.longitude!,
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'About this Event',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
            if (event.hasRegistrationRequirement) ...[
              const SizedBox(height: 20),
              const Text(
                'Registration Requirement',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                event.registrationRequirementPrompt?.trim().isNotEmpty == true
                    ? event.registrationRequirementPrompt!.trim()
                    : 'Additional information is required when registering.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: cs.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Photos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            MediaGallery(images: event.photoBase64List),
          ],
        ),
      ),
    );
  }
}
