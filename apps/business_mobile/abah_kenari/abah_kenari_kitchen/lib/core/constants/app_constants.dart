class AppConstants {
  static const businessName = 'RM Abah Kenari';
  static const businessCategory = 'Rumah Makan';
  static const poweredBy = 'NUSA-DHIPA BUSINESS OS';

  // Tenant is intentionally configuration-driven.
  // DO NOT hardcode tenant_id in application business logic.
  static const tenantSlug = 'abah-kenari';

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8300',
  );
}
