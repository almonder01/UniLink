import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tp = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionHeader('Appearance'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_rounded, size: 16),
                      ),
                    ],
                    selected: {tp.themeMode},
                    onSelectionChanged: (s) => tp.setThemeMode(s.first),
                    style: ButtonStyle(
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader('Privacy'),
          const SizedBox(height: 10),
          Card(
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
                    child: Icon(Icons.visibility_rounded,
                        color: cs.primary, size: 18),
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
                      : (value) =>
                          auth.updateProfile(showInClubMembers: value),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.people_alt_rounded,
                        color: Color(0xFF8B5CF6), size: 18),
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
                      : (value) =>
                          auth.updateProfile(showInClubFollowers: value),
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
                              color:
                                  const Color(0xFF14B8A6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.forum_rounded,
                                color: Color(0xFF14B8A6), size: 18),
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
          ),
          const SizedBox(height: 24),
          const _SectionHeader('Feed Priority'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PrioritySelector(
                    title: 'Post priority',
                    value: tp.postFeedPriority,
                    onChanged: tp.setPostFeedPriority,
                  ),
                  const SizedBox(height: 16),
                  _PrioritySelector(
                    title: 'Event priority',
                    value: tp.eventFeedPriority,
                    onChanged: tp.setEventFeedPriority,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader('Notifications'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _NotifToggle(
                  icon: Icons.chat_bubble_rounded,
                  iconColor: const Color(0xFF14B8A6),
                  title: 'New Posts',
                  subtitle: 'Get notified when clubs post new content',
                  value: tp.notifyPosts,
                  onChanged: tp.setNotifyPosts,
                ),
                const Divider(height: 1, indent: 56),
                _NotifToggle(
                  icon: Icons.event_rounded,
                  iconColor: const Color(0xFFF97316),
                  title: 'New Events',
                  subtitle:
                      'Be notified of upcoming events from followed clubs',
                  value: tp.notifyEvents,
                  onChanged: tp.setNotifyEvents,
                ),
                const Divider(height: 1, indent: 56),
                _NotifToggle(
                  icon: Icons.alarm_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Event Reminders',
                  subtitle: 'Reminders before events you\'re registered for',
                  value: tp.notifyReminders,
                  onChanged: tp.setNotifyReminders,
                ),
                const Divider(height: 1, indent: 56),
                _NotifToggle(
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Club Updates',
                  subtitle: 'News and announcements from your clubs',
                  value: tp.notifyClubUpdates,
                  onChanged: tp.setNotifyClubUpdates,
                ),
                const Divider(height: 1, indent: 56),
                _NotifToggle(
                  icon: Icons.mark_chat_unread_rounded,
                  iconColor: const Color(0xFF14B8A6),
                  title: 'Chat Messages',
                  subtitle: 'Receive notifications for private messages',
                  value: user?.notifyChatMessages ?? true,
                  onChanged: (value) =>
                      auth.updateProfile(notifyChatMessages: value),
                ),
                const Divider(height: 1, indent: 56),
                _NotifToggle(
                  icon: Icons.group_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Messages from Members',
                  subtitle: 'Notify me when a club member messages me',
                  value: user?.notifyChatFromMembers ?? true,
                  onChanged: (value) =>
                      auth.updateProfile(notifyChatFromMembers: value),
                ),
                const Divider(height: 1, indent: 56),
                _NotifToggle(
                  icon: Icons.admin_panel_settings_rounded,
                  iconColor: const Color(0xFFF97316),
                  title: 'Messages from Club Managers',
                  subtitle: 'Notify me when a club manager messages me',
                  value: user?.notifyChatFromManagers ?? true,
                  onChanged: (value) =>
                      auth.updateProfile(notifyChatFromManagers: value),
                ),
                const Divider(height: 1, indent: 56),
                _NotifToggle(
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Messages from Any Student',
                  subtitle: 'Notify me about messages outside my clubs',
                  value: user?.notifyChatFromEveryone ?? true,
                  onChanged: (value) =>
                      auth.updateProfile(notifyChatFromEveryone: value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final String title;
  final String value;
  final ValueChanged<String> onChanged;

  const _PrioritySelector({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'member_first',
                label: Text('Member'),
                icon: Icon(Icons.groups_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'followed_first',
                label: Text('Followed'),
                icon: Icon(Icons.notifications_active_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'recent',
                label: Text('Recent'),
                icon: Icon(Icons.schedule_rounded, size: 16),
              ),
            ],
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
