import 'package:flutter/foundation.dart';

enum PushIntentType { recordPrompt }

class PushIntent {
  final PushIntentType type;
  final String? keyword;

  PushIntent({required this.type, this.keyword});
}

class PushIntentHolder {
  static PushIntent? pending;

  /// ✅ 새 intent가 세팅될 때 AppShell에 알려주기 위한 콜백
  static VoidCallback? onChanged;

  /// ✅ 기존 코드 영향 최소를 위해 setter만 추가
  static void setPending(PushIntent? intent) {
    pending = intent;
    onChanged?.call();
  }

  static PushIntent? consume() {
    final v = pending;
    pending = null;
    return v;
  }
}
