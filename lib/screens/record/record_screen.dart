// lib/screens/record/record_screen.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:lifelog_mobile/api/auth_api_client.dart';
import 'package:lifelog_mobile/api/log_api_client.dart';
import 'package:lifelog_mobile/config/api_config.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'package:lifelog_mobile/screens/record/record_widgets.dart';
import 'package:lifelog_mobile/widgets/app_toast.dart';

import 'package:lifelog_mobile/widgets/glass_dot.dart';

class RecordScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const RecordScreen({super.key, this.onLogout});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final SpeechToText _speech = SpeechToText();
  final GlobalKey _doneFabKey = GlobalKey();

  bool _sttAvailable = false;
  String? _selectedLocaleId;

  bool _isListening = false;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _editorFocus = FocusNode();

  // API
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final AuthApiClient _authApi;
  late final LogApiClient _logApi;
  bool _saving = false;

  // STT merge state
  String _committedText = '';
  String _partialText = '';

  // STT session guards (prevents double-commit on stop vs finalResult)
  bool _sessionFinalCommitted = false;
  String _lastCommittedChunk = '';

  bool _hasText = false; // 완료 버튼 활성화용
  String? _stickyNotice; // 권한/사용불가 같은 상태성 메시지(지속 노출)

  Future<bool> _hasSpeechPermission() async {
    final dynamic v = _speech.hasPermission;
    if (v is bool) return v;
    if (v is Future<bool>) return await v;
    return false;
  }

  @override
  void initState() {
    super.initState();

    _authApi = AuthApiClient(
      baseUrl: ApiConfig.baseUrl,
      storage: _secureStorage,
      onUnauthorized: widget.onLogout,
    );
    _logApi = LogApiClient(_authApi);

    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(() {
      final next = _controller.text.trim().isNotEmpty;
      if (next != _hasText) setState(() => _hasText = next);
    });

    _initStt();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    _controller.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  void _setStickyNotice(String? message) {
    if (!mounted) return;
    if (_stickyNotice == message) return;
    setState(() => _stickyNotice = message);
  }

  double _computeToastBottomPadding() {
    final media = MediaQuery.of(context);
    final screenH = media.size.height;

    // 기본값: 홈 인디케이터 위 + 여백
    double bottomPadding = media.padding.bottom + 18;

    // DoneFab 위치 기반(버튼 위)
    final fabCtx = _doneFabKey.currentContext;
    if (fabCtx != null) {
      final render = fabCtx.findRenderObject();
      if (render is RenderBox && render.hasSize) {
        final topLeft = render.localToGlobal(Offset.zero);
        final fabTopY = topLeft.dy;

        const gap = 14.0;
        bottomPadding = (screenH - fabTopY) + gap;

        // 키보드가 올라온 경우 보정
        bottomPadding += media.viewInsets.bottom;

        bottomPadding = bottomPadding.clamp(
          media.padding.bottom + 18,
          screenH * 0.75,
        );
      }
    }

    return bottomPadding;
  }

  void _showToast(String message) {
    if (!mounted) return;
    AppToast.show(
      context,
      message,
      bottomPadding: _computeToastBottomPadding(),
    );
  }

  Future<void> _initStt() async {
    try {
      final available = await _speech.initialize(
        onStatus: (s) {
          if (!mounted) return;
          if ((s == 'notListening' || s == 'done') && _isListening) {
            _stopListening();
          }
        },
        onError: (e) {
          if (!mounted) return;
          if (_isListening) _stopListening();
          _showToast('STT 오류: ${e.errorMsg}');
        },
      );

      if (!mounted) return;

      if (!available) {
        setState(() => _sttAvailable = false);
        return;
      }

      final perm = await _hasSpeechPermission();
      if (!perm) {
        _setStickyNotice(null);
        setState(() => _sttAvailable = false);
        _setStickyNotice('마이크/음성 인식 권한이 필요합니다. iOS 설정에서 허용해 주세요.');
        return;
      }

      final locales = await _speech.locales();
      final systemLocale = await _speech.systemLocale();

      String? preferred;
      if (locales.any((l) => l.localeId == 'ko_KR')) {
        preferred = 'ko_KR';
      } else if (systemLocale != null &&
          locales.any((l) => l.localeId == systemLocale.localeId)) {
        preferred = systemLocale.localeId;
      } else if (locales.isNotEmpty) {
        preferred = locales.first.localeId;
      }

      setState(() {
        _sttAvailable = true;
        _selectedLocaleId = preferred;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sttAvailable = false);
    }
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _joinWithSpace(String a, String b) {
    final left = a.trimRight();
    final right = b.trimLeft();
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    final needsSpace = !left.endsWith('\n') && !left.endsWith(' ');
    return needsSpace ? '$left $right' : '$left$right';
  }

  String _appendAsNewLine(String base, String chunk) {
    final right = chunk.trim();
    if (right.isEmpty) return base;

    final left = base.endsWith('\n') ? base : base.trimRight();
    if (left.trim().isEmpty) return right;

    return left.endsWith('\n') ? '$left$right' : '$left\n$right';
  }

  String _composeDisplayText() {
    final p = _partialText;
    if (p.trim().isEmpty) return _committedText;

    if (_committedText.endsWith('\n')) {
      return '$_committedText${p.trimLeft()}';
    }

    return _joinWithSpace(_committedText, p);
  }

  void _applyDisplayTextToEditor() {
    final text = _composeDisplayText();
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    if (!_sttAvailable) {
      _showToast('STT를 사용할 수 없습니다. 권한/엔진을 확인하세요.');
      return;
    }

    final perm = await _hasSpeechPermission();
    if (!perm) {
      _setStickyNotice('마이크/음성 인식 권한이 필요합니다. iOS 설정에서 허용해 주세요.');
      _showToast('권한이 없습니다. 설정에서 마이크/음성 인식을 허용해 주세요.');
      return;
    }

    final localeId = _selectedLocaleId;
    if (localeId == null) {
      _showToast('인식 언어가 설정되지 않았습니다. 설정에서 선택하세요.');
      return;
    }

    _setStickyNotice(null);
    _editorFocus.unfocus();

    _committedText = _controller.text;
    _partialText = '';

    if (_committedText.trim().isNotEmpty && !_committedText.endsWith('\n')) {
      _committedText = '$_committedText\n';
      _partialText = '';
      _applyDisplayTextToEditor();
    }

    _sessionFinalCommitted = false;
    _lastCommittedChunk = '';

    setState(() {
      _isListening = true;
      _elapsed = Duration.zero;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });

    await _speech.listen(
      localeId: localeId,
      partialResults: true,
      listenMode: ListenMode.dictation,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: false,
      onResult: (result) {
        if (!mounted) return;
        if (_editorFocus.hasFocus) return;

        final words = result.recognizedWords;
        if (words.trim().isEmpty) return;

        setState(() {
          if (result.finalResult) {
            final chunk = words.trim();
            if (chunk.isNotEmpty && chunk != _lastCommittedChunk) {
              _committedText = _appendAsNewLine(_committedText, chunk);
              _lastCommittedChunk = chunk;
            }
            _partialText = '';
            _sessionFinalCommitted = true;
          } else {
            _partialText = words;
          }
          _applyDisplayTextToEditor();
        });
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!_speech.isListening) {
      if (!mounted) return;
      _timer?.cancel();
      _timer = null;
      setState(() => _isListening = false);
      _showToast('음성 인식을 시작하지 못했습니다.\n입력 장치/권한을 확인해 주세요.');
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;

    _timer?.cancel();
    _timer = null;

    await _speech.stop();
    if (!mounted) return;

    if (!_editorFocus.hasFocus && !_sessionFinalCommitted) {
      setState(() {
        final p = _partialText.trim();
        if (p.isNotEmpty && p != _lastCommittedChunk) {
          _committedText = _appendAsNewLine(_committedText, p);
          _lastCommittedChunk = p;
        }
        _partialText = '';
        _applyDisplayTextToEditor();
      });
    } else {
      setState(() {
        _partialText = '';
        _applyDisplayTextToEditor();
      });
    }

    setState(() => _isListening = false);
  }

  Future<void> _onDone() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await _logApi.createLog(content: text);

      // Reset editor
      _controller.clear();
      _committedText = '';
      _partialText = '';
      _lastCommittedChunk = '';
      _sessionFinalCommitted = false;
      _editorFocus.unfocus();

      if (!mounted) return;
      _showToast('저장했습니다.');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();

      if (msg.contains('accessToken이 없습니다')) {
        _showToast('로그인이 필요합니다.');
      } else if (msg.contains('토큰 갱신 실패') || msg.contains('refreshToken')) {
        _showToast('세션이 만료되었습니다. 다시 로그인해 주세요.');
      } else {
        _showToast('저장 실패');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(Theme.of(context).colorScheme);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? p.bg : const Color(0xFFFAFAFA);

    final localTheme = Theme.of(context).copyWith(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accentSoft,
        selectionHandleColor: p.accent,
      ),
    );

    final doneEnabled = _hasText && !_saving;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // ✅ GlassFab 직접 사용 → DoneFab(공통) 사용
      floatingActionButton: SizedBox(
        key: _doneFabKey,
        child: DoneFab(
          enabled: doneEnabled,
          onPressed: _onDone,
          p: p,
          floatEnabled: false,
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: const Offset(-14, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: _DepthIcon(
                          icon: Icons.chevron_left_rounded,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: HoldToTalkPill(
                        label: _isListening
                            ? '말하는 중 • ${_formatElapsed(_elapsed)}'
                            : '말하기',
                        active: _isListening,
                        enabled: _sttAvailable,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        borderRadius: BorderRadius.zero,
                        showUnderline: true,
                        onHoldStart: _startListening,
                        onHoldEnd: _stopListening,
                        onTapHint: () {
                          if (_isListening) return;
                          _showToast('말하기는 길게 눌러서 시작합니다.');
                        },
                        p: p,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: ModePill(
                        label: '직접 입력',
                        active: _editorFocus.hasFocus,
                        enabled: true,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        borderRadius: BorderRadius.zero,
                        showUnderline: true,
                        onTap: () {
                          if (_isListening) _stopListening();
                          _editorFocus.requestFocus();
                        },
                        p: p,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              if (_stickyNotice != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _stickyNotice!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: p.muted,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 16),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '오늘의 기록',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: p.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (_isListening) ...[
                    const SizedBox(width: 8),
                    GlassDot(size: 6, color: p.accent, active: true),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _saving
                    ? '저장 중…'
                    : (_isListening
                          ? '말하면 바로 여기에 적혀요'
                          : '짧게라도 괜찮아요. 지금 떠오르는 걸 적어보세요.'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.muted,
                  height: 1.45,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Theme(
                  data: localTheme,
                  child: TextField(
                    focusNode: _editorFocus,
                    controller: _controller,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    expands: true,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: p.ink,
                      height: 1.6,
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '예) 아침에 일찍 일어나 산책을 했다. 커피를 마시며 하루를 정리했다…',
                      hintStyle: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: p.muted, height: 1.6, fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ 배경(원형/캡슐) 없이 아이콘만 “살짝 떠있는” 느낌.
class _DepthIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const _DepthIcon({required this.icon, required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).iconTheme.color ?? Colors.black87;

    const shadowOpacity = 0.20;
    const shadowBlur = 5.0;
    const shadowDy = 2.2;

    const hiOpacity = 0.16;
    const hiBlur = 1.8;
    const hiDy = -0.7;

    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, shadowDy),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: shadowBlur,
              sigmaY: shadowBlur,
            ),
            child: Icon(
              icon,
              size: size,
              color: Colors.black.withOpacity(shadowOpacity),
            ),
          ),
        ),
        Icon(icon, size: size, color: c),
        Transform.translate(
          offset: const Offset(0, hiDy),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: hiBlur, sigmaY: hiBlur),
            child: Icon(
              icon,
              size: size,
              color: Colors.white.withOpacity(hiOpacity),
            ),
          ),
        ),
      ],
    );
  }
}
