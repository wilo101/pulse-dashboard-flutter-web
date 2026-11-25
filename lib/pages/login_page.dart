import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/relay_api.dart';
import '../state/session_model.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _user = TextEditingController(text: 'admin');
  final _pass = TextEditingController();
  final _url = TextEditingController(text: RelayApi.defaultUrl);

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionModel>();
    final busy = s.state == SessionState.signingIn;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Pulse.', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              const Text('Sign in to your Relay server.'),
              const SizedBox(height: 24),
              TextField(controller: _url, decoration: const InputDecoration(labelText: 'Server URL')),
              const SizedBox(height: 12),
              TextField(controller: _user, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onSubmitted: (_) => _go(s),
              ),
              if (s.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: ErrorBanner(s.error!)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ink, shape: const RoundedRectangleBorder()),
                onPressed: busy ? null : () => _go(s),
                child: busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder()),
                onPressed: busy ? null : () => s.useSampleData(),
                child: const Text('Open with sample data'),
              ),
              TextButton(onPressed: busy ? null : () => s.useSampleData(role: 'viewer'), child: const Text('Open as a read-only viewer')),
            ]),
          ),
        ),
      ),
    );
  }

  void _go(SessionModel s) => s.signIn(_user.text.trim(), _pass.text, url: _url.text);
}
