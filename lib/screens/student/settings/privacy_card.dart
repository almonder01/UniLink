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
          _PrivacySwitchTile(
            icon: Icons.visibility_rounded,
            iconColor: cs.primary,
            title: 'Show me in club member lists',
            subtitle: 'Students can see your name in clubs you are a member of',
            value: user?.showInClubMembers ?? true,
            onChanged: user == null
                ? null
                : (value) => auth.updateProfile(showInClubMembers: value),
          ),
          const Divider(height: 1, indent: 56),
          _PrivacySwitchTile(
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Show me in follower list',
            subtitle: 'Students can see your name in clubs you follow',
            value: user?.showInClubFollowers ?? true,
            onChanged: user == null
                ? null
                : (value) => auth.updateProfile(showInClubFollowers: value),
          ),
          const Divider(height: 1, indent: 56),
          _PrivacySwitchTile(
            icon: Icons.ondemand_video_rounded,
            iconColor: const Color(0xFFF97316),
            title: 'Auto-open club videos',
            subtitle: 'Open featured club videos automatically when allowed',
            value: user?.autoOpenClubVideos ?? true,
            onChanged: user == null
                ? null
                : (value) => auth.updateProfile(autoOpenClubVideos: value),
          ),
          const Divider(height: 1, indent: 56),
          _PrivacySwitchTile(
            icon: Icons.music_note_rounded,
            iconColor: const Color(0xFF22C55E),
            title: 'Autoplay club music',
            subtitle: 'Start club background music automatically when allowed',
            value: user?.autoPlayClubMusic ?? true,
            onChanged: user == null
                ? null
                : (value) => auth.updateProfile(autoPlayClubMusic: value),
          ),
          const Divider(height: 1, indent: 56),
          _PrivacySwitchTile(
            icon: Icons.smart_display_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Auto-open post and event videos',
            subtitle: 'Open videos automatically when the club enables it',
            value: user?.autoOpenContentVideos ?? false,
            onChanged: user == null
                ? null
                : (value) => auth.updateProfile(autoOpenContentVideos: value),
          ),
          const Divider(height: 1, indent: 56),
          _PrivacySwitchTile(
            icon: Icons.library_music_rounded,
            iconColor: const Color(0xFF14B8A6),
            title: 'Autoplay post and event music',
            subtitle: 'Start music automatically when the club enables it',
            value: user?.autoPlayContentAudio ?? true,
            onChanged: user == null
                ? null
                : (value) => auth.updateProfile(autoPlayContentAudio: value),
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

class _PrivacySwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _PrivacySwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurface.withValues(alpha: 0.5),
        ),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
