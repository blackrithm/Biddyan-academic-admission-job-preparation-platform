import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

const _receiverNumber = '01301051585';

class ExamBatchPaymentScreen extends ConsumerStatefulWidget {
  const ExamBatchPaymentScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<ExamBatchPaymentScreen> createState() =>
      _ExamBatchPaymentScreenState();
}

class _ExamBatchPaymentScreenState
    extends ConsumerState<ExamBatchPaymentScreen> {
  static const _providers = ['bkash', 'nagad', 'rocket'];
  static const _providerLabels = {
    'bkash': 'bKash',
    'nagad': 'Nagad',
    'rocket': 'Rocket',
  };
  static const _providerColors = {
    'bkash': Color(0xFFD12053),
    'nagad': Color(0xFFF07824),
    'rocket': Color(0xFF743A9B),
  };

  final _formKey = GlobalKey<FormState>();
  final _paidFromNumber = TextEditingController();
  final _transactionId = TextEditingController();
  late Future<Map<String, dynamic>> _batchFuture;
  String _provider = 'bkash';
  bool _submitting = false;
  Map<String, dynamic>? _submittedPayment;

  @override
  void initState() {
    super.initState();
    _batchFuture = ExamService(apiClient).batchDetails(widget.batchId);
  }

  @override
  void dispose() {
    _paidFromNumber.dispose();
    _transactionId.dispose();
    super.dispose();
  }

  Future<void> _copyReceiver() async {
    await Clipboard.setData(const ClipboardData(text: _receiverNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('পেমেন্ট নম্বর কপি হয়েছে')),
    );
  }

  Future<void> _submit() async {
    if (ref.read(authNotifierProvider).user == null) {
      final redirect =
          Uri.encodeComponent('/exam-batches/${widget.batchId}/pay');
      await context.push('/account?redirect=$redirect');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final payment = await ExamService(apiClient).submitBatchPayment(
        batchId: widget.batchId,
        provider: _provider,
        paidFromNumber: _paidFromNumber.text.trim(),
        transactionId: _transactionId.text.trim(),
      );
      if (mounted) setState(() => _submittedPayment = payment);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppConstants.background,
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('ব্যাচ পেমেন্ট'),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _batchFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final batch = snapshot.data!;
            final price =
                double.tryParse(batch['price']?.toString() ?? '') ?? 0;
            final submitted = _submittedPayment;
            final paymentRequest = batch['payment_request'] as Map?;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      batch['name']?.toString() ?? 'Exam batch',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text('Mobile banking দিয়ে Send Money করুন'),
                    const SizedBox(height: 16),
                    if (submitted != null)
                      _PendingReceipt(payment: submitted)
                    else if (paymentRequest?['status'] == 'pending')
                      const _AlreadyPendingNotice()
                    else if (batch['is_enrolled'] == true)
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.verified, color: Colors.green),
                          title: Text('আপনি এই ব্যাচে enrolled'),
                        ),
                      )
                    else if (price <= 0)
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('এই batch-টি ফ্রি। পেমেন্ট লাগবে না।'),
                        ),
                      )
                    else ...[
                      _AmountPanel(price: price),
                      const SizedBox(height: 14),
                      SegmentedButton<String>(
                        segments: [
                          for (final provider in _providers)
                            ButtonSegment(
                              value: provider,
                              label: Text(_providerLabels[provider]!),
                            ),
                        ],
                        selected: {_provider},
                        onSelectionChanged: _submitting
                            ? null
                            : (selected) =>
                                setState(() => _provider = selected.first),
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: 12),
                      _ReceiverPanel(
                        provider: _providerLabels[_provider]!,
                        color: _providerColors[_provider]!,
                        onCopy: _copyReceiver,
                      ),
                      const SizedBox(height: 14),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _paidFromNumber,
                              enabled: !_submitting,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+ -]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'যে নম্বর থেকে টাকা পাঠিয়েছেন',
                                hintText: '01XXXXXXXXX',
                                prefixIcon: Icon(Icons.phone_android),
                              ),
                              validator: (value) {
                                final digits = (value ?? '')
                                    .replaceAll(RegExp(r'[\s-]'), '')
                                    .replaceFirst(RegExp(r'^\+?88'), '');
                                return RegExp(r'^01[3-9]\d{8}$')
                                        .hasMatch(digits)
                                    ? null
                                    : 'সঠিক ১১ সংখ্যার মোবাইল নম্বর লিখুন';
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _transactionId,
                              enabled: !_submitting,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9-]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Transaction ID',
                                hintText: 'পেমেন্টের SMS থেকে লিখুন',
                                prefixIcon: Icon(Icons.receipt_long_outlined),
                              ),
                              validator: (value) {
                                final valueToCheck = (value ?? '').trim();
                                return RegExp(r'^[a-zA-Z0-9-]{5,64}$')
                                        .hasMatch(valueToCheck)
                                    ? null
                                    : 'সঠিক Transaction ID লিখুন';
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: const Text('পেমেন্ট তথ্য জমা দিন'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppConstants.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'তথ্য জমা দিলে admin পেমেন্ট যাচাই করবেন। Approve না হওয়া পর্যন্ত paid exam unlock হবে না।',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppConstants.mutedText),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: BrandBottomNavigation(
          selectedIndex: 2,
          onSelected: (index) => BrandBottomNavigation.navigate(context, index),
        ),
      );
}

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({required this.price});

  final double price;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.payments_outlined,
                  color: AppConstants.accent, size: 28),
              const SizedBox(width: 12),
              const Expanded(child: Text('Auto amount')),
              Text(
                '৳${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
}

class _ReceiverPanel extends StatelessWidget {
  const _ReceiverPanel({
    required this.provider,
    required this.color,
    required this.onCopy,
  });

  final String provider;
  final Color color;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(provider,
                        style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ),
                  const Chip(
                    avatar: Icon(Icons.send_outlined, size: 16),
                    label: Text('Send Money'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('এই নম্বরে Send Money করুন'),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(
                    child: SelectableText(
                      _receiverNumber,
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'নম্বর কপি করুন',
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _PendingReceipt extends StatelessWidget {
  const _PendingReceipt({required this.payment});

  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(Icons.hourglass_top,
                  color: AppConstants.golden, size: 42),
              const SizedBox(height: 10),
              const Text('পেমেন্ট তথ্য জমা হয়েছে',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                'Admin যাচাই করে approve করলে batch enrollment স্বয়ংক্রিয়ভাবে হবে।',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text('Transaction ID: ${payment['transaction_id'] ?? ''}'),
            ],
          ),
        ),
      );
}

class _AlreadyPendingNotice extends StatelessWidget {
  const _AlreadyPendingNotice();

  @override
  Widget build(BuildContext context) => const Card(
        child: ListTile(
          leading: Icon(Icons.hourglass_top, color: AppConstants.golden),
          title: Text('আপনার পেমেন্ট যাচাই চলছে'),
          subtitle:
              Text('একই batch-এর জন্য আরেকটি request জমা দেওয়া যাবে না।'),
        ),
      );
}
