class AppConfig {
  /// URL produksi RAG sengaja di-hardcode agar build release tidak dapat
  /// diarahkan ke server lain, baik lewat prefs maupun dart-define.
  static const String productionApiBaseUrl =
      'https://api-ragi-indonusa.poltekindonusa.ac.id/api/v1';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionApiBaseUrl,
  );

  static const String ragBaseUrl = String.fromEnvironment(
    'RAG_BASE_URL',
    defaultValue: productionApiBaseUrl,
  );

  static const bool isProduction = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );
}
