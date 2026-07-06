part of '../profile_screen.dart';

class _GenderFieldCard extends StatelessWidget {
  final String? gender;
  final ValueChanged<String> onChanged;

  const _GenderFieldCard({
    required this.gender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          initialValue: gender == 'female' || gender == 'male' ? gender : null,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.people_outline_rounded),
          ),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Theme.of(context).colorScheme.surface,
          items: [
            DropdownMenuItem(
              value: 'male',
              child: Row(
                children: [
                  Icon(Icons.male_rounded, color: cs.primary),
                  const SizedBox(width: 10),
                  const Text('Male'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'female',
              child: Row(
                children: [
                  Icon(Icons.female_rounded, color: cs.primary),
                  const SizedBox(width: 10),
                  const Text('Female'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ),
    );
  }
}
