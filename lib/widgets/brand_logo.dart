import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

/// bluelog 브랜드 로고
/// - 기본은 "정적 wordmark" (iOS스럽고 가장 깔끔)
/// - 필요할 때만 "typing" 애니메이션 사용
enum BrandLogoStyle {
  wordmark, // 기본: 정적
  typing, // 옵션: 타이핑 애니메이션
}

class BrandLogo extends StatelessWidget {
  final Palette p;
  final BrandLogoStyle style;

  /// Controls visual size without hardcoding font size everywhere
  final double scale;

  /// 로고 텍스트(기본: bluelog)
  final String text;

  /// wordmark 스타일 튜닝
  final FontWeight fontWeight;
  final double letterSpacing;

  /// ✅ 미미한 그라데이션 on/off
  final bool subtleGradient;

  /// typing 옵션
  final bool showCaret; // typing일 때 caret 표시
  final Duration loopPause;
  final int msPerChar;

  const BrandLogo({
    super.key,
    required this.p,
    this.style = BrandLogoStyle.wordmark,
    this.scale = 1.0,
    this.text = 'bluelog',
    this.fontWeight = FontWeight.w500,
    this.letterSpacing = -0.8,
    this.subtleGradient = true, // ✅ 기본 ON
    this.showCaret = false, // ✅ iOS스럽게: 기본은 caret 없음
    this.loopPause = const Duration(milliseconds: 650),
    this.msPerChar = 220,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case BrandLogoStyle.wordmark:
        return _WordmarkLogo(
          p: p,
          scale: scale,
          text: text,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          subtleGradient: subtleGradient,
        );
      case BrandLogoStyle.typing:
        return _TypingLogo(
          p: p,
          scale: scale,
          text: text,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          subtleGradient: subtleGradient,
          showCaret: showCaret,
          loopPause: loopPause,
          msPerChar: msPerChar,
        );
    }
  }
}

class _BrandGradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color accent;
  final bool enabled;
  final TextAlign textAlign;

  const _BrandGradientText({
    required this.text,
    required this.style,
    required this.accent,
    required this.enabled,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final s = style;

    // ✅ 그라데이션 대비를 "조금" 더 올림 (너무 유리/메탈로 안가게 10~12% 선)
    final light = Color.lerp(accent, Colors.white, 0.12)!; // 12%
    final dark = Color.lerp(accent, Colors.black, 0.10)!; // 10%

    // ✅ iOS스러운 아주 약한 텍스트 쉐도우(거의 안 튀게)
    final shadowedStyle = s?.copyWith(
      height: 1.08, // ✅ descender(g 등) 공간 확보
      shadows: const [],
    );

    if (!enabled) {
      return Text(
        text,
        textAlign: textAlign,
        style: shadowedStyle?.copyWith(color: accent),
        maxLines: 1,
        overflow: TextOverflow.visible,
        strutStyle: StrutStyle(
          fontSize: shadowedStyle?.fontSize,
          height: 1.15, // ✅ 추가 안전장치 (glyph 잘림 방지)
          forceStrutHeight: true,
        ),
      );
    }

    final child = Text(
      text,
      textAlign: textAlign,
      style: shadowedStyle?.copyWith(color: Colors.white),
      maxLines: 1,
      overflow: TextOverflow.visible,
      strutStyle: StrutStyle(
        fontSize: shadowedStyle?.fontSize,
        height: 1.15,
        forceStrutHeight: true,
      ),
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

class _WordmarkLogo extends StatelessWidget {
  final Palette p;
  final double scale;
  final String text;
  final FontWeight fontWeight;
  final double letterSpacing;
  final bool subtleGradient;

  const _WordmarkLogo({
    required this.p,
    required this.scale,
    required this.text,
    required this.fontWeight,
    required this.letterSpacing,
    required this.subtleGradient,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.headlineMedium;

    final style = base?.copyWith(
      fontFamily: 'MontserratAlternates',
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      fontSize: (base?.fontSize ?? 34) * (scale * 0.96),
      height: 1.0,
    );

    return _BrandGradientText(
      text: text,
      style: style,
      accent: p.accent,
      enabled: subtleGradient,
    );
  }
}

class _TypingLogo extends StatefulWidget {
  final Palette p;
  final double scale;
  final String text;
  final FontWeight fontWeight;
  final double letterSpacing;
  final bool subtleGradient;

  final bool showCaret;
  final Duration loopPause;
  final int msPerChar;

  const _TypingLogo({
    required this.p,
    required this.scale,
    required this.text,
    required this.fontWeight,
    required this.letterSpacing,
    required this.subtleGradient,
    required this.showCaret,
    required this.loopPause,
    required this.msPerChar,
  });

  @override
  State<_TypingLogo> createState() => _TypingLogoState();
}

class _TypingLogoState extends State<_TypingLogo>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _blink;

  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.msPerChar * widget.text.length),
    );

    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _controller.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        _pauseTimer?.cancel();
        _pauseTimer = Timer(widget.loopPause, () {
          if (!mounted) return;
          _controller
            ..reset()
            ..forward();
        });
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _blink.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final base = Theme.of(context).textTheme.headlineMedium;

    final style = base?.copyWith(
      fontWeight: widget.fontWeight,
      letterSpacing: widget.letterSpacing,
      fontSize: (base?.fontSize ?? 34) * (widget.scale * 0.96),
      height: 1.0,
    );

    final fullText = widget.text;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value) * fullText.length;
        final i = t.floor().clamp(0, fullText.length);
        final prefix = fullText.substring(0, i);
        final hasNext = i < fullText.length;
        final nextChar = hasNext ? fullText[i] : '';

        // ✅ 지금까지 타이핑된 문자열
        final typed = '$prefix${hasNext ? nextChar : ''}';

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _BrandGradientText(
              text: typed,
              style: style,
              accent: p.accent,
              enabled: widget.subtleGradient,
              textAlign: TextAlign.center,
            ),
            if (widget.showCaret)
              FadeTransition(
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
          ],
        );
      },
    );
  }
}
