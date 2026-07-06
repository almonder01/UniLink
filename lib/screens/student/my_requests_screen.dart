import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/club_membership_request.dart';
import '../../models/event_registration.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import '../../services/membership_request_service.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late Future<_RequestsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RequestsData> _load() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      return const _RequestsData(events: [], memberships: []);
    }
    final events = await EventService().getRegistrationsForUser(user.id);
    final memberships =
        await MembershipRequestService().requestsForUser(user.id);
    return _RequestsData(events: events, memberships: memberships);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: FutureBuilder<_RequestsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ??
              const _RequestsData(events: [], memberships: []);
          if (data.events.isEmpty && data.memberships.isEmpty) {
            return Center(
              child: Text(
                'No requests yet',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (data.events.isNotEmpty) ...[
                  const _SectionTitle('Event Registrations'),
                  const SizedBox(height: 8),
                  ...data.events.map((registration) =>
                      _EventRequestCard(registration: registration)),
                  const SizedBox(height: 18),
                ],
                if (data.memberships.isNotEmpty) ...[
                  const _SectionTitle('Membership Requests'),
                  const SizedBox(height: 8),
                  ...data.memberships.map((request) =>
                      _MembershipRequestCard(request: request)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestsData {
  final List<EventRegistration> events;
  final List<ClubMembershipRequest> memberships;

  const _RequestsData({
    required this.events,
    required this.memberships,
  });
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }
}

class _EventRequestCard extends StatelessWidget {
  final EventRegistration registration;

  const _EventRequestCard({required this.registration});

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      title: registration.eventTitle,
      subtitle: 'Event registration',
      status: registration.status,
      icon: Icons.event_available_rounded,
    );
  }
}

class _MembershipRequestCard extends StatelessWidget {
  final ClubMembershipRequest request;

  const _MembershipRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      title: request.clubName,
      subtitle: 'Club membership request',
      status: request.status,
      icon: Icons.how_to_reg_rounded,
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('Approved', const Color(0xFF22C55E)),
      'rejected' => ('Rejected', const Color(0xFFEF4444)),
      'cancelled' => ('Cancelled', const Color(0xFF64748B)),
      'payment_requested' => ('Payment requested', const Color(0xFFF59E0B)),
      _ => ('Pending', const Color(0xFFF59E0B)),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
