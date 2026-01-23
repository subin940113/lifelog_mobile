import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

/// 기존 main_page.dart의 _TopInsightPreview를 public으로 분리한 모델
class TopInsightPreview {
  final DateTime date;
  final String headline;
  final int signalCount;
  final List<String> axes;
  final String lastTimeLabel;

  const TopInsightPreview({
    required this.date,
    required this.headline,
    required this.signalCount,
    required this.axes,
    required this.lastTimeLabel,
  });
}

/// 메인 상단에 표시되는 “Signal Object + 카피” 카드
class SignalObjectCard extends StatefulWidget {
  final Palette p;
  final TopInsightPreview top;

  final bool isLoading;
  final bool hasError;

  /// ✅ totalCandy를 중앙 숫자로 표시하기 위한 값
  /// - 0이면 표시하지 않음
  /// - 999 초과면 999+ 로 표시
  final int totalCandy;

  /// ✅ 오브젝트(Blob) 위에 얹는 오버레이 (예: SignalOrbitOverlay)
  /// 주의: 오버레이는 Blob 내부에만 그리는 게 아니라, “주변”에 존재할 수 있음
  final Widget? blobOverlay;

  /// ✅ Blob(오브젝트) 자체를 탭했을 때만 동작 (물방울 탭과 분리하기 위함)
  final VoidCallback? onTapBlob;

  const SignalObjectCard({
    super.key,
    required this.p,
    required this.top,
    required this.isLoading,
    required this.hasError,
    this.totalCandy = 0,
    this.blobOverlay,
    this.onTapBlob,
  });

  @override
  State<SignalObjectCard> createState() => _SignalObjectCardState();
}

