part of '../members_tab.dart';

class _MembersHeader extends StatelessWidget {
  final ClubModel club;

  const _MembersHeader({required this.club});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Members',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Membership requests',
            icon: const Icon(Icons.how_to_reg_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MembershipRequestsScreen(club: club),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
