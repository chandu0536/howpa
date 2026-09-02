class Env {
  Env._();

  // Base URL
  static const String baseUrl = 'https://howpa.vercel.app';

  // API Version / Prefix
  static const String apiPrefix = '/api';

  // Google Maps API Key
  static const String googleMapsApiKey = 'AIzaSyBBfALT0fQbrlVav4d-Fyj7KuVswEnrfck';

  // Full API Base URL
  static String get fullApiUrl => '$baseUrl$apiPrefix';
}
