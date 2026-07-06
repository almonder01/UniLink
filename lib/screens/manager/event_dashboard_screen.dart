import 'package:flutter/material.dart';

import '../../models/club.dart';
import 'event_dashboard_tab.dart';

class EventDashboardScreen extends StatelessWidget {
  final ClubModel club;

  const EventDashboardScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Dashboard'),
      ),
      body: EventDashboardTab(club: club),
    );
  }
}
