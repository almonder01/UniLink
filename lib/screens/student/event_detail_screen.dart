import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../services/event_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/event_map_preview.dart';
import '../../widgets/identity_avatar.dart';
import '../../widgets/media_gallery.dart';
import '../chat/share_to_chat_sheet.dart';
import 'club_detail_screen.dart';
import 'widgets/info_chip.dart';
import 'widgets/event_registration_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late bool _isRegistered;
  String? _registrationStatus;

  @override
  void initState() {
    super.initState();
    _isRegistered = widget.event.isRegistered;
    _registrationStatus = widget.event.registrationStatus;
  }

  Future<void> _confirmRegistration() async {
    if (widget.event.isFull && !_isRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This event is full.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final submission = await showEventRegistrationDialog(
      context,
      event: widget.event,
    );
    if (submission != null && mounted) {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      try {
        await EventService().registerForEvent(
          event: widget.event,
          user: user,
          paymentReceiptBase64: submission.paymentReceiptBase64,
          requirementTextResponse: submission.requirementTextResponse,
          requirementFileBase64: submission.requirementFileBase64,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _isRegistered = true;
        _registrationStatus =
            widget.event.requiresPayment || widget.event.hasRegistrationRequirement
                ? 'pending'
                : 'approved';
      });
      widget.event.isRegistered = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.event.requiresPayment
                        || widget.event.hasRegistrationRequirement
                    ? 'Registration submitted for approval.'
                    : "You're registered! See you there.",
              ),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _shareEvent() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await ShareToChatSheet.showEvent(context, event: widget.event, user: user);
  }

  Future<void> _copyExternalForm() async {
    final link = widget.event.externalFormUrl?.trim();
    if (link == null || link.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form link copied.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openClub() {
    final club = context.read<ClubProvider>().getById(widget.event.clubId);
    if (club == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubDetailScreen(club: club)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coverColor = Color(int.parse(widget.event.coverColor, radix: 16));
    final logoColor = widget.event.clubLogoColor != null
        ? Color(int.parse(widget.event.clubLogoColor!, radix: 16))
        : cs.primary;
    final isPending = _registrationStatus == 'pending';
    final statusColor =
        isPending ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────────
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
                      Color.lerp(coverColor, Colors.orange.shade900, 0.5)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.event.coverImageBase64 != null) ...[
                      Base64Image(data: widget.event.coverImageBase64!),
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
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => showBase64ImagePreview(
                              context,
                              data: widget.event.coverImageBase64!,
                            ),
                          ),
                        ),
                      ),
                    ],
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.confirmation_number_rounded,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    // Date badge
                    Positioned(
                      right: 16,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('MMM')
                                  .format(widget.event.eventDate)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5),
                            ),
                            Text(
                              DateFormat('d').format(widget.event.eventDate),
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Event label
                    Positioned(
                      left: 16,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 5),
                            Text('EVENT',
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

          // ── Body ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Club row
                  InkWell(
                    onTap: _openClub,
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      children: [
                        ClubAvatar(
                          color: logoColor,
                          logoBase64: widget.event.clubLogoImageBase64,
                          showBackground: widget.event.clubShowLogoBackground,
                          size: 40,
                          borderRadius: 12,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.event.clubName,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                            Text('Organized by ${widget.event.clubName}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.event.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  // Info chips
                  Row(
                    children: [
                      Expanded(
                        child: InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: DateFormat('MMM d, y')
                              .format(widget.event.eventDate),
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InfoChip(
                          icon: Icons.schedule_rounded,
                          label: DateFormat('h:mm a')
                              .format(widget.event.eventDate),
                          color: const Color(0xFFF97316),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InfoChip(
                    icon: Icons.location_on_rounded,
                    label: widget.event.location,
                    color: const Color(0xFF22C55E),
                    expand: true,
                  ),
                  if (widget.event.hasCapacityLimit) ...[
                    const SizedBox(height: 10),
                    InfoChip(
                      icon: Icons.groups_rounded,
                      label:
                          '${widget.event.registeredCount}/${widget.event.maxParticipants} registered',
                      color: const Color(0xFF6366F1),
                      expand: true,
                    ),
                  ],
                  if (widget.event.requiresPayment) ...[
                    const SizedBox(height: 10),
                    InfoChip(
                      icon: Icons.payments_rounded,
                      label: 'Payment required: ${widget.event.feeLabel}',
                      color: const Color(0xFF14B8A6),
                      expand: true,
                    ),
                  ],
                  if (widget.event.hasExternalForm) ...[
                    const SizedBox(height: 10),
                    _ExternalFormPanel(
                      url: widget.event.externalFormUrl!.trim(),
                      onCopy: _copyExternalForm,
                    ),
                  ],
                  if (widget.event.latitude != null &&
                      widget.event.longitude != null) ...[
                    const SizedBox(height: 12),
                    EventMapPreview(
                      latitude: widget.event.latitude!,
                      longitude: widget.event.longitude!,
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Description
                  const Text('About this Event',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: cs.onSurface.withValues(alpha: 0.75)),
                  ),
                  if (widget.event.hasRegistrationRequirement) ...[
                    const SizedBox(height: 20),
                    const Text('Registration Requirement',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      widget.event.registrationRequirementPrompt?.trim()
                                  .isNotEmpty ==
                              true
                          ? widget.event.registrationRequirementPrompt!.trim()
                          : 'Additional information is required when registering.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: cs.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Photo gallery
                  const Text('Photos',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  MediaGallery(images: widget.event.photoBase64List),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom bar ─────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _isRegistered
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPending
                                ? Icons.hourglass_top_rounded
                                : Icons.check_circle_rounded,
                            color: statusColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPending
                                ? 'Pending approval'
                                : "You're registered!",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : FilledButton.icon(
                      onPressed:
                          widget.event.isFull ? null : _confirmRegistration,
                      icon: const Icon(Icons.confirmation_number_rounded,
                          size: 20),
                      label: Text(widget.event.isFull ? 'Event Full' : 'Register Now'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: _shareEvent,
              icon: const Icon(Icons.send_rounded),
              tooltip: 'Share',
            ),
          ],
        ),
      ),
    );
  }
}

class _ExternalFormPanel extends StatelessWidget {
  final String url;
  final VoidCallback onCopy;

  const _ExternalFormPanel({
    required this.url,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'External form',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy'),
              ),
            ],
          ),
          SelectableText(
            url,
            style: TextStyle(
              fontSize: 12,
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
