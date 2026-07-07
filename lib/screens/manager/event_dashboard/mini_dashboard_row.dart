part of '../event_dashboard_tab.dart';

class _MiniDashboardRow extends StatelessWidget {
  final String firstLabel;
  final String firstValue;
  final String secondLabel;
  final String secondValue;

  const _MiniDashboardRow({
    required this.firstLabel,
    required this.firstValue,
    required this.secondLabel,
    required this.secondValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniStat(label: firstLabel, value: firstValue)),
        const SizedBox(width: 8),
        Expanded(child: _MiniStat(label: secondLabel, value: secondValue)),
      ],
    );
  }
}