class _SignalObjectCardState extends State<SignalObjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;

    // NOTE: 외곽선이 얇아 보이는 주 원인이 Transform.scale의 미세 리샘플링이라,
    //       카드 레벨 스케일 애니메이션은 제거(=1.0 고정)하고 BlobPainter의 path wobble만 사용한다.
    final scale = AlwaysStoppedAnimation<double>(1.0);

    final tilt = Tween<double>(
      begin: -0.010,
      end: 0.010,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasOverlay = widget.blobOverlay != null;

    // 물방울(overlay)이 없을 때는 캔버스를 줄여 “휑함”을 줄이고,
    // 있을 때는 주변 공간을 확보한다.
    final canvasW = hasOverlay ? 248.0 : 136.0;
    final canvasH = hasOverlay ? 196.0 : 136.0;

    // blob 위치: 오버레이 유무와 관계없이 항상 같은 위치에 유지
    final blobTopPad = 0.0;

    // overlay(물방울)만 추가로 바깥으로 밀어내기
    final overlayTranslateY = hasOverlay ? 16.0 : 0.0;
    final overlayScale = hasOverlay ? 1.10 : 1.0;

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Transform.rotate(
                angle: tilt.value,
                child: Transform.scale(
                  scale: scale.value,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      // ✅ overlay 유무에 따라 캔버스 크기를 자동 조절
                      width: canvasW,
                      height: canvasH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Blob은 상단 중앙에 고정(128x128) + “Blob만” 탭 가능
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.only(top: blobTopPad),
                              child: SizedBox(
                                width: 128,
                                height: 128,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: widget.onTapBlob,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(128, 128),
                                        painter: BlobPainter(
                                          accent: p.accent,
                                          t: _c.value,
                                          hasSignal: widget.top.signalCount > 0,
                                          signalCount: widget.top.signalCount,
                                          isDark: isDark,
                                          strokeLight: Palette.strokeLight,
                                          strokeDark: Palette.strokeDark,
                                        ),
                                      ),

                                      // ✅ totalCandy 중앙 숫자 (0이면 숨김)
                                      if (!widget.isLoading && !widget.hasError && widget.totalCandy > 0)
                                        _CandyCountCenterLabel(
                                          p: widget.p,
                                          value: widget.totalCandy,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ✅ 오버레이는 “바깥 캔버스(canvasW/canvasH)” 레벨에서 채우되,
                          // 반드시 Blob "위" 레이어에 둬서 물방울 탭이 가로막히지 않게 한다.
                          if (widget.blobOverlay != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: false,
                                child: Transform.translate(
                                  offset: Offset(0, overlayTranslateY),
                                  child: Transform.scale(
                                    scale: overlayScale,
                                    alignment: Alignment.topCenter,
                                    child: widget.blobOverlay!,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: hasOverlay ? 0 : 10),
          Text(
            widget.isLoading
                ? '기록을 불러오는 중…'
                : (widget.hasError
                      ? '기록을 불러오지 못했어요'
                      : (widget.top.signalCount == 0
                            ? '아직 생각들이 모이지 않았어요'
                            : '생각들이 조금씩 모이고 있어요')),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: p.ink,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 1.25,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.top.axes.isEmpty
                ? (widget.top.lastTimeLabel == '—'
                      ? '기록이 쌓이면 형태가 천천히 변해요.'
                      : '마지막 기록: ${widget.top.lastTimeLabel}')
                : widget.top.axes.take(4).join(' · '),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: p.muted.withOpacity(0.85),
              fontWeight: FontWeight.w500,
              height: 1.4,
              fontSize: 15.5,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class BlobPainter extends CustomPainter {
  final Color accent;
  final double t; // 0..1 repeating
  final bool hasSignal;
  final bool isDark;
  final Color strokeLight;
  final Color strokeDark;
  final int signalCount;

  BlobPainter({
    required this.accent,
    required this.t,
    required this.hasSignal,
    required this.signalCount,
    required this.isDark,
    required this.strokeLight,
    required this.strokeDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final baseR = (w < h ? w : h) * 0.46;

    final wobble = 0.030 + (hasSignal ? 0.012 : 0.0);
    final phase = t * 2 * math.pi;

    final bulgeAmp = 0.022 + (hasSignal ? 0.010 : 0.0);
    final bulgeAngle = phase * 0.85 + 0.6;

    final path = Path();
    const steps = 96;

    for (int i = 0; i <= steps; i++) {
      final a = (i / steps) * 2 * math.pi;

      final k1 = math.sin(a * 2.0 + phase);
      final k2 = math.sin(a * 3.0 - phase * 0.7);
      final k3 = math.sin(a * 5.0 + phase * 0.35);

      final d = _wrapAngle(a - bulgeAngle);
      final bulge = math.exp(-(d * d) / 0.55) * bulgeAmp;

      final r =
          baseR * (1.0 + wobble * (0.55 * k1 + 0.30 * k2 + 0.15 * k3) + bulge);

      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final rect = Rect.fromLTWH(0, 0, w, h);

    // --- begin hard clip layer ---
    canvas.saveLayer(rect, Paint());

    // draw mask
    canvas.drawPath(path, Paint()..color = Colors.white);

    // everything after this must be clipped to the blob
    canvas.saveLayer(rect, Paint()..blendMode = BlendMode.srcIn);

    const cTop0 = Color(0xFFD6F3FF);
    const cMid0 = Color(0xFF9AD8FA);
    const cBot0 = Color(0xFFF7FDFF);

    Color lift(Color c, double amt) => Color.lerp(c, Colors.white, amt)!;

    final outline = isDark ? strokeDark : strokeLight;

    final cTop = isDark ? lift(cTop0, 0.10) : cTop0;
    final cMid = isDark ? lift(cMid0, 0.08) : cMid0;
    final cBot = isDark ? lift(cBot0, 0.06) : cBot0;

    final rot = math.pi; // ~180deg

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.24, -0.30),
        radius: 1.06,
        colors: <Color>[
          cTop.withOpacity(0.985),
          cMid.withOpacity(0.905),
          cBot.withOpacity(0.985),
        ],
        stops: const <double>[0.0, 0.46, 1.0],
        transform: GradientRotation(rot),
      ).createShader(rect);

    final overlayPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: const Alignment(-0.70, -0.55),
        end: const Alignment(0.75, 0.85),
        transform: GradientRotation(rot),
        colors: <Color>[
          Colors.white.withOpacity(0.12),
          const Color(0xFF79BDEB).withOpacity(0.095),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(rect);

    final vignettePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(0.05, -0.12),
        radius: 1.25,
        colors: <Color>[
          Colors.transparent,
          const Color(0xFF6FB3E3).withOpacity(0.030),
        ],
        stops: const <double>[0.70, 1.0],
        transform: GradientRotation(rot),
      ).createShader(rect);

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, overlayPaint);
    canvas.drawPath(path, vignettePaint);

    // -----------------------------------------------------------------

    final tex = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final a = (i * 0.92 + t * 6.2) % (2 * math.pi);
      final rr = baseR * (0.16 + 0.48 * ((i % 5) / 5.0));
      final dx = math.cos(a) * rr * 0.55;
      final dy = math.sin(a * 1.12) * rr * 0.45;

      final rDot = 2.6 + (i % 4) * 1.1;
      final o = 0.020 + (i % 3) * 0.008;

      tex.color = (i.isEven ? Colors.white : const Color(0xFF8BC9F3))
          .withOpacity(o);
      canvas.drawCircle(Offset(center.dx + dx, center.dy + dy), rDot, tex);
    }

    // HandDrawnWaveDivider와 동일 두께/톤 (라이트 1.4 / 다크 3.0)
    // 다만, 내부 그라데이션 대비 때문에 체감 두께가 얇아질 수 있어
    // 매우 약한 언더코트를 한 번 더 깔아 “보이는 두께”를 맞춘다.
    final underStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isDark ? 3.0 : 1.4) + (isDark ? 1.0 : 0.9)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = outline.withOpacity(isDark ? 0.16 : 0.18);
    canvas.drawPath(path, underStroke);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 3.0 : 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = outline.withOpacity(isDark ? 0.88 : 0.68);
    canvas.drawPath(path, strokePaint);

    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.70
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = (isDark ? strokeDark : strokeLight).withOpacity(
        isDark ? 0.16 : 0.12,
      );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(0.988, 0.988);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, innerStroke);
    canvas.restore();

    canvas.restore(); // srcIn layer
    canvas.restore(); // base layer
    // --- end hard clip layer ---
  }

  @override
  bool shouldRepaint(covariant BlobPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.accent.value != accent.value ||
        oldDelegate.hasSignal != hasSignal ||
        oldDelegate.signalCount != signalCount ||
        oldDelegate.isDark != isDark;
  }

  double _wrapAngle(double a) {
    var x = a;
    while (x > math.pi) x -= 2 * math.pi;
    while (x < -math.pi) x += 2 * math.pi;
    return x;
  }
}

class _CandyCountCenterLabel extends StatefulWidget {
  final Palette p;
  final int value;

  const _CandyCountCenterLabel({
    required this.p,
    required this.value,
  });

  @override
  State<_CandyCountCenterLabel> createState() => _CandyCountCenterLabelState();
}

class _CandyCountCenterLabelState extends State<_CandyCountCenterLabel>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool _isMilestone(int v) => v > 0 && (v % 10 == 0);

  String _format(int v) => v > 999 ? '999+' : v.toString();

  int _hash32(String s) {
    var h = 2166136261;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 16777619) & 0xFFFFFFFF;
    }
    return h;
  }

  // ✅ 자리수(글자)별로 따로 부유하는 숫자 + (조건부) 느낌표를 "바로 옆"에 붙여 렌더
  Widget _buildFloatingNumber({
    required String text,
    required TextStyle style,
    required double t,
  }) {
    final runes = text.runes.toList(growable: false);

    // Inline milestone mark settings (independent micro-float, but anchored next to number)
    final showMark = _showMark(widget.value);
    final hMark = _hash32('mark|${widget.value}');
    final uMark = ((hMark & 0xFFFF) / 0xFFFF);
    final vMark = (((hMark >> 16) & 0xFFFF) / 0xFFFF);

    final ampX = 0.5 + 0.8 * uMark; // 0.5..1.3px
    final ampY = 0.9 + 1.5 * vMark; // 0.9..2.4px

    final dxMark = ampX * math.sin(t * (1.12 + 0.25 * uMark) + 1.9);
    final dyMark = ampY * math.sin(t * (1.02 + 0.22 * vMark) + 2.6);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...List<Widget>.generate(runes.length, (i) {
            final ch = String.fromCharCode(runes[i]);

            // Stable per-glyph seed
            final h = _hash32('${widget.value}|$text|$i|$ch');
            final u = ((h & 0xFFFF) / 0xFFFF); // 0..1
            final v = (((h >> 16) & 0xFFFF) / 0xFFFF); // 0..1

            // “좌우 흔들림”은 거의 없게, “상하 부유”는 조금 더.
            final ampX = 0.10 + 0.30 * u; // 0.10..0.40px
            final ampY = 0.70 + 1.30 * v; // 0.70..2.00px

            final dx =
                ampX * math.sin(t * (1.10 + 0.35 * u) + i * 0.85 + u * 6.2);
            final dy =
                ampY * math.sin(t * (0.95 + 0.30 * v) + i * 0.92 + v * 5.4);

            return Transform.translate(
              offset: Offset(dx, dy),
              child: Text(ch, style: style),
            );
          }),

          if (showMark) ...[
            // Keep it very close to the number (avoid looking detached).
            const SizedBox(width: 1.5),
            IgnorePointer(
              child: Transform.translate(
                // Keep it "attached"; micro-float only
                offset: Offset(dxMark, dyMark),
                child: Text(
                  '!',
                  style: style.copyWith(
                    // Slightly tighter so it feels attached to the number
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


  bool _showMark(int v) => v == 1 || _isMilestone(v);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = (_c.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          // ✅ 숫자 색상: 오버레이와 동일한 원리로 테마에 맞게 보정
          // - Light: 잉크를 기준으로 accent를 아주 살짝 섞어 "블루로그" 톤
          // - Dark : scaffold bg 쪽으로 당겨 밝은 Blob 내부에서도 이질감 최소화
          final bg = Theme.of(context).scaffoldBackgroundColor;
          final textBase = widget.p.ink.withOpacity(isDark ? 0.92 : 0.88);
          final textColor = isDark
              ? Color.lerp(bg, widget.p.ink, 0.10)!.withOpacity(0.95)
              : Color.lerp(textBase, widget.p.accent, 0.10)!;

          // Blob과 톤 맞춘 “부유”: 상하 중심, 좌우 최소
          final dy = 2.6 * math.sin(t * 1.05) + 0.8 * math.sin(t * 0.52 + 1.1);
          final dx = 0.30 * math.sin(t * 0.62 + 2.4);

          final ang = 0.010 * math.sin(t * 0.78 + 0.9);
          final s = 1.0 + 0.008 * math.sin(t * 0.95 + 0.4);

          final text = _format(widget.value);
          final baseTextStyle = (Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                    fontFamily: 'MuseoModerno',
                    height: 1.0,
                    letterSpacing: -0.4,
                    // ✅ 숫자 주변 “하얀 막(글로우)” 제거
                    shadows: const <Shadow>[],
                  )) ??
              TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 20,
                height: 1.0,
                letterSpacing: -0.4,
              );

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: ang,
              child: Transform.scale(
                scale: s,
                child: _buildFloatingNumber(
                  text: text,
                  t: t,
                  style: baseTextStyle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}