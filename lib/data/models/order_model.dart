class OrderTable {
  final int id;
  final String name;

  const OrderTable({required this.id, required this.name});

  factory OrderTable.fromJson(Map<String, dynamic> j) =>
      OrderTable(id: j['id'], name: j['name']);
}

class OrderUser {
  final int id;
  final String name;

  const OrderUser({required this.id, required this.name});

  factory OrderUser.fromJson(Map<String, dynamic> j) =>
      OrderUser(id: j['id'], name: j['name']);
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final int productPrice;
  final String printerTarget;
  final int quantity;
  final int subtotal;
  final String status;
  final String statusLabel;
  final String? note;
  final String? voidReason;

  bool get isVoided => status == 'voided';
  bool get isQueued => status == 'queued';
  bool get isPrinted => status == 'printed';
  bool get isServed => status == 'served';

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.printerTarget,
    required this.quantity,
    required this.subtotal,
    required this.status,
    required this.statusLabel,
    this.note,
    this.voidReason,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'],
        productId: json['product_id'],
        productName: json['product_name'],
        productPrice: json['product_price'] is int
            ? json['product_price']
            : (json['product_price'] as num).toInt(),
        printerTarget: json['printer_target'] ?? 'kitchen',
        quantity: json['quantity'],
        subtotal: json['subtotal'] is int
            ? json['subtotal']
            : (json['subtotal'] as num).toInt(),
        status: json['status'],
        statusLabel: json['status_label'] ?? json['status'],
        note: json['note'],
        voidReason: json['void_reason'],
      );
}

class PrintJob {
  final int id;
  final String printer;
  final String status;
  final int attempts;
  final String? error;
  final DateTime createdAt;

  bool get hasFailed => status == 'failed';
  bool get isSent => status == 'sent';
  bool get isQueued => status == 'queued';

  const PrintJob({
    required this.id,
    required this.printer,
    required this.status,
    required this.attempts,
    this.error,
    required this.createdAt,
  });

  factory PrintJob.fromJson(Map<String, dynamic> json) => PrintJob(
        id: json['id'],
        printer: json['printer'],
        status: json['status'],
        attempts: json['attempts'] ?? 0,
        error: json['error'],
        createdAt: DateTime.parse(json['created_at']),
      );
}

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String statusLabel;
  final OrderTable? table;
  final OrderUser? waiter;
  final String? customerName;
  final String? customerPhone;
  final String? note;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String? paymentMethod;
  final DateTime orderedAt;
  final DateTime? servedAt;
  final DateTime? paidAt;
  final String? voidReason;
  final List<PrintJob> printJobs;

  bool get isOpen => status == 'open';
  bool get isServed => status == 'served';
  bool get isPaid => status == 'paid';
  bool get isVoided => status == 'voided';
  bool get canServe => isOpen;
  bool get canVoid => isOpen || isServed;
  bool get canAddItems => isOpen || isServed;

  List<OrderItem> get activeItems =>
      items.where((i) => !i.isVoided).toList();

  bool get hasFailedPrintJobs => printJobs.any((j) => j.hasFailed);

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
    this.table,
    this.waiter,
    this.customerName,
    this.customerPhone,
    this.note,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    this.paymentMethod,
    required this.orderedAt,
    this.servedAt,
    this.paidAt,
    this.voidReason,
    required this.printJobs,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle both direct object and wrapped { "order": {...} }
    final o = json.containsKey('order')
        ? json['order'] as Map<String, dynamic>
        : json;
    return Order(
      id: o['id'],
      orderNumber: o['order_number'],
      status: o['status'],
      statusLabel: o['status_label'] ?? o['status'],
      table: o['table'] != null ? OrderTable.fromJson(o['table']) : null,
      waiter: o['waiter'] != null ? OrderUser.fromJson(o['waiter']) : null,
      customerName: o['customer_name'],
      customerPhone: o['customer_phone'],
      note: o['note'],
      items: (o['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      subtotal: (o['subtotal'] as num).toDouble(),
      discount: (o['discount'] as num? ?? 0).toDouble(),
      tax: (o['tax'] as num? ?? 0).toDouble(),
      total: (o['total'] as num).toDouble(),
      paymentMethod: o['payment_method'],
      orderedAt: DateTime.parse(o['ordered_at']),
      servedAt:
          o['served_at'] != null ? DateTime.parse(o['served_at']) : null,
      paidAt: o['paid_at'] != null ? DateTime.parse(o['paid_at']) : null,
      voidReason: o['void_reason'],
      printJobs: (o['print_jobs'] as List? ?? [])
          .map((e) => PrintJob.fromJson(e))
          .toList(),
    );
  }
}

class PaginatedOrders {
  final List<Order> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedOrders({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasNextPage => currentPage < lastPage;

  factory PaginatedOrders.fromJson(Map<String, dynamic> json) {
    final o = json['orders'] as Map<String, dynamic>;
    return PaginatedOrders(
      data: (o['data'] as List).map((e) => Order.fromJson(e)).toList(),
      currentPage: o['current_page'],
      lastPage: o['last_page'],
      total: o['total'],
    );
  }
}
