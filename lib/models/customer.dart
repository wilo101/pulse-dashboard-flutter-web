class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.email,
    this.city = '',
    this.tags = const [],
    this.orders = 0,
    this.lifetimeValue = 0,
    this.lastOrderAt,
  });

  final int id, orders;
  final String name, email, city;
  final List<String> tags;
  final double lifetimeValue;
  final DateTime? lastOrderAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.length == 1 ? parts.first[0].toUpperCase() : (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool get isVip => tags.contains('vip');

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as int,
        name: '${j['name']}',
        email: '${j['email']}',
        city: '${j['city'] ?? ''}',
        tags: [for (final t in (j['tags'] ?? const []) as List) '$t'],
        orders: (j['orders'] ?? 0) as int,
        lifetimeValue: ((j['lifetimeValue'] ?? 0) as num).toDouble(),
        lastOrderAt: j['lastOrderAt'] == null ? null : DateTime.parse(j['lastOrderAt'] as String),
      );
}

class CustomerQuery {
  const CustomerQuery({this.text = '', this.tag, this.sort = 'name', this.page = 1, this.perPage = 20});
  final String text, sort;
  final String? tag;
  final int page, perPage;

  CustomerQuery copyWith({String? text, String? tag, bool clearTag = false, String? sort, int? page}) => CustomerQuery(
        text: text ?? this.text,
        tag: clearTag ? null : (tag ?? this.tag),
        sort: sort ?? this.sort,
        page: page ?? this.page,
        perPage: perPage,
      );

  Map<String, String> toParams() => {
        if (text.isNotEmpty) 'q': text,
        if (tag != null) 'tag': tag!,
        'sort': sort,
        'page': '$page',
        'per_page': '$perPage',
      };
}
