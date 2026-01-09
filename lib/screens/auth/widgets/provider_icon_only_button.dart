// lib/screens/auth/widgets/provider_icon_only_button.dart
import 'package:flutter/material.dart';

class ProviderIconOnlyButton extends StatelessWidget {
  final String iconAsset;
  final VoidCallback? onTap;
  final bool pressed;
  final ValueChanged<bool> onPressedStateChanged;

  const ProviderIconOnlyButton({
    super.key,
    required this.iconAsset,
    required this.onTap,
    required this.pressed,
    required this.onPressedStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (onTap == null) return;
        onPressedStateChanged(true);
      },
      onTapUp: (_) {
        if (onTap == null) return;
        onPressedStateChanged(false);
      },
      onTapCancel: () {
        if (onTap == null) return;
        onPressedStateChanged(false);
      },
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: onTap == null ? 0.55 : (pressed ? 0.55 : 1.0),
        child: const SizedBox(
          width: 64,
          height: 64,
          child: Center(),
        ),
      ),
    );
  }
}