part of '../settings_screen.dart';

class _NotificationSettingsCard extends StatelessWidget {
  final ThemeProvider themeProvider;
  final AuthProvider auth;

  const _NotificationSettingsCard({
    required this.themeProvider,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    return Card(
      child: Column(
        children: [
          _NotifToggle(
            icon: Icons.chat_bubble_rounded,
            iconColor: const Color(0xFF14B8A6),
            title: 'New Posts',
            subtitle: 'Get notified when clubs post new content',
            value: themeProvider.notifyPosts,
            onChanged: themeProvider.setNotifyPosts,
          ),
          const Divider(height: 1, indent: 56),
          _NotifToggle(
            icon: Icons.event_rounded,
            iconColor: const Color(0xFFF97316),
            title: 'New Events',
            subtitle: 'Be notified of upcoming events from followed clubs',
            value: themeProvider.notifyEvents,
            onChanged: themeProvider.setNotifyEvents,
          ),
          const Divider(height: 1, indent: 56),
          _NotifToggle(
            icon: Icons.alarm_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Event Reminders',
            subtitle: 'Reminders before events you\'re registered for',
            value: themeProvider.notifyReminders,
            onChanged: themeProvider.setNotifyReminders,
          ),
          const Divider(height: 1, indent: 56),
          _NotifToggle(
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Club Updates',
            subtitle: 'News and announcements from your clubs',
            value: themeProvider.notifyClubUpdates,
            onChanged: themeProvider.setNotifyClubUpdates,
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
    );
  }
}
