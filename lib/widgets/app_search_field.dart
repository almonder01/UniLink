import 'package:flutter/material.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry padding;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      hintText: hintText,
      leading: const Icon(Icons.search_rounded),
      onChanged: onChanged,
      trailing: controller.text.isEmpty
          ? null
          : [
              IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                  FocusScope.of(context).unfocus();
                },
              ),
            ],
      padding: WidgetStatePropertyAll(padding),
    );
  }
}
