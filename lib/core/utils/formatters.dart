import 'package:intl/intl.dart';

class Formatters {
  static String currency(num amount, {String symbol = 'Ks'}) {
    final formatter = NumberFormat('#,###', 'en_US');
    return '${formatter.format(amount)} $symbol';
  }

  static String dateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());
  }

  static String date(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  static String time(DateTime dt) {
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  static String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(dt.toLocal());
  }

  static String orderStatus(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'served': return 'Served';
      case 'paid': return 'Paid';
      case 'voided': return 'Voided';
      default: return status;
    }
  }

  static String tableStatus(String status) {
    switch (status) {
      case 'available': return 'Available';
      case 'occupied': return 'Occupied';
      case 'reserved': return 'Reserved';
      default: return status;
    }
  }

  static String itemStatus(String status) {
    switch (status) {
      case 'queued': return 'Queued';
      case 'printed': return 'Printed';
      case 'served': return 'Served';
      case 'voided': return 'Voided';
      default: return status;
    }
  }

  static String printerTarget(String target) {
    switch (target) {
      case 'kitchen': return 'Kitchen';
      case 'beer': return 'Bar';
      case 'cashier': return 'Cashier';
      default: return target;
    }
  }
}
