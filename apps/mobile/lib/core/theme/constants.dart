/// Layout tokens from the design spec.
class AppRadius {
  AppRadius._();

  static const double largeCard = 28;
  static const double smallCard = 22;
  static const double button = 18;
  static const double input = 28;
  static const double pill = 100;
}

class AppGlass {
  AppGlass._();

  static const double blurSigma = 18;
  static const double opacity = 0.12;
  static const double borderWidth = 1;
}

class AppMotion {
  AppMotion._();

  static const Duration screenTransition = Duration(milliseconds: 300);
  static const Duration cardEnter = Duration(milliseconds: 350);
  static const Duration buttonPress = Duration(milliseconds: 120);
  static const Duration badgePulse = Duration(seconds: 2);
  static const Duration auroraLoop = Duration(seconds: 18);
}
