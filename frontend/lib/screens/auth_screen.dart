import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../providers/providers.dart';

/// Responsive OTP + social-login authentication screen.
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
                const Text(
                  'বিদ্যান',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.primary,
                  ),
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
                    child: _OtpForm(
                      authState: authState,
                      notifier: notifier,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'অথবা',
                        style: TextStyle(color: AppConstants.mutedText),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => notifier.socialLogin('Google'),
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('Google'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => notifier.socialLogin('Facebook'),
                        icon: const Icon(Icons.facebook),
                        label: const Text('Facebook'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _OtpForm extends StatefulWidget {
    const _OtpForm({required this.authState, required this.notifier});

  final AuthState authState;
  final AuthNotifier notifier;

  @override
  State<_OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<_OtpForm> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _sending = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = widget.authState;
    if (authState.isLoading || _sending) {
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
        if (!_otpSent) ...[
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.number,
            maxLength: 11,
            decoration: const InputDecoration(
              labelText: 'মোবাইল নম্বর',
              hintText: '01XXXXXXXXX',
              prefixIcon: Icon(Icons.phone_android),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _requestOtp(),
            child: const Text('ওটিপি পাঠান'),
          ),
        ] else ...[
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'ওটিপি কোড',
              hintText: '6 ডিজিটের কোড',
              prefixIcon: Icon(Icons.sms),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => widget.notifier.loginWithOtp(
              _phoneCtrl.text.trim(),
              _otpCtrl.text.trim(),
            ),
            child: const Text('লগইন করুন'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: (_resendSeconds > 0)
                ? null
                : () {
                    _requestOtp();
                    _startResendTimer();
                  },
            child: Text(
              _resendSeconds > 0
                  ? 'আবার পাঠান (${_resendSeconds}s)'
                  : 'আবার ওটিপি পাঠান',
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _requestOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক মোবাইল নম্বর লিখুন')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.notifier.requestOtp(phone);
      _otpSent = true;
      _startResendTimer();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendSeconds = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          _resendTimer?.cancel();
          _resendTimer = null;
        }
      });
    });
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