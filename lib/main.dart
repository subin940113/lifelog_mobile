import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/app_shell.dart';
import 'app/app_config.dart';
import 'theme/theme_provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'push/push_intent.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final kakaoKey = await AppConfig.kakaoNativeKey;

  KakaoSdk.init(nativeAppKey: kakaoKey);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _kPushFcmTokenKey = 'push.fcmToken';

  @override
  void initState() {
    super.initState();
    _initPush();
  }

  Future<void> _initPush() async {
    final messaging = FirebaseMessaging.instance;

    // iOS 권한 요청
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[PUSH] permission denied');
      // 권한이 없더라도, push tap 핸들러는 바인딩해 둠
      await _bindPushOpenHandlers();
      return;
    }

    // iOS에서 APNs token 확보는 FCM token 안정성에 도움
    try {
      await messaging.getAPNSToken();
    } catch (_) {}

    // 최신 FCM 토큰을 로컬에 저장해두고(로그인 후 AppShell에서 서버 등록)
    // 토큰이 바뀌어도 항상 최신값이 남도록 한다.
    try {
      final token = await messaging.getToken();
      final t = token?.trim();
      if (t != null && t.isNotEmpty) {
        await _storage.write(key: _kPushFcmTokenKey, value: t);
        debugPrint('[PUSH] fcmToken persisted');
      }
    } catch (e) {
      debugPrint('[PUSH] persist fcmToken failed: $e');
    }

    await _bindPushOpenHandlers();
  }

  Future<void> _bindPushOpenHandlers() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handlePushTap(initial);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handlePushTap);
  }

  void _handlePushTap(RemoteMessage message) {
    final data = message.data;
    final type = data['intent_type']?.toString();
    final keywordRaw = data['keyword']?.toString();
    final keyword = keywordRaw?.trim();

    if (type == 'record_prompt') {
      PushIntentHolder.setPending(
        PushIntent(type: PushIntentType.recordPrompt, keyword: keyword),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'bluelog',
      themeMode: themeProvider.mode,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      home: const AppShell(),
    );
  }
}

final ThemeData _lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Pretendard',
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
      letterSpacing: -0.1,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.55,
      letterSpacing: -0.1,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  ),
);

final ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Pretendard',
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
      letterSpacing: -0.1,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.55,
      letterSpacing: -0.1,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  ),
);
