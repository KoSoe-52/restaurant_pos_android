class RestaurantTable {
  final int id;
  final String name;
  final int capacity;
  final String? location;
  final String status;
  final String statusLabel;
  final TableActiveOrder? activeOrder;

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
  bool get canTakeOrder => status == 'available' || status == 'reserved';

  const RestaurantTable({
    required this.id,
    required this.name,
    required this.capacity,
    this.location,
    required this.status,
    required this.statusLabel,
    this.activeOrder,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) =>
      RestaurantTable(
        id: json['id'],
        name: json['name'],
        capacity: json['capacity'] ?? 4,
        location: json['location'],
        status: json['status'],
        statusLabel: json['status_label'] ?? json['status'],
        activeOrder: json['active_order'] != null
            ? TableActiveOrder.fromJson(json['active_order'])
            : null,
      );
}

class TableActiveOrder {
  final int id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final int itemCount;
  final Map<String, dynamic>? waiter;
  final DateTime orderedAt;

  const TableActiveOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.itemCount,
    this.waiter,
    required this.orderedAt,
  });

  factory TableActiveOrder.fromJson(Map<String, dynamic> json) =>
      TableActiveOrder(
        id: json['id'],
        orderNumber: json['order_number'],
        status: json['status'],
        subtotal: (json['subtotal'] as num).toDouble(),
        discount: (json['discount'] as num? ?? 0).toDouble(),
        tax: (json['tax'] as num? ?? 0).toDouble(),
        total: (json['total'] as num).toDouble(),
        itemCount: json['item_count'] ?? 0,
        waiter: json['waiter'] as Map<String, dynamic>?,
        orderedAt: DateTime.parse(json['ordered_at']),
      );
}
