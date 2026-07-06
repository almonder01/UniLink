part of '../home_screen.dart';

class _HomeFeedPrioritizer {
  final Set<String> memberClubIds;

  const _HomeFeedPrioritizer(this.memberClubIds);

  int _priorityForClub(
    String clubId,
    Set<String> followedIds,
    String mode,
  ) {
    final isMember = memberClubIds.contains(clubId);
    final isFollowed = followedIds.contains(clubId);
    if (mode == 'recent') return 0;
    if (mode == 'followed_first') {
      if (isFollowed) return 0;
      if (isMember) return 1;
      return 2;
    }
    if (isMember) return 0;
    if (isFollowed) return 1;
    return 2;
  }

  List<PostModel> posts(
    List<PostModel> source,
    Set<String> followedIds,
    String mode,
  ) {
    final visibleClubIds = {...followedIds, ...memberClubIds};
    final posts =
        source.where((post) => visibleClubIds.contains(post.clubId)).toList();
    posts.sort((a, b) {
      final priority = _priorityForClub(a.clubId, followedIds, mode)
          .compareTo(_priorityForClub(b.clubId, followedIds, mode));
      if (priority != 0) return priority;
      return b.createdAt.compareTo(a.createdAt);
    });
    return posts;
  }

  List<EventModel> events(
    List<EventModel> source,
    Set<String> followedIds,
    String mode,
  ) {
    final visibleClubIds = {...followedIds, ...memberClubIds};
    final events = source
        .where((event) => visibleClubIds.contains(event.clubId))
        .toList();
    events.sort((a, b) {
      final priority = _priorityForClub(a.clubId, followedIds, mode)
          .compareTo(_priorityForClub(b.clubId, followedIds, mode));
      if (priority != 0) return priority;
      return a.eventDate.compareTo(b.eventDate);
    });
    return events;
  }
}
