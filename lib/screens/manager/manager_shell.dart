import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../../models/club.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../student/clubs_screen.dart';
import '../student/home_screen.dart';
import '../student/profile_screen.dart';
import 'club_management_screen.dart';
import 'no_club_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final user = context.read<AuthProvider>().currentUser;
    final clubId = user?.managedClubId;
    final clubProvider = context.watch<ClubProvider>();

    if (clubProvider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ClubModel? managedClub = clubId != null && clubId.isNotEmpty
        ? clubProvider.getById(clubId)
        : null;

    final screens = [
      const HomeScreen(),
      const ClubsScreen(),
      managedClub != null
          ? ClubManagementScreen(club: managedClub)
          : const NoClubScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: tokens.shadow,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Clubs',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts_rounded),
              label: 'My Club',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
