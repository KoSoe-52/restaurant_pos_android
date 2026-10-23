# Restaurant Waiter App — Agent Notes

## Project
Flutter waiter POS app connecting to the Laravel backend at `\\wsl$\Ubuntu\var\www\html\restaurant-app`.

## Key Commands
- `flutter pub get` — Install dependencies
- `flutter analyze` — Static analysis (must pass with 0 issues)
- `flutter run` — Run on device/emulator
- `flutter build apk --release` — Build Android APK

## Architecture
```
lib/
├── core/
│   ├── constants/app_constants.dart  ← baseUrl, timeouts, status strings
│   ├── errors/exceptions.dart        ← ApiException, UnauthorizedException, etc.
│   ├── theme/app_theme.dart          ← AppColors, AppTheme, status color helpers
│   └── utils/formatters.dart         ← Currency, date, time formatting
├── data/
│   ├── models/                       ← Dart models matching API responses
│   ├── providers/                    ← ChangeNotifier state (auth, table, menu, order)
│   └── services/api_service.dart     ← All HTTP calls + token management
└── presentation/
    ├── screens/
    │   ├── splash_screen.dart        ← Auth check on startup
    │   ├── home_screen.dart          ← Bottom nav (Tables / My Orders / Profile)
    │   ├── auth/login_screen.dart
    │   ├── tables/table_grid_screen.dart
    │   ├── menu/menu_screen.dart
    │   ├── orders/cart_screen.dart
    │   ├── orders/order_confirmation_screen.dart
    │   ├── orders/my_orders_screen.dart
    │   ├── orders/order_detail_screen.dart
    │   └── profile/profile_screen.dart
    └── widgets/common/               ← AppLoading, AppError, AppEmpty, StatusBadge, ConfirmDialog
```

## Configuration
- **Server URL**: Edit `lib/core/constants/app_constants.dart` → `baseUrl`
- **Table refresh**: `tableRefreshInterval` (default 30s)
- **Test credentials**: `waiter@gmail.com` / `password`

## Notes
- `withOpacity()` is deprecated in Flutter 3.x; use `.withValues(alpha: x)` instead (already done globally)
- Windows Developer Mode must be enabled for `flutter build` (symlink support)
- The `intl: ^0.19.0` package was added for date/number formatting
- `device_info_plus` upgraded from `^10.1.4` → `^12.4.0` for compatibility
