import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tp = context.watch<ThemeProvider>();

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
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
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
