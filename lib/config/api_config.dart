class ApiConfig {
  // Pour le développement
  static const String devUrl = "http://10.0.2.2:5000"; // Pour émulateur Android
  static const String devUrlIos = "http://localhost:5000"; // Pour simulateur iOS

  // Pour la production
  static const String prodUrl = "https://api.show_app.com";

  // URL à utiliser
  static const String baseUrl = devUrl; // Changer selon l'environnement
}