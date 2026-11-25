import '../models/customer.dart';
import '../models/order.dart';
import '../models/stats.dart';

/// Everything the screens need from a backend. Two implementations: RelayApi (HTTP) and SampleApi (in memory).
abstract class PulseApi {
  /// True when talking to a real Relay server.
  bool get isLive;

  /// `admin` can change data, `viewer` can only read.
  String get role;
  bool get canWrite => role == 'admin';

  Future<void> signIn(String username, String password);
  Future<Paged<Order>> orders(OrderQuery q);
  Future<Order> order(int id);
  Future<Order> setStatus(int id, String status);

  /// Returns how many orders were changed.
  Future<int> bulkStatus(List<int> ids, String status);
  Future<String> ordersCsv(OrderQuery q);
  Future<Paged<Customer>> customers(CustomerQuery q);
  Future<Customer> customer(int id);
  Future<Customer> createCustomer(String name, String email, String city);
  Future<Stats> stats();
  Future<String> insights();
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  bool get isAuth => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isRateLimited => statusCode == 429;

  /// A short sentence that is safe to show to a person.
  String get friendly {
    if (isAuth) return 'Your session expired. Please sign in again.';
    if (isForbidden) return 'Your role is read-only.';
    if (isRateLimited) return 'Too many requests. Try again in a moment.';
    if (statusCode >= 500) return 'The server had a problem. Try again.';
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
