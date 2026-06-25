import 'package:flutter/material.dart';

class ThreeDotButton extends StatelessWidget {
  final VoidCallback onTap;
  const ThreeDotButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.more_vert_rounded,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
