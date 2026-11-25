const orderStatuses = ['pending', 'paid', 'shipped', 'refunded', 'cancelled'];

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class OrderItem {
  const OrderItem({required this.sku, required this.name, required this.qty, required this.price});
  final String sku, name;
  final int qty;
  final double price;
  double get total => qty * price;

  factory OrderItem.fromJson(Map<String, dynamic> j) =>
      OrderItem(sku: '${j['sku']}', name: '${j['name']}', qty: (j['qty'] as num).toInt(), price: (j['price'] as num).toDouble());
}

class StatusChange {
  const StatusChange(this.status, this.at, this.by);
  final String status, by;
  final DateTime at;

  factory StatusChange.fromJson(Map<String, dynamic> j) =>
      StatusChange('${j['status']}', DateTime.parse(j['at'] as String), '${j['by'] ?? 'system'}');
}

class Order {
  const Order({
    required this.id,
    required this.customer,
    required this.amount,
    required this.status,
    required this.date,
    this.customerId,
    this.itemCount = 0,
    this.items = const [],
    this.history = const [],
    this.note = '',
  });

  final int id;
  final String customer, status, note;
  final int? customerId;
  final double amount;
  final DateTime date;
  final int itemCount;

  /// Only filled by the detail endpoint.
  final List<OrderItem> items;
  final List<StatusChange> history;

  String get label => '#$id';

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as int,
        customer: '${j['customer']}',
        customerId: j['customerId'] as int?,
        amount: (j['amount'] as num).toDouble(),
        status: '${j['status']}',
        date: DateTime.parse(j['date'] as String),
        itemCount: (j['itemCount'] ?? (j['items'] as List?)?.length ?? 0) as int,
        items: [for (final i in (j['items'] ?? const []) as List) OrderItem.fromJson(i as Map<String, dynamic>)],
        history: [for (final h in (j['history'] ?? const []) as List) StatusChange.fromJson(h as Map<String, dynamic>)],
        note: '${j['note'] ?? ''}',
      );

  Order copyWith({String? status, List<StatusChange>? history}) => Order(
        id: id,
        customer: customer,
        customerId: customerId,
        amount: amount,
        status: status ?? this.status,
        date: date,
        itemCount: itemCount,
        items: items,
        history: history ?? this.history,
        note: note,
      );
}

/// What the orders screen asks for. Immutable, so a change always means a new query.
class OrderQuery {
  const OrderQuery({this.status, this.text = '', this.sort = '-date', this.page = 1, this.perPage = 10, this.customerId});
  final String? status;
  final String text, sort;
  final int page, perPage;
  final int? customerId;

  OrderQuery copyWith({String? status, bool clearStatus = false, String? text, String? sort, int? page, int? perPage}) => OrderQuery(
        status: clearStatus ? null : (status ?? this.status),
        text: text ?? this.text,
        sort: sort ?? this.sort,
        page: page ?? this.page,
        perPage: perPage ?? this.perPage,
        customerId: customerId,
      );

  Map<String, String> toParams() => {
        if (status != null) 'status': status!,
        if (text.isNotEmpty) 'q': text,
        if (customerId != null) 'customer_id': '$customerId',
        'sort': sort,
        'page': '$page',
        'per_page': '$perPage',
      };
}
