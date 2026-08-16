/// Strict 4px-based spacing scale and standardized corner radii, used in
/// place of ad hoc EdgeInsets/BorderRadius values scattered across screens.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8; // chips, small buttons, icon tiles
  static const double md = 12; // inputs, buttons
  static const double lg = 20; // cards, sheets, dialogs
}
