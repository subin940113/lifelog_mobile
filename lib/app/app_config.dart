import 'package:flutter/services.dart';

class AppConfig {
  static const _channel = MethodChannel('app.config');

  static Future<String> get kakaoNativeKey async {
    final key = await _channel.invokeMethod<String>('getKakaoNativeKey');
    if (key == null || key.isEmpty) {
      throw Exception('KAKAO_NATIVE_APP_KEY is missing');
    }
    return key;
  }
}