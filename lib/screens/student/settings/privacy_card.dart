part of '../settings_screen.dart';

class _PrivacyCard extends StatelessWidget {
  final AuthProvider auth;

  const _PrivacyCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = auth.currentUser;

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.visibility_rounded, color: cs.primary, size: 18),
            ),
            title: const Text(
              'Show me in club member lists',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Students can see your name in clubs you are a member of',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            value: user?.showInClubMembers ?? true,
            onChanged: user == null
                ? null
                : (value) => auth.updateProfile(showInClubMembers: value),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: Color(0xFF8B5CF6),
                size: 18,
              ),
            ),
            title: const Text(
              'Show me in follower list',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Students can see your name in clubs you follow',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            value: user?.showInClubFollowers ?? true,
            onChanged: user == null
                ? null
                : (value) => auth.updateProfile(showInClubFollowers: value),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.ondemand_video_rounded,
                color: Color(0xFFF97316),
                size: 18,
              ),
            ),
            title: const Text(
              'Autoplay club background media',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Allow club pages to start music or open featured media automatically',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            value: user?.showClubBackgroundMedia ?? true,
            onChanged: user == null
                ? null
                : (value) =>
                    auth.updateProfile(showClubBackgroundMedia: value),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          const Divider(height: 1, indent: 56),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        color: Color(0xFF14B8A6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Who can message me',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'everyone',
                        label: Text('Anyone'),
                        icon: Icon(Icons.public_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: 'club_members',
                        label: Text('Club members'),
                        icon: Icon(Icons.groups_rounded, size: 16),
                      ),
                    ],
                    selected: {user?.messagePrivacy ?? 'everyone'},
                    onSelectionChanged: user == null
                        ? null
                        : (selection) => auth.updateProfile(
                              messagePrivacy: selection.first,
                            ),
                    style: ButtonStyle(
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
