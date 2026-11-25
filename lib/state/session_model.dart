import 'package:flutter/foundation.dart';
import '../core/api.dart';
import '../core/relay_api.dart';
import '../core/sample_api.dart';

enum SessionState { signedOut, signingIn, signedIn }

/// Owns the API for the whole app. Screens never build their own clients.
class SessionModel extends ChangeNotifier {
  SessionModel({PulseApi Function(String url)? relayFactory}) : _relayFactory = relayFactory ?? ((url) => RelayApi(url));

  final PulseApi Function(String url) _relayFactory;
  SessionState state = SessionState.signedOut;
  PulseApi? _api;
  String? error;
  String serverUrl = RelayApi.defaultUrl;
  String username = '';

  PulseApi get api => _api ?? (throw StateError('Not signed in'));
  bool get signedIn => state == SessionState.signedIn;

  Future<void> signIn(String user, String pass, {String? url}) async {
    if (url != null && url.trim().isNotEmpty) serverUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    state = SessionState.signingIn;
    error = null;
    notifyListeners();
    final relay = _relayFactory(serverUrl);
    try {
      await relay.signIn(user, pass);
      _api = relay;
      username = user;
      state = SessionState.signedIn;
    } on ApiException catch (e) {
      // The server answered, so the problem is the credentials, not the connection.
      error = e.friendly;
      state = SessionState.signedOut;
    } catch (_) {
      error = 'Could not reach $serverUrl. You can still explore with sample data.';
      state = SessionState.signedOut;
    }
    notifyListeners();
  }

  /// Opens the app on in-memory sample data.
  void useSampleData({String role = 'admin'}) {
    _api = SampleApi(asRole: role);
    username = 'sample';
    error = null;
    state = SessionState.signedIn;
    notifyListeners();
  }

  void signOut() {
    _api = null;
    state = SessionState.signedOut;
    notifyListeners();
  }
}
