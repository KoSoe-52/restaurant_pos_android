import 'package:intl/intl.dart';

class RestaurantSettings {
  final String restaurantName;
  final String? restaurantAddress;
  final String? restaurantPhone;
  final String currencySymbol;
  final double taxRate;
  final String? receiptFooter;
  final String? businessDayCutoff;

  const RestaurantSettings({
    required this.restaurantName,
    this.restaurantAddress,
    this.restaurantPhone,
    required this.currencySymbol,
    required this.taxRate,
    this.receiptFooter,
    this.businessDayCutoff,
  });

  factory RestaurantSettings.fromJson(Map<String, dynamic> json) {
    final s = json['settings'] as Map<String, dynamic>;
    return RestaurantSettings(
      restaurantName: s['restaurant_name'] ?? 'Restaurant',
      restaurantAddress: s['restaurant_address'],
      restaurantPhone: s['restaurant_phone'],
      currencySymbol: s['currency_symbol'] ?? 'Ks',
      taxRate: (s['tax_rate'] as num? ?? 0).toDouble(),
      receiptFooter: s['receipt_footer'],
      businessDayCutoff: s['business_day_cutoff'],
    );
  }

  Map<String, dynamic> toJson() => {
        'restaurant_name': restaurantName,
        'restaurant_address': restaurantAddress,
        'restaurant_phone': restaurantPhone,
        'currency_symbol': currencySymbol,
        'tax_rate': taxRate,
        'receipt_footer': receiptFooter,
        'business_day_cutoff': businessDayCutoff,
      };

  String formatPrice(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return '${formatter.format(amount)} $currencySymbol';
  }

  static RestaurantSettings get defaultSettings => const RestaurantSettings(
        restaurantName: 'Restaurant',
        currencySymbol: 'Ks',
        taxRate: 0,
      );
}
