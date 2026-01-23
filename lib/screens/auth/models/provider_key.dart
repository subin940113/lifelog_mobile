enum ProviderKey { kakao, naver, google, apple }

extension ProviderKeyX on ProviderKey {
  String get storageValue {
    switch (this) {
      case ProviderKey.kakao:
        return 'kakao';
      case ProviderKey.naver:
        return 'naver';
      case ProviderKey.google:
        return 'google';
      case ProviderKey.apple:
        return 'apple';
    }
  }

  static ProviderKey? fromStorage(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;

    switch (v) {
      case 'kakao':
        return ProviderKey.kakao;
      case 'naver':
        return ProviderKey.naver;
      case 'google':
        return ProviderKey.google;
      case 'apple':
        return ProviderKey.apple;
      default:
        return null;
    }
  }
}
