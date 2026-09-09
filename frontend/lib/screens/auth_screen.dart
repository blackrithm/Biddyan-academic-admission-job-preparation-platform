import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../providers/providers.dart';

/// Phone/password authentication screen with guest access.
///
/// On mobile the card fills the screen; on wide web canvases the brand hero
/// and login card are laid out in a centered column.
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final notifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Image.asset(
                      'assets/biddyan_logo.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const Text(
                      'বিদ্যান',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'BCS, ব্যাংক ও চাকরির পরীক্ষার আধুনিক প্রস্তুতি',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppConstants.mutedText,
                  ),
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _AccountForm(
                      authState: authState,
                      notifier: notifier,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: notifier.continueAsGuest,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Guest হিসেবে প্রবেশ করুন'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _AccountForm extends StatefulWidget {
  const _AccountForm({required this.authState, required this.notifier});

  final AuthState authState;
  final AuthNotifier notifier;

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loginMode = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = widget.authState;
    if (authState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final errorText = authState.errorMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null) ...[
          _ErrorBanner(text: errorText),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'মোবাইল নম্বর',
            hintText: '01XXXXXXXXX',
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _submit,
          child: Text(_loginMode ? 'লগইন করুন' : 'Account খুলুন'),
        ),
        TextButton(
          onPressed: () => setState(() => _loginMode = !_loginMode),
          child: Text(_loginMode
              ? 'নতুন account খুলুন'
              : 'আগের account-এ লগইন করুন'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (phone.length < 11 || password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক নম্বর এবং কমপক্ষে ৪ অক্ষরের password দিন')),
      );
      return;
    }
    if (_loginMode) {
      await widget.notifier.login(phone, password);
    } else {
      await widget.notifier.register(phone, password);
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}