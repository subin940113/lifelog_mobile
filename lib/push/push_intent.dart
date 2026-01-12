enum PushIntentType { recordPrompt }

class PushIntent {
  final PushIntentType type;
  final String? keyword;

  PushIntent({required this.type, this.keyword});
}

class PushIntentHolder {
  static PushIntent? pending;
}
