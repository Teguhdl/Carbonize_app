class ApiEndpoints {
  static const String baseUrl = 'https://carbonize-api.teguhdl.com/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';

  // User
  static const String profile = '/user/profile';
  static const String uploadProfileImage = '/user/profile/image';
  static const String changePassword = '/user/change-password';

  // Emission Factors
  static const String emissionCategories = '/emission/categories';
  static const String emissionFactors = '/emission/factors';

  // Consumption Entries
  static const String consumptionEntries = '/consumption/entries';
}
