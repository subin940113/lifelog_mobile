import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';

/// Field Layout 버전:
/// - 궤도(orbit) 개념 제거
/// - 좌/우 "벽 필드" 안에 물방울이 안정적으로 배치
/// - per-frame 에서는 base 위치를 유지하고, 아주 작은 drift만 추가 (끊김/점프 없음)
/// - 겹침은 base 배치 단계에서 해결 (pair relaxation)
class SignalOrbitOverlay extends StatefulWidget {
  final Palette p;
  final List<WaterDropVm> drops;
  final void Function(String keywordKey, String? insightText) onTapDrop;
  final int candyCount;

  /// Blob(128) 기준. overlay는 blob 위에 Positioned.fill로 올라오므로
  /// blob center는 (w/2, objectSize/2)로 잡는 게 안전.
  final double objectSize;

  const SignalOrbitOverlay({
    super.key,
    required this.p,
    required this.drops,
    required this.onTapDrop,
    required this.candyCount,
    this.objectSize = 128,
  });

  @override
  State<SignalOrbitOverlay> createState() => _SignalOrbitOverlayState();
}

class _SignalOrbitOverlayState extends State<SignalOrbitOverlay>
    with SingleTickerProviderStateMixin {
  // bubble sizing constraints
  static const double _maxBubbleR = 30.0;
  static const double _minBubbleR = 18.0;

  // safe padding inside overlay bounds
  static const double _edgePad = 10.0;

  // how close to wall we allow (smaller = closer to wall)
  static const double _wallInset = 6.0;

  // vertical distribution: keep bubbles around blob, not too low
  static const double _topGuard = 2.0; // avoid going above overlay too much
  static const double _bottomGuard = 10.0;

  // cached base layout to avoid jitter/popping
  Size? _lastBounds;
  List<String> _lastKeys = const <String>[];
  List<int> _lastCandy = const <int>[];
  List<Offset> _basePositions = const <Offset>[];

  bool _sameList<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  int _hash32(String s) {
    var h = 2166136261;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 16777619) & 0xFFFFFFFF;
    }
    return h;
  }

  Color _tintForKeyword(Palette p, String keyword, bool isDark) {
    final h = _hash32(keyword);
    final u = ((h & 0xFFFF) / 0xFFFF); // 0..1

    // subtle tint variation only
    final w = (0.06 + 0.10 * u).clamp(0.06, 0.16);
    final ww = isDark ? (w + 0.02).clamp(0.08, 0.18) : w;

    return Color.lerp(p.accent, Colors.white, ww)!;
  }

  double _estimateBubbleRadius({
    required String keywordKey,
    required int candyCount,
    required int index,
  }) {
    final len = keywordKey.runes.length;
    final lenFactor = ((len - 2) / 10.0).clamp(0.0, 1.0);

    final hKey = _hash32(keywordKey);
    final keyJitter = (((hKey >> 8) & 0xFF) / 255.0);
    final sizeJitter = (keyJitter - 0.5) * 2.0;

    const maxForFull = 24;
    final cLevel = (candyCount.clamp(0, maxForFull) / maxForFull).toDouble();
    final cK = math.pow(cLevel, 0.55).toDouble();
    final candyScale = 1.0 + 0.55 * cK;

    final baseSize =
        ((30.0 + (index % 3) * 1.2) + (9.0 * lenFactor) + (3.2 * sizeJitter)) *
        candyScale;

    final r = (baseSize * 0.5).clamp(_minBubbleR, _maxBubbleR);
    return r;
  }

  void _ensureLayout({
    required Size bounds,
    required Offset blobCenter,
    required List<String> keys,
    required List<int> candyCounts,
  }) {
    final need =
        _lastBounds != bounds ||
        !_sameList(_lastKeys, keys) ||
        !_sameList(_lastCandy, candyCounts);

    if (!need) return;

    _lastBounds = bounds;
    _lastKeys = List<String>.from(keys, growable: false);
    _lastCandy = List<int>.from(candyCounts, growable: false);

    _basePositions = _computeFieldPositions(
      bounds: bounds,
      blobCenter: blobCenter,
      keys: _lastKeys,
      candyCounts: _lastCandy,
    );
  }

  List<Offset> _applyFloat(List<Offset> base, List<String> keys, double t) {
    if (base.isEmpty) return base;

    // Seamless, small drift (no re-seeding per frame).
    final out = <Offset>[];
    for (int i = 0; i < base.length; i++) {
      final p0 = base[i];
      final h = _hash32(keys[i]);
      final u = ((h & 0xFFFF) / 0xFFFF);
      final v = (((h >> 16) & 0xFFFF) / 0xFFFF);

      // 2.0..4.0px, subtle
      final ampX = 2.0 + 2.0 * u;
      final ampY = 2.2 + 2.2 * v;

      final dx = ampX * math.sin(t * 0.55 + i * 1.11 + u * 6.1);
      final dy = ampY * math.sin(t * 0.48 + i * 0.97 + v * 5.2);

      out.add(Offset(p0.dx + dx, p0.dy + dy));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.drops.isEmpty && widget.candyCount <= 0) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: false,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, cs) {
              final w = cs.maxWidth;
              final h = cs.maxHeight;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              // blob center (overlay fills card, blob sits at top)
              // NOTE: SignalObjectCard 쪽에서 상단 여백을 줄이면(오브젝트가 위로 붙으면)
              // overlay는 Positioned.fill 특성상 상대적으로 아래로 내려가 보일 수 있음.
              // blob 기준점을 약간 위로 당겨(shiftY) 오버레이도 함께 올라가도록 보정한다.
              const double _blobCenterShiftY = 18.0;
              final blobCenter = Offset(
                w / 2,
                math.max(0.0, widget.objectSize / 2 - _blobCenterShiftY),
              );

              // visible drops: stable ordering to prevent layout shuffle
              final visible = widget.drops.take(6).toList(growable: false)
                ..sort((a, b) => a.keywordKey.compareTo(b.keywordKey));

              final keys = visible
                  .map((e) => e.keywordKey)
                  .toList(growable: false);
              final candyCounts = visible
                  .map((e) => e.candyCount)
                  .toList(growable: false);

              // round bounds a bit to avoid re-layout flicker on fractional pixels
              final roundedW = (w * 2).round() / 2.0;
              final roundedH = (h * 2).round() / 2.0;
              final bounds = Size(roundedW, roundedH);

              _ensureLayout(
                bounds: bounds,
                blobCenter: blobCenter,
                keys: keys,
                candyCounts: candyCounts,
              );

              final t = (_c.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
              final positions = _applyFloat(_basePositions, keys, t);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < visible.length; i++)
                    _buildDropAt(
                      context: context,
                      pos: positions[i],
                      index: i,
                      keywordKey: visible[i].keywordKey,
                      candyCount: visible[i].candyCount,
                      insightText: visible[i].insightText,
                      isDark: isDark,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Field Layout:
  /// - left field near left wall
  /// - right field near right wall
  /// - y is distributed around blobCenter.dy with bounded range (prevents "too low")
  /// - then relax overlaps
  List<Offset> _computeFieldPositions({
    required Size bounds,
    required Offset blobCenter,
    required List<String> keys,
    required List<int> candyCounts,
  }) {
    final count = keys.length;
    if (count == 0) return const <Offset>[];

    // assign left/right counts (max 3 each) - stable by hashed ranking
    int leftCount;
    if (count == 1) {
      leftCount =
          0; // single defaults to right for visual balance vs hamburger left
    } else if (count == 2) {
      leftCount = 1;
    } else if (count == 3) {
      final flip = (_hash32(keys.join('|')) & 1) == 1;
      leftCount = flip ? 2 : 1;
    } else if (count == 4) {
      leftCount = 2;
    } else if (count == 5) {
      final flip = (_hash32(keys.join('|')) & 1) == 1;
      leftCount = flip ? 3 : 2;
    } else {
      leftCount = 3;
    }

    final idx = List<int>.generate(count, (i) => i);
    idx.sort((a, b) => _hash32(keys[a]).compareTo(_hash32(keys[b])));
    final leftIdx = idx.take(leftCount).toList(growable: false);
    final rightIdx = idx.skip(leftCount).toList(growable: false);

    // estimate radii
    final radii = List<double>.generate(count, (i) {
      return _estimateBubbleRadius(
        keywordKey: keys[i],
        candyCount: candyCounts[i],
        index: i,
      );
    });

    // safe bounds (bubble center limits)
    final minX = _edgePad + _minBubbleR;
    final maxX = bounds.width - _edgePad - _minBubbleR;

    // vertical range: keep around blob, not too low.
    // Use blobCenter.dy as anchor, allow spread but clamp.
    // upper limit not too high, lower limit not too low
    final minY = _topGuard + _minBubbleR;
    final maxY = math.min(
      bounds.height - _bottomGuard - _minBubbleR,
      blobCenter.dy + 72.0, // << 이 값이 "아래로 내려가는 느낌"을 결정함
    );

    // field X anchors (near walls)
    // allow big bubbles to get closer while still not clipping
    double leftX(int i) {
      final r = radii[i];
      return (0.0 + _wallInset + r).clamp(minX, maxX);
    }

    double rightX(int i) {
      final r = radii[i];
      return (bounds.width - _wallInset - r).clamp(minX, maxX);
    }

    // y slots: distribute within a band centered around blobCenter.dy
    // wide enough to feel "넓게 분포" but not so low that it creates dead space.
    List<double> ySlots(int n) {
      if (n <= 0) return const [];
      final bandTop = (blobCenter.dy - 24.0).clamp(minY, maxY);
      final bandBot = (blobCenter.dy + 62.0).clamp(minY, maxY);
      if (n == 1) return [(bandTop + bandBot) * 0.5];
      final step = (bandBot - bandTop) / (n - 1);
      return List<double>.generate(n, (k) => bandTop + step * k);
    }

    final leftYs = ySlots(leftIdx.length);
    final rightYs = ySlots(rightIdx.length);

    final pts = List<Offset>.filled(count, Offset.zero);

    void placeSide(List<int> ids, List<double> ys, bool isLeft) {
      for (int s = 0; s < ids.length; s++) {
        final i = ids[s];
        final h = _hash32(keys[i]);
        final u = ((h & 0xFFFF) / 0xFFFF); // 0..1
        final v = (((h >> 16) & 0xFFFF) / 0xFFFF); // 0..1

        // small deterministic jitter, but stable
        final jy = (u - 0.5) * 18.0; // -9..9
        final jx = (v - 0.5) * 10.0; // -5..5

        final x0 = isLeft ? leftX(i) : rightX(i);
        final x = (x0 + jx).clamp(minX, maxX);

        final y0 = ys[s];
        final y = (y0 + jy).clamp(minY, maxY);

        pts[i] = Offset(x, y);
      }
    }

    placeSide(leftIdx, leftYs, true);
    placeSide(rightIdx, rightYs, false);

    // overlap relaxation (pair-wise)
    const gap = 12.0;
    const maxIter = 42;

    Offset clampCenter(Offset p, int i) {
      final r = radii[i];
      final cxMin = _edgePad + r;
      final cxMax = bounds.width - _edgePad - r;
      final cyMin = _topGuard + r;
      final cyMax = math.min(
        bounds.height - _bottomGuard - r,
        blobCenter.dy + 72.0,
      );

      return Offset(p.dx.clamp(cxMin, cxMax), p.dy.clamp(cyMin, cyMax));
    }

    for (int iter = 0; iter < maxIter; iter++) {
      var any = false;
      for (int i = 0; i < count; i++) {
        for (int j = i + 1; j < count; j++) {
          final pi = pts[i];
          final pj = pts[j];
          final dx = pj.dx - pi.dx;
          final dy = pj.dy - pi.dy;
          final d2 = dx * dx + dy * dy;
          if (d2 < 0.0001) continue;

          final d = math.sqrt(d2);
          final target = radii[i] + radii[j] + gap;
          if (d < target) {
            any = true;
            final nx = dx / d;
            final ny = dy / d;
            final overlap = target - d;

            final gain = 1.10 - 0.30 * (iter / maxIter);
            final push = 0.5 * overlap * gain;

            pts[i] = clampCenter(
              Offset(pi.dx - nx * push, pi.dy - ny * push),
              i,
            );
            pts[j] = clampCenter(
              Offset(pj.dx + nx * push, pj.dy + ny * push),
              j,
            );
          }
        }
      }
      if (!any) break;
    }

    // final pass: slight pull toward wall to satisfy “벽쪽으로 붙어도 될 듯”
    // (but still clamped to avoid clipping)
    for (int i = 0; i < count; i++) {
      final isLeft = leftIdx.contains(i);
      final r = radii[i];

      final wallX = isLeft ? (_wallInset + r) : (bounds.width - _wallInset - r);

      final p = pts[i];
      final pulled = Offset(
        // 35%만 벽쪽으로 당겨 과도한 박힘 방지
        p.dx + (wallX - p.dx) * 0.50,
        p.dy,
      );
      pts[i] = clampCenter(pulled, i);
    }

    return pts;
  }

  Widget _buildFloatingKeywordLabel({
    required String text,
    required TextStyle style,
    required double t,
  }) {
    // Character-level subtle float.
    // NOTE: Do NOT ClipRect here. Each glyph translates a few pixels; clipping makes
    // the first/last glyph look "cut" as they drift.

    final chars = text.runes.toList(growable: false);

    // Add a small horizontal safety padding so drifting glyphs have room.
    // Use FittedBox(scaleDown) so longer keywords still fit without hard clipping.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List<Widget>.generate(chars.length, (i) {
            final ch = String.fromCharCode(chars[i]);

            // Stable per-character phase/amp based on hash(text + index)
            final h = _hash32('$text|$i');
            final u = ((h & 0xFFFF) / 0xFFFF); // 0..1
            final v = (((h >> 16) & 0xFFFF) / 0xFFFF); // 0..1

            // 0.7..1.6px (x), 1.0..2.3px (y)
            final ampX = 0.7 + 0.9 * u;
            final ampY = 1.0 + 1.3 * v;

            // Slightly different frequencies so letters don’t move in lockstep.
            final dx = ampX * math.sin(t * 1.15 + i * 0.85 + u * 6.2);
            final dy = ampY * math.sin(t * 1.05 + i * 0.92 + v * 5.4);

            return Transform.translate(
              offset: Offset(dx, dy),
              child: Text(ch, style: style),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDropAt({
    required BuildContext context,
    required Offset pos,
    required int index,
    required String keywordKey,
    required int candyCount,
    required String? insightText,
    required bool isDark,
  }) {
    // For UI text rendering: truncate long keywords with ellipsis.
    final displayText = keywordKey.length > 4
        ? '${keywordKey.substring(0, 4)}…'
        : keywordKey;
    final t = (_c.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
    final phase = t;

    final len = keywordKey.runes.length;
    final lenFactor = ((len - 2) / 10.0).clamp(0.0, 1.0);

    final hKey = _hash32(keywordKey);
    final keyJitter = (((hKey >> 8) & 0xFF) / 255.0);
    final sizeJitter = (keyJitter - 0.5) * 2.0;

    const maxForFull = 24;
    final cLevel = (candyCount.clamp(0, maxForFull) / maxForFull).toDouble();
    final cK = math.pow(cLevel, 0.55).toDouble();
    final candyScale = 1.0 + 0.55 * cK;

    final baseSize =
        ((30.0 + (index % 3) * 1.2) + (9.0 * lenFactor) + (3.2 * sizeJitter)) *
        candyScale;

    final breath =
        1.0 +
        (0.024 + 0.010 * lenFactor + 0.004 * keyJitter) *
            math.sin(phase * 1.10 + index * 1.05);

    final size = (baseSize * breath).clamp(36.0, _maxBubbleR * 2);

    final fontSize = (12.6 + 2.0 * lenFactor).clamp(12.6, 14.8);

    final accentTint = _tintForKeyword(widget.p, keywordKey, isDark);

    // Text color:
    // - Light mode: slightly tinted ink (current behavior)
    // - Dark mode: use the app background color so it stays readable on brighter drops
    final textBase = widget.p.ink.withOpacity(isDark ? 0.92 : 0.86);
    final bg = Theme.of(context).scaffoldBackgroundColor;

    final textTint = isDark
        ? Color.lerp(bg, widget.p.ink, 0.08)!.withOpacity(0.95)
        : Color.lerp(textBase, accentTint, 0.10)!;

    final x = pos.dx;
    final y = pos.dy;

    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTapDrop(keywordKey, insightText),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _MiniBlobPainter(
                accent: accentTint,
                t: ((t + (index * 0.07)) % 1.0),
                isDark: isDark,
                strokeLight: Palette.strokeLight,
                strokeDark: Palette.strokeDark,
              ),
            ),
            // Clip the drifting glyphs to the exact mini-blob shape so they can
            // never escape the bubble boundary.
            Positioned.fill(
              child: ClipPath(
                clipper: _MiniBlobClipper(t: ((t + (index * 0.07)) % 1.0)),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildFloatingKeywordLabel(
                      text: displayText,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: textTint,
                            fontWeight: FontWeight.w500,
                            fontSize: fontSize,
                            height: 1.0,
                            letterSpacing: -0.2,
                          ) ??
                          TextStyle(
                            color: textTint,
                            fontWeight: FontWeight.w500,
                            fontSize: fontSize,
                            height: 1.0,
                            letterSpacing: -0.2,
                          ),
                      t: t,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaterDropVm {
  final String keywordKey;
  final int candyCount;
  final String? insightText;
  const WaterDropVm({
    required this.keywordKey,
    required this.candyCount,
    this.insightText,
  });
}

class _MiniBlobClipper extends CustomClipper<Path> {
  final double t; // 0..1

  const _MiniBlobClipper({required this.t});

  double _wrapAngle(double a) {
    var x = a;
    while (x > math.pi) x -= 2 * math.pi;
    while (x < -math.pi) x += 2 * math.pi;
    return x;
  }

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final baseR = math.min(w, h) * 0.46;

    final phase = t * 2 * math.pi;
    const steps = 80;
    final wobble = 0.028;
    final bulgeAmp = 0.018;
    final bulgeAngle = phase * 0.85 + 0.6;

    final path = Path();
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
    return path;
  }

  @override
  bool shouldReclip(covariant _MiniBlobClipper oldClipper) {
    return oldClipper.t != t;
  }
}

class _MiniBlobPainter extends CustomPainter {
  final Color accent;
  final double t; // 0..1
  final bool isDark;
  final Color strokeLight;
  final Color strokeDark;

  _MiniBlobPainter({
    required this.accent,
    required this.t,
    required this.isDark,
    required this.strokeLight,
    required this.strokeDark,
  });

  double _wrapAngle(double a) {
    var x = a;
    while (x > math.pi) x -= 2 * math.pi;
    while (x < -math.pi) x += 2 * math.pi;
    return x;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final baseR = math.min(w, h) * 0.46;

    final phase = t * 2 * math.pi;
    const steps = 80;
    final wobble = 0.028;
    final bulgeAmp = 0.018;
    final bulgeAngle = phase * 0.85 + 0.6;

    final path = Path();
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

    Color lift(Color c, double amt) => Color.lerp(c, Colors.white, amt)!;

    const cTop0 = Color(0xFFD6F3FF);
    const cMid0 = Color(0xFF9AD8FA);
    const cBot0 = Color(0xFFF7FDFF);

    final cTop = isDark ? lift(cTop0, 0.10) : cTop0;
    final cMid = isDark ? lift(cMid0, 0.08) : cMid0;
    final cBot = isDark ? lift(cBot0, 0.06) : cBot0;

    Color mix(Color a, Color b, double tt) => Color.lerp(a, b, tt) ?? a;
    final top = mix(cTop, accent, isDark ? 0.10 : 0.08);
    final mid = mix(cMid, accent, isDark ? 0.12 : 0.10);
    final bot = mix(cBot, accent, isDark ? 0.08 : 0.06);

    final rect = Rect.fromLTWH(0, 0, w, h);
    final rot = math.pi;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.24, -0.30),
        radius: 1.06,
        colors: <Color>[
          top.withOpacity(0.985),
          mid.withOpacity(0.905),
          bot.withOpacity(0.985),
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
          Colors.white.withOpacity(isDark ? 0.10 : 0.12),
          mix(
            accent,
            const Color(0xFF79BDEB),
            0.35,
          ).withOpacity(isDark ? 0.06 : 0.085),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, overlayPaint);

    final outline = isDark ? strokeDark : strokeLight;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 2.0 : 1.0
      ..color = outline.withOpacity(isDark ? 0.74 : 0.54);
    canvas.drawPath(path, strokePaint);

    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..color = outline.withOpacity(isDark ? 0.14 : 0.11);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(0.988, 0.988);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, innerStroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniBlobPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.accent.value != accent.value ||
        oldDelegate.isDark != isDark ||
        oldDelegate.strokeLight.value != strokeLight.value ||
        oldDelegate.strokeDark.value != strokeDark.value;
  }
}
