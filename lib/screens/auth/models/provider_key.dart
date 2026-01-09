// lib/screens/auth/models/provider_key.dart

enum ProviderKey { google, kakao, naver }

extension ProviderKeyX on ProviderKey {
  String get storageValue {
    switch (this) {
      case ProviderKey.google:
        return 'google';
      case ProviderKey.kakao:
        return 'kakao';
      case ProviderKey.naver:
        return 'naver';
    }
  }

  static ProviderKey? fromStorage(String? raw) {
    switch (raw) {
      case 'google':
        return ProviderKey.google;
      case 'kakao':
        return ProviderKey.kakao;
      case 'naver':
        return ProviderKey.naver;
      default:
        return null;
    }
  }
}
