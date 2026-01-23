import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

/// 색연필로 그린 듯한 물결 무늬 구분선
/// - 좌우 여백 없이 화면 끝까지
/// - 아래쪽만 그림자
/// - 스트로크 두께는 Signal Object 테두리와 동일(라이트 1.4 / 다크 3.0)
class HandDrawnWaveDivider extends StatelessWidget {
  /// 높이(레이아웃 여백 최소화 목적)
  final double height;

  /// 파동 패턴 변형을 위한 시드값 (0~2 사이의 값)
  final int waveSeed;

  const HandDrawnWaveDivider({super.key, this.height = 20, this.waveSeed = 0});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 시그널 오브젝트 테두리색과 동일 톤
    const outlineLight = Palette.strokeLight;
    const outlineDark = Palette.strokeDark;
    final outlineColor = isDark ? outlineDark : outlineLight;

    final waveColor = outlineColor.withOpacity(isDark ? 0.88 : 0.68);

    // NOTE
    // MainPage는 Padding(horizontal: 10) 안에서 Column/ScrollView를 구성한다.
    // 스크롤 시 Viewport 클리핑 때문에 "부모 밖으로 삐져나가 그리기"는 잘릴 수 있으므로,
    // 레이아웃 단계에서부터 full-bleed 폭을 확보한다.
    //
    // constraints.maxWidth = (screenW - 20)
    // fullW = (screenW - 20) + 20 = screenW
    // 그리고 -10 translate로 좌측 패딩을 상쇄하여 화면 좌우 끝까지 맞춘다.
    return LayoutBuilder(
      builder: (context, constraints) {
        final innerW = constraints.maxWidth; // screenW - 20
        final fullW = innerW + 20; // screenW

        return SizedBox(
          height: height,
          width: fullW,
          child: Transform.translate(
            offset: const Offset(-10, 0),
            child: SizedBox(
              width: fullW,
              height: height,
              child: CustomPaint(
                size: Size(fullW, height),
                painter: _HandDrawnWavePainter(
                  color: waveColor,
                  isDark: isDark,
                  screenWidth: fullW,
                  waveSeed: waveSeed,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HandDrawnWavePainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final double screenWidth;
  final int waveSeed;

  _HandDrawnWavePainter({
    required this.color,
    required this.isDark,
    required this.screenWidth,
    required this.waveSeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 화면 전체 폭을 직접 사용 (부모의 제약 무시)
    final width = screenWidth;
    final centerY = (size.height / 2) - 2;

    // 곡선 생성
    const numPoints = 220;
    final points = <Offset>[];

    // 좌/우 끝 여백이 보이지 않도록, 화면 밖으로 조금 더 그린 뒤 잘리게 한다.
    const bleed = 28.0;
    final drawWidth = width + bleed * 2;

    // 파형 변형을 위한 시드값 기반 오프셋
    final seedOffset = waveSeed * 0.7; // 각 구분선마다 다른 패턴
    final phaseOffset = waveSeed * 1.3;

    // 파형 (너무 넓지 않게)
    final baseAmplitude = 7.0 + waveSeed * 0.5; // 약간씩 다른 진폭
    final baseWavelength = drawWidth / (2.6 + waveSeed * 0.15); // 약간씩 다른 파장

    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      final x = -bleed + t * drawWidth;

      final wavePhase =
          t * math.pi * 2.0 * (drawWidth / baseWavelength) + phaseOffset;
      final freqMod =
          1.0 +
          (0.08 + waveSeed * 0.02) * math.sin(t * math.pi * 2.0 + seedOffset);
      final ampMod =
          1.0 +
          (0.12 + waveSeed * 0.03) *
              math.sin(t * math.pi * 1.5 + seedOffset * 0.7);

      final baseWave = math.sin(wavePhase * freqMod);
      final detailWave =
          (0.22 + waveSeed * 0.05) *
          math.sin(wavePhase * (2.0 + waveSeed * 0.1));

      final y = centerY + baseAmplitude * baseWave * ampMod + detailWave;
      points.add(Offset(x, y));
    }

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        if (i == 1) {
          path.lineTo(points[i].dx, points[i].dy);
        } else {
          final prev = points[i - 1];
          final curr = points[i];
          final next = i < points.length - 1 ? points[i + 1] : curr;

          final c1x = prev.dx + (curr.dx - prev.dx) * 0.5;
          final c1y = prev.dy;
          final c2x = curr.dx - (next.dx - curr.dx) * 0.3;
          final c2y = curr.dy;

          path.cubicTo(c1x, c1y, c2x, c2y, curr.dx, curr.dy);
        }
      }
    }

    /*
    // 아래쪽만 그림자 (카드 경계처럼 보이도록)
    final clipBelow = Path()
      ..addPath(path, Offset.zero)
      ..lineTo(width + 80, size.height + 80)
      ..lineTo(-80, size.height + 80)
      ..close();

    canvas.save();
    canvas.clipPath(clipBelow);

    final shadowOffsetY = isDark ? 7.0 : 6.0;

    // 큰/진한 그림자
    final shadowSoft = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.26 : 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 11.0 : 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path.shift(Offset(0, shadowOffsetY)), shadowSoft);

    // 접지 그림자(더 선명)
    final shadowTight = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.18 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 5.2 : 4.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path.shift(Offset(0, shadowOffsetY)), shadowTight);

    canvas.restore();
*/

    // 구분선 스트로크
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      // Signal Object 테두리 두께와 동일
      ..strokeWidth = isDark ? 3.0 : 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _HandDrawnWavePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isDark != isDark ||
        oldDelegate.waveSeed != waveSeed ||
        oldDelegate.screenWidth != screenWidth;
  }
}
