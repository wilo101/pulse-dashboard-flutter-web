import 'package:flutter/foundation.dart';
import '../core/api.dart';
import '../models/order.dart';
import 'dashboard_model.dart';

/// One order. Status changes show immediately and roll back if the server says no.
class OrderDetailModel extends ChangeNotifier {
  OrderDetailModel(this._api, this.id);
  final PulseApi _api;
  final int id;

  Load state = Load.idle;
  Order? order;
  String? error;
  bool saving = false;

  bool get canWrite => _api.canWrite;

  Future<void> load() async {
    state = Load.loading;
    notifyListeners();
    try {
      order = await _api.order(id);
      state = Load.ready;
    } on ApiException catch (e) {
      error = e.statusCode == 404 ? 'Order #$id was not found.' : e.friendly;
      state = Load.failed;
    }
    notifyListeners();
  }

  /// Returns true when the server accepted the change.
  Future<bool> changeStatus(String status) async {
    final before = order;
    if (before == null || before.status == status) return false;
    order = before.copyWith(status: status);
    saving = true;
    error = null;
    notifyListeners();
    try {
      order = await _api.setStatus(id, status);
      saving = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      order = before;
      error = e.friendly;
      saving = false;
      notifyListeners();
      return false;
    }
  }
}
