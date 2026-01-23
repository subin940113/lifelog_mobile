import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/api/signal_api_client.dart';

import 'signal_object_card.dart';
import 'signal_orbit_overlay.dart';
import 'keyword_insight_sheet.dart';

class SignalObjectSection extends StatefulWidget {
  final Palette p;
  final SignalApiClient api;

  // 상단 카피에 필요했던 top preview(기존 흐름 유지)
  final TopInsightPreview top;

  final VoidCallback? onTapObject;

  const SignalObjectSection({
    super.key,
    required this.p,
    required this.api,
    required this.top,
    this.onTapObject,
  });

  @override
  State<SignalObjectSection> createState() => _SignalObjectSectionState();
}

class _SignalObjectSectionState extends State<SignalObjectSection> {
  bool _didKickoffLoad = false;

  bool _loading = true;
  bool _error = false;

  SignalObjectsResponse? _objects;

  @override
  void initState() {
    super.initState();

    // Kick off after first frame to avoid lifecycle edge cases
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_didKickoffLoad) return;
      _didKickoffLoad = true;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant SignalObjectSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the API client instance changes (e.g., after re-login / rebuild), reload.
    if (oldWidget.api != widget.api) {
      _load();
      return;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final res = await widget.api.getObjects();
      if (!mounted) return;
      setState(() {
        _objects = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _openDrop(String keywordKey, String? insightText) async {
    if (!mounted) return;
    await KeywordInsightSheet.show(
      context: context,
      p: widget.p,
      keywordKey: keywordKey,
      insightText: insightText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final objects = _objects;

    // waterDrops -> orbit view model
    // activeKeywords -> orbit view model (keyword 기반)
    final activeKeywords = objects?.activeKeywords;
    final List<WaterDropVm> drops =
        (activeKeywords != null && activeKeywords.isNotEmpty)
        ? activeKeywords
              .map(
                (k) => WaterDropVm(
                  keywordKey: k.keywordKey,
                  candyCount: k.candyCount,
                  insightText: k.insightText,
                ),
              )
              .toList(growable: false)
        : (objects?.waterDrops ?? const <WaterDropDto>[])
              .map(
                (d) => WaterDropVm(
                  keywordKey: d.keywordKey,
                  candyCount: 0, // fallback
                  insightText: null, // fallback
                ),
              )
              .toList(growable: false);

    // ✅ insightText가 있는 물방울만 표시
    final filteredDrops = drops.where((d) => d.insightText?.trim().isNotEmpty == true).toList(growable: false);

    final totalCandy = objects?.totalCandyCount ?? 0;
    final effectiveTop = widget.top;

    final Widget? overlay = filteredDrops.isNotEmpty
        ? SignalOrbitOverlay(
            p: p,
            drops: filteredDrops,
            onTapDrop: _openDrop,
            candyCount: totalCandy,
          )
        : (totalCandy > 0
              ? IgnorePointer(
                  ignoring: true,
                  child: SignalOrbitOverlay(
                    p: p,
                    drops: const <WaterDropVm>[],
                    onTapDrop: (_, __) {},
                    candyCount: totalCandy,
                  ),
                )
              : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SignalObjectCard(
          p: p,
          top: effectiveTop,
          isLoading: _loading,
          hasError: _error,
          totalCandy: totalCandy,
          blobOverlay: overlay,
          onTapBlob: widget.onTapObject,
        ),
      ],
    );
  }
}
