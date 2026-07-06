part of '../profile_screen.dart';

class _MemberClubsSection extends StatelessWidget {
  final Future<List<String>> memberClubIdsFuture;
  final List<ClubModel> allClubs;
  final UserModel user;

  const _MemberClubsSection({
    required this.memberClubIdsFuture,
    required this.allClubs,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: memberClubIdsFuture,
      builder: (context, snapshot) {
        final memberIds = snapshot.data?.toSet() ?? <String>{};
        if ((user.managedClubId ?? '').isNotEmpty) {
          memberIds.add(user.managedClubId!);
        }
        final memberClubs =
            allClubs.where((club) => memberIds.contains(club.id)).toList();

        return _ProfileClubList(
          title: 'Member Clubs',
          clubs: memberClubs,
          emptyIcon: Icons.badge_outlined,
          emptyText: snapshot.connectionState == ConnectionState.waiting
              ? 'Loading member clubs...'
              : 'No club memberships yet',
        );
      },
    );
  }
}
