class Currency {
  const Currency(this.code, this.symbol, this.name);
  final String code, symbol, name;
}

const currencies = [
  Currency('USD', '\$', 'US dollar'),
  Currency('EUR', '€', 'Euro'),
  Currency('EGP', 'E£', 'Egyptian pound'),
  Currency('GBP', '£', 'Pound sterling'),
];

class Settings {
  const Settings({
    this.currencyCode = 'USD',
    this.compactNumbers = true,
    this.pageSize = 10,
    this.pendingAlert = true,
    this.pendingThreshold = 5,
    this.denseTables = false,
  });

  final String currencyCode;
  final bool compactNumbers, pendingAlert, denseTables;
  final int pageSize, pendingThreshold;

  Currency get currency => currencies.firstWhere((c) => c.code == currencyCode, orElse: () => currencies.first);

  Settings copyWith({
    String? currencyCode,
    bool? compactNumbers,
    int? pageSize,
    bool? pendingAlert,
    int? pendingThreshold,
    bool? denseTables,
  }) =>
      Settings(
        currencyCode: currencyCode ?? this.currencyCode,
        compactNumbers: compactNumbers ?? this.compactNumbers,
        pageSize: pageSize ?? this.pageSize,
        pendingAlert: pendingAlert ?? this.pendingAlert,
        pendingThreshold: pendingThreshold ?? this.pendingThreshold,
        denseTables: denseTables ?? this.denseTables,
      );
}
