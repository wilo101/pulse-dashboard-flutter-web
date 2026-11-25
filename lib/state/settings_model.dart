import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

/// App settings, saved on the device. Also the one place that formats money, so every screen agrees.
class SettingsModel extends ChangeNotifier {
  SettingsModel(this._prefs) {
    _value = Settings(
      currencyCode: _prefs.getString('currency') ?? 'USD',
      compactNumbers: _prefs.getBool('compact') ?? true,
      pageSize: _prefs.getInt('pageSize') ?? 10,
      pendingAlert: _prefs.getBool('pendingAlert') ?? true,
      pendingThreshold: _prefs.getInt('pendingThreshold') ?? 5,
      denseTables: _prefs.getBool('dense') ?? false,
    );
  }

  final SharedPreferences _prefs;
  late Settings _value;
  Settings get value => _value;

  static const pageSizes = [10, 20, 50];

  static Future<SettingsModel> load() async => SettingsModel(await SharedPreferences.getInstance());

  Future<void> update(Settings next) async {
    _value = next;
    await _prefs.setString('currency', next.currencyCode);
    await _prefs.setBool('compact', next.compactNumbers);
    await _prefs.setInt('pageSize', next.pageSize);
    await _prefs.setBool('pendingAlert', next.pendingAlert);
    await _prefs.setInt('pendingThreshold', next.pendingThreshold);
    await _prefs.setBool('dense', next.denseTables);
    notifyListeners();
  }

  Future<void> reset() => update(const Settings());

  String money(num amount) {
    final symbol = _value.currency.symbol;
    return _value.compactNumbers && amount.abs() >= 1000
        ? NumberFormat.compactCurrency(symbol: symbol, decimalDigits: 1).format(amount)
        : NumberFormat.currency(symbol: symbol, decimalDigits: amount == amount.roundToDouble() ? 0 : 2).format(amount);
  }
}
