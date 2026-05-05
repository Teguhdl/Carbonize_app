class ApiEndpoints {
  static const String baseUrl = 'https://carbonize-api.teguhdl.com/api/v1';

  // ── Auth ─────────────────────────────────────────────────
  static const String login    = '/auth/login';
  static const String register = '/auth/register';
  static const String logout   = '/auth/logout';

  // ── User ─────────────────────────────────────────────────
  static const String profile            = '/user/profile';
  static const String uploadProfileImage = '/user/profile/image';
  static const String changePassword     = '/user/change-password';

  // ── Food & Packaging ──────────────────────────────────────
  static const String foodItems    = '/food-packaging/items';
  static const String foodEntries  = '/food-packaging/entries';

  // ── Transport — Master Data ───────────────────────────────
  static const String transportModes      = '/transport/modes';
  static const String privateVehicles     = '/transport/private/vehicles';
  static const String privateFuels        = '/transport/private/fuels';
  static const String publicVehicles      = '/transport/public/vehicles';

  // ── Transport — Entries ───────────────────────────────────
  static const String transportEntries    = '/transport/entries';

  // ── Consumption History (all domains) ─────────────────────
  static const String entries = '/entries';
}
