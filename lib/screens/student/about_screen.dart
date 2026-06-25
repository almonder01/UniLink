import 'package:flutter/material.dart';
import '../../widgets/unilink_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About UniLink')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const UnilinkLogo(size: LogoSize.large),
            const SizedBox(height: 16),
            Text(
              'UniLink',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Connecting students, building community',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 36),
            _InfoCard(
              icon: Icons.flag_rounded,
              iconColor: cs.primary,
              title: 'Our Mission',
              body:
                  'UniLink empowers university students to discover, join, and actively engage with campus clubs. We believe that student life beyond the classroom is where lifelong friendships, leadership skills, and passion projects are born. Our mission is to make that experience seamless, social, and accessible to every student.',
            ),
            const SizedBox(height: 16),
            const _InfoCard(
              icon: Icons.visibility_rounded,
              iconColor: Color(0xFF8B5CF6),
              title: 'Our Vision',
              body:
                  'We envision a university ecosystem where every student feels a deep sense of belonging. A world where technology bridges the gap between students and opportunities — where no one misses out on the events, clubs, and connections that shape who they become. UniLink is the social layer of campus life.',
            ),
            const SizedBox(height: 24),
            Text(
              'Our Values',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _ValueCard(
                        icon: Icons.people_rounded,
                        label: 'Community',
                        color: cs.primary)),
                const SizedBox(width: 10),
                const Expanded(
                    child: _ValueCard(
                        icon: Icons.lightbulb_rounded,
                        label: 'Innovation',
                        color: Color(0xFFF97316))),
                const SizedBox(width: 10),
                const Expanded(
                    child: _ValueCard(
                        icon: Icons.diversity_3_rounded,
                        label: 'Inclusion',
                        color: Color(0xFF22C55E))),
              ],
            ),
            const SizedBox(height: 40),
            Divider(color: cs.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              '© 2025 UniLink. All rights reserved.',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.35)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: cs.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ValueCard(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
