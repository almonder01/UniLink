part of '../event_registration_dialog.dart';

class _RegistrationUploadBox extends StatelessWidget {
  final String? data;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RegistrationUploadBox({
    required this.data,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  bool get _hasData => (data ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 92,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hasData
                ? cs.primary.withValues(alpha: 0.55)
                : cs.onSurface.withValues(alpha: 0.12),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _hasData
            ? TappableBase64Image(data: data!)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: cs.primary, size: 24),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}
