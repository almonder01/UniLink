import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

part 'settings/appearance_card.dart';
part 'settings/feed_priority_card.dart';
part 'settings/notification_settings_card.dart';
part 'settings/notif_toggle.dart';
part 'settings/priority_selector.dart';
part 'settings/privacy_card.dart';
part 'settings/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SettingsSectionHeader('Appearance'),
          const SizedBox(height: 10),
          _AppearanceCard(themeProvider: tp),
          const SizedBox(height: 24),
          const _SettingsSectionHeader('Privacy'),
          const SizedBox(height: 10),
          _PrivacyCard(auth: auth),
          const SizedBox(height: 24),
          const _SettingsSectionHeader('Feed Priority'),
          const SizedBox(height: 10),
          _FeedPriorityCard(themeProvider: tp),
          const SizedBox(height: 24),
          const _SettingsSectionHeader('Notifications'),
          const SizedBox(height: 10),
          _NotificationSettingsCard(themeProvider: tp, auth: auth),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
