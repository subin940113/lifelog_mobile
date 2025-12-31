import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

enum BrandLogoStyle {
  primary, // lifelog (accent, refined & tight)
}

class BrandLogo extends StatelessWidget {
  final Palette p;
  final BrandLogoStyle style;

  /// Controls visual size without hardcoding font size everywhere
  final double scale;

  const BrandLogo({
    super.key,
    required this.p,
    required this.style,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return _TypingLogo(p: p, scale: scale);
  }
}

class _TypingLogo extends StatefulWidget {
  final Palette p;
  final double scale;

  const _TypingLogo({required this.p, required this.scale});

  @override
  State<_TypingLogo> createState() => _TypingLogoState();
}

class _TypingLogoState extends State<_TypingLogo>
    with TickerProviderStateMixin {
  static const int _msPerChar = 220;
  static const Duration _loopPause = Duration(milliseconds: 650);
  static const String _text = 'lifelog';

  late final AnimationController _controller;
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _msPerChar * _text.length),
    );

    _controller.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        Future<void>.delayed(_loopPause, () {
          if (!mounted) return;
          _controller
            ..reset()
            ..forward();
        });
      }
    });

    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _controller.forward();
  }

  @override
  void dispose() {
    _blink.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final base = Theme.of(context).textTheme.headlineMedium;
    final style = base?.copyWith(
      color: p.accent,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.55,
      fontSize: (base?.fontSize ?? 34) * (widget.scale * 0.96),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value) * _text.length;
        final i = t.floor().clamp(0, _text.length);
        final frac = (t - i).clamp(0.0, 1.0);

        final prefix = _text.substring(0, i);
        final hasNext = i < _text.length;
        final nextChar = hasNext ? _text[i] : '';

        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: style,
            children: [
              TextSpan(text: prefix),
              if (hasNext) TextSpan(text: nextChar),
              // caret
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: FadeTransition(
                  opacity: _blink,
                  child: Transform.translate(
                    offset: const Offset(-1.2, 0),
                    child: Container(
                      width: 1.4,
                      height: (style?.fontSize ?? 34) * 0.9,
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
