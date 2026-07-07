part of '../club_payment_screen.dart';

class _PaymentStatsGrid extends StatelessWidget {
  final ClubPaymentStats stats;

  const _PaymentStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth < 340 ? 1 : 2;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cards = [
          _PaymentStatCard(
            icon: Icons.request_quote_rounded,
            label: 'Requests',
            value: '${stats.requestCount}',
            color: const Color(0xFF6366F1),
          ),
          _PaymentStatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Submitted',
            value: '${stats.submittedReceipts}/${stats.expectedReceipts}',
            color: const Color(0xFF14B8A6),
          ),
          _PaymentStatCard(
            icon: Icons.today_rounded,
            label: 'Today',
            value: '${stats.todayReceipts}',
            color: const Color(0xFFF97316),
          ),
          _PaymentStatCard(
            icon: Icons.calendar_month_rounded,
            label: 'This Month',
            value: '${stats.monthReceipts}',
            color: const Color(0xFF22C55E),
          ),
        ];
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              cards.map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}
