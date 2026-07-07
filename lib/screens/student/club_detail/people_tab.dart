part of '../club_detail_screen.dart';

class _PeopleTab extends StatelessWidget {
  final List<Map<String, dynamic>> people;
  final String emptyMessage;
  final ValueChanged<Map<String, dynamic>> onMessage;
  final Widget? header;

  const _PeopleTab({
    required this.people,
    required this.emptyMessage,
    required this.onMessage,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (header != null) header!,
          SizedBox(
            height: 360,
            child: _EmptyTabState(
              icon: Icons.people_outline_rounded,
              message: emptyMessage,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: people.length + (header == null ? 0 : 1),
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        if (header != null && index == 0) return header!;
        final peopleIndex = header == null ? index : index - 1;
        final person = people[peopleIndex];
        final name = person['name'] as String;
        final gender = person['gender'] as String;
        final role = person['role'] as String?;
        return ListTile(
          leading: UserAvatar(
            photoBase64: person['photoBase64'] as String?,
            gender: gender,
            radius: 20,
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            role == 'Manager'
                ? 'Club manager'
                : (person['major'] as String).isNotEmpty
                    ? person['major'] as String
                    : person['email'] as String,
          ),
          trailing: IconButton(
            tooltip: 'Message',
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => onMessage(person),
          ),
        );
      },
    );
  }
}
