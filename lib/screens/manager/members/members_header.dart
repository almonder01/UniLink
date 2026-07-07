part of '../members_tab.dart';

class _MembersHeader extends StatelessWidget {
  final ClubModel club;

  const _MembersHeader({required this.club});

  @override
  Widget build(BuildContext context) {
    return ManagerActionBanner(
      icon: Icons.how_to_reg_rounded,
      title: 'Members',
      subtitle: 'Review requests and manage club members',
      tooltip: 'Membership requests',
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MembershipRequestsScreen(club: club),
        ),
      ),
    );
  }
}
