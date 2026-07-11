import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme_tokens.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_surface.dart';
import '../student/clubs_screen.dart';
import '../student/notifications_screen.dart';
import '../student/profile_screen.dart';
import 'admin_dashboard_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasUnreadNotifications =
        context.watch<NotificationProvider>().unreadCount > 0;
    final screens = [
      const AdminDashboardScreen(),
      const NotificationsScreen(),
      const ClubsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AppSurface(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          color: tokens.elevatedSurface,
          borderRadius: tokens.radiusXlBorder,
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: _NavIconWithDot(
                  icon: Icons.notifications_outlined,
                  showDot: hasUnreadNotifications,
                ),
                selectedIcon: _NavIconWithDot(
                  icon: Icons.notifications_rounded,
                  showDot: hasUnreadNotifications,
                ),
                label: 'Alerts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Clubs',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIconWithDot extends StatelessWidget {
  final IconData icon;
  final bool showDot;

  const _NavIconWithDot({
    required this.icon,
    required this.showDot,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showDot)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: tokens.info,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
