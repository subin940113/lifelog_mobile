# 블루로그 (bluelog)

음성 인식으로 일상을 기록하고, AI 인사이트로 자신을 더 깊이 이해할 수 있는 라이프로그 모바일 앱입니다.

## 📱 주요 기능

- **음성으로 기록하기**: 음성 인식(STT)을 통해 빠르고 자연스럽게 일상을 기록할 수 있습니다
- **AI 인사이트**: 기록된 내용을 분석하여 패턴과 트렌드를 발견할 수 있습니다
- **시그널 추적**: 관심 있는 키워드와 주제를 추적하고 관련 기록을 자동으로 연결합니다
- **소셜 로그인**: Google, Kakao, Naver, Apple ID로 간편하게 로그인할 수 있습니다
- **푸시 알림**: Firebase를 통한 푸시 알림으로 기록을 도와줍니다
- **다크 모드**: 라이트/다크 테마를 지원합니다
- **설정**: 테마, 언어, 알림, 관심사, 인사이트 등 다양한 설정을 지원합니다

## 🛠 기술 스택

- **Framework**: Flutter 3.10.4
- **언어**: Dart
- **상태 관리**: Provider
- **HTTP 클라이언트**: Dio
- **음성 인식**: speech_to_text
- **푸시 알림**: Firebase Cloud Messaging
- **소셜 로그인**: 
  - Google Sign In
  - Kakao Flutter SDK
  - Naver Login
  - Sign in with Apple
- **보안 저장소**: flutter_secure_storage

## 📦 프로젝트 구조

```
lib/
├── api/              # API 클라이언트
│   ├── auth_api_client.dart
│   ├── home_api_client.dart
│   ├── log_api_client.dart
│   ├── insight_api_client.dart
│   ├── signal_api_client.dart
│   └── push_api_client.dart
├── app/              # 앱 설정 및 셸
│   ├── app_config.dart
│   └── app_shell.dart
├── screens/          # 화면
│   ├── auth/         # 로그인 화면
│   ├── home/         # 메인 홈 화면
│   ├── record/       # 기록 화면
│   ├── insight/      # 인사이트 화면
│   └── settings/     # 설정 화면
├── push/             # 푸시 알림 관련
├── theme/            # 테마 관련
└── widgets/          # 공통 위젯
```

## 🚀 시작하기

### 사전 요구사항

- Flutter SDK 3.10.4 이상
- Dart SDK
- iOS 개발: Xcode 및 CocoaPods
- Android 개발: Android Studio

### 설치

1. 저장소 클론
```bash
git clone <repository-url>
cd lifelog_mobile
```

2. 의존성 설치
```bash
flutter pub get
```

3. iOS 의존성 설치 (iOS 개발시)
```bash
cd ios
pod install
cd ..
```

### 환경 설정

#### API 설정

`lib/config/api_config.dart`에서 API 기본 URL을 설정할 수 있습니다.

빌드 시 환경 변수로 설정:
```bash
flutter run --dart-define=API_BASE_URL=http://your-api-url
```

#### Firebase 설정

1. Firebase Console에서 프로젝트 생성
2. iOS용 `GoogleService-Info.plist` 파일을 `ios/Runner/`에 추가
3. Android용 `google-services.json` 파일을 `android/app/`에 추가

#### 소셜 로그인 설정

각 소셜 로그인 서비스의 키가 `Info.plist` (iOS) 및 프로젝트 설정 (Android)에 구성되어 있어야 합니다.

### 실행

```bash
# 개발 모드로 실행
flutter run

# 특정 디바이스로 실행
flutter run -d <device-id>

# 릴리즈 모드로 빌드 (iOS)
flutter build ios --release

# 릴리즈 모드로 빌드 (Android)
flutter build apk --release
```

## 📝 주요 기능 설명

### 음성 인식 기록

- 실시간 음성 인식으로 텍스트로 변환
- 텍스트 편집 기능 지원
- 여러 언어 지원

### AI 인사이트

- 기록된 내용 기반 패턴 분석
- 트렌드 발견
- 키워드 기반 인사이트 제공

### 시그널 추적

- 관심 키워드 및 주제 설정
- 관련 기록 자동 연결
- 시각적 표시로 추적

## 🔧 개발

### 코드 스타일

프로젝트는 `flutter_lints` 패키지를 사용하여 코드 품질을 관리합니다.

### 테스트

```bash
flutter test
```

### 빌드

```bash
# iOS
flutter build ios

# Android
flutter build apk
```

## 📄 라이센스

이 프로젝트는 비공개 프로젝트입니다.

## 👥 기여

프로젝트에 기여하고 싶으시다면, 이슈를 생성하거나 Pull Request를 보내주세요.

## 📞 문의

프로젝트 관련 문의사항이 있으시면 이슈를 생성해주세요.
