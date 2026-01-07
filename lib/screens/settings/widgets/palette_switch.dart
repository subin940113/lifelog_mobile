import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

class PaletteSwitch extends StatelessWidget {
  final Palette p;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PaletteSwitch({
    super.key,
    required this.p,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final trackOn = p.accent.withOpacity(0.95);
    final trackOff = p.ink.withOpacity(0.10);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? trackOn : trackOff,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: p.ink.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
