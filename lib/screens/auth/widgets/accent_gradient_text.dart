// lib/screens/auth/widgets/accent_gradient_text.dart
import 'package:flutter/material.dart';

class AccentGradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color accent;
  final TextAlign textAlign;

  const AccentGradientText({
    super.key,
    required this.text,
    required this.style,
    required this.accent,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final light = Color.lerp(accent, Colors.white, 0.12)!;
    final dark = Color.lerp(accent, Colors.black, 0.10)!;

    final child = Text(
      text,
      textAlign: textAlign,
      style: style?.copyWith(color: Colors.white),
      maxLines: 1,
      overflow: TextOverflow.visible,
    );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: const Alignment(-0.7, -1.0),
          end: const Alignment(0.8, 1.0),
          colors: [light, accent, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}