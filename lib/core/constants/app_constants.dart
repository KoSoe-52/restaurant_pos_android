class AppConstants {
  // API Base URL - change this to your server IP/domain
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  // Storage keys
  static const String tokenKey = 'api_token';
  static const String userKey = 'current_user';
  static const String settingsKey = 'restaurant_settings';

  // App info
  static const String appName = 'Waiter App';
  static const String defaultDeviceName = 'flutter-waiter-app';

  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration tableRefreshInterval = Duration(seconds: 30);

  // Pagination
  static const int defaultPerPage = 50;
  static const int ordersPerPage = 20;

  // Order statuses
  static const String statusOpen = 'open';
  static const String statusServed = 'served';
  static const String statusPaid = 'paid';
  static const String statusVoided = 'voided';

  // Item statuses
  static const String itemStatusQueued = 'queued';
  static const String itemStatusPrinted = 'printed';
  static const String itemStatusServed = 'served';
  static const String itemStatusVoided = 'voided';

  // Table statuses
  static const String tableAvailable = 'available';
  static const String tableOccupied = 'occupied';
  static const String tableReserved = 'reserved';

  // Printer targets
  static const String printerKitchen = 'kitchen';
  static const String printerBeer = 'beer';
  static const String printerCashier = 'cashier';
}
