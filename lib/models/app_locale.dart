enum AppLanguage {
  english,
  bangla,
}

extension AppLanguageExtension on AppLanguage {
  String get code => this == AppLanguage.bangla ? 'bn' : 'en';
  String get displayName => this == AppLanguage.bangla ? 'বাংলা' : 'English';
  String get flagEmoji => this == AppLanguage.bangla ? '🇧🇩' : '🇬🇧';
}
