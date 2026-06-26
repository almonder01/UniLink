import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import 'widgets/info_chip.dart';
import 'widgets/register_sheet.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late bool _isRegistered;

  @override
  void initState() {
    super.initState();
    _isRegistered = widget.event.isRegistered;
  }

  Future<void> _showRegisterSheet() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => RegisterSheet(event: widget.event),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _isRegistered = true;
        widget.event.isRegistered = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("You're registered! See you there."),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coverColor = Color(int.parse(widget.event.coverColor, radix: 16));
    final logoColor = widget.event.clubLogoColor != null
        ? Color(int.parse(widget.event.clubLogoColor!, radix: 16))
        : cs.primary;

    final nameParts = widget.event.clubName.trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : widget.event.clubName.substring(0, 2).toUpperCase();

    final sampleColors = [
      const Color(0xFFF97316),
      const Color(0xFF6366F1),
      const Color(0xFF22C55E),
      const Color(0xFFA855F7),
    ];

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
                  children: [
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
                  const SizedBox(height: 24),
                  // Photo gallery
                  const Text('Photos',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
        child: _isRegistered
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF22C55E), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "You're registered!",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF22C55E)),
                    ),
                  ],
                ),
              )
            : FilledButton.icon(
                onPressed: _showRegisterSheet,
                icon:
                    const Icon(Icons.confirmation_number_rounded, size: 20),
                label: const Text('Register Now'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
      ),
    );
  }
}
