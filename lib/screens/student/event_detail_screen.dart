import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../services/event_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/club_audio_player.dart';
import '../../widgets/event_map_preview.dart';
import '../../widgets/identity_avatar.dart';
import '../../widgets/media_gallery.dart';
import '../../widgets/video_media_preview.dart';
import '../../widgets/youtube_video_preview.dart';
import '../chat/share_to_chat_sheet.dart';
import 'club_detail_screen.dart';
import 'widgets/info_chip.dart';
import 'widgets/event_registration_dialog.dart';

part 'event_detail/event_detail_content.dart';
part 'event_detail/event_detail_header.dart';
part 'event_detail/event_registration_bar.dart';
part 'event_detail/external_form_panel.dart';

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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _EventDetailHeader(
            event: widget.event,
            coverColor: coverColor,
          ),
        

          _EventDetailContent(
            event: widget.event,
            logoColor: logoColor,
            onClubTap: _openClub,
            onCopyExternalForm: _copyExternalForm,
          ),
        
        ],
      ),

      bottomNavigationBar: _EventRegistrationBar(
        event: widget.event,
        isRegistered: _isRegistered,
        registrationStatus: _registrationStatus,
        onRegister: _confirmRegistration,
        onShare: _shareEvent,
      ),
        
    );
  }
}

