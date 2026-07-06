part of '../home_screen.dart';

class _GreetingCard extends StatelessWidget {
  final String greeting;
  final String name;
  final String date;

  const _GreetingCard(
      {required this.greeting, required this.name, required this.date});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            Color.lerp(cs.primary, const Color(0xFF8B5CF6), 0.6)!
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $name!',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
