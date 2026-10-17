import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

class AdminExamBatchPaymentsScreen extends StatefulWidget {
  const AdminExamBatchPaymentsScreen({super.key});

  @override
  State<AdminExamBatchPaymentsScreen> createState() =>
      _AdminExamBatchPaymentsScreenState();
}

class _AdminExamBatchPaymentsScreenState
    extends State<AdminExamBatchPaymentsScreen> {
  late Future<List<Map<String, dynamic>>> _payments;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _payments = ExamService(apiClient).adminBatchPayments();
  }

  Future<void> _saveEdit(Map<String, dynamic> payment) async {
    final edited = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditPaymentDialog(payment: payment),
    );
    if (edited == null) return;
    try {
      await ExamService(apiClient).updateBatchPayment(
        paymentId: payment['id'].toString(),
        provider: edited['provider'],
        paidFromNumber: edited['paidFromNumber'],
        transactionId: edited['transactionId'],
      );
      if (mounted) setState(_load);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _review(Map<String, dynamic> payment, String status) async {
    String? note;
    if (status == 'failed') {
      note = await showDialog<String>(
        context: context,
        builder: (_) => const _PaymentFailureReasonDialog(),
      );
      if (note == null) return;
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('পেমেন্ট approve করবেন?'),
          content: Text(
              '${payment['student_name']} — ${payment['batch_name']} ব্যাচে enroll হবে।'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('বাতিল')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Approve ও enroll')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      await ExamService(apiClient).updateBatchPayment(
        paymentId: payment['id'].toString(),
        status: status,
        reviewNote: note,
      );
      if (mounted) {
        setState(_load);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'approved'
                ? 'পেমেন্ট approved; শিক্ষার্থী enrolled হয়েছে।'
                : 'পেমেন্ট failed হিসেবে সংরক্ষণ হয়েছে।'),
          ),
        );
      }
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Exam Batch Enrollers'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => setState(_load),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _payments,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final all = snapshot.data ?? const [];
            final payments = _filter == 'all'
                ? all
                : all.where((item) => item['status'] == _filter).toList();
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'pending', label: Text('Pending')),
                          ButtonSegment(
                              value: 'approved', label: Text('Approved')),
                          ButtonSegment(value: 'failed', label: Text('Failed')),
                          ButtonSegment(value: 'all', label: Text('সব')),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (selection) =>
                            setState(() => _filter = selection.first),
                      ),
                    ),
                    Expanded(
                      child: payments.isEmpty
                          ? const Center(
                              child:
                                  Text('এই filter-এ কোনো payment request নেই।'))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                              itemCount: payments.length,
                              itemBuilder: (context, index) =>
                                  _PaymentRequestCard(
                                payment: payments[index],
                                onEdit: () => _saveEdit(payments[index]),
                                onApprove: () =>
                                    _review(payments[index], 'approved'),
                                onFail: () =>
                                    _review(payments[index], 'failed'),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: BrandBottomNavigation(
          selectedIndex: 4,
          onSelected: (index) => BrandBottomNavigation.navigate(context, index),
        ),
      );
}

class _PaymentRequestCard extends StatelessWidget {
  const _PaymentRequestCard({
    required this.payment,
    required this.onEdit,
    required this.onApprove,
    required this.onFail,
  });

  final Map<String, dynamic> payment;
  final VoidCallback onEdit;
  final VoidCallback onApprove;
  final VoidCallback onFail;

  @override
  Widget build(BuildContext context) {
    final pending = payment['status'] == 'pending';
    final provider = switch (payment['provider']) {
      'bkash' => 'bKash',
      'nagad' => 'Nagad',
      'rocket' => 'Rocket',
      _ => payment['provider'].toString(),
    };
    final statusColor = switch (payment['status']) {
      'approved' => const Color(0xFF16845B),
      'failed' => AppConstants.accent,
      _ => AppConstants.golden,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(payment['batch_name']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                Chip(
                  label: Text(payment['status'].toString().toUpperCase()),
                  labelStyle: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Text(
                '${payment['student_name']}  •  ${payment['student_phone'] ?? ''}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _PaymentDetail(label: provider),
                _PaymentDetail(label: 'Send Money'),
                _PaymentDetail(label: '৳${payment['amount']}'),
                _PaymentDetail(label: 'From ${payment['paid_from_number']}'),
                _PaymentDetail(label: 'Txn ${payment['transaction_id']}'),
              ],
            ),
            if ((payment['review_note'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('কারণ: ${payment['review_note']}'),
            ],
            if (pending) ...[
              const Divider(height: 22),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit details'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onFail,
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Payment failed'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.accent),
                  ),
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve & enroll'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  const _PaymentDetail({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        visualDensity: VisualDensity.compact,
        label: Text(label),
      );
}

class _EditPaymentDialog extends StatefulWidget {
  const _EditPaymentDialog({required this.payment});

  final Map<String, dynamic> payment;

  @override
  State<_EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<_EditPaymentDialog> {
  late String _provider;
  late final TextEditingController _number;
  late final TextEditingController _transactionId;

  @override
  void initState() {
    super.initState();
    _provider = widget.payment['provider'].toString();
    _number = TextEditingController(
        text: widget.payment['paid_from_number'].toString());
    _transactionId = TextEditingController(
        text: widget.payment['transaction_id'].toString());
  }

  @override
  void dispose() {
    _number.dispose();
    _transactionId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Payment details edit করুন'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _provider,
                items: const [
                  DropdownMenuItem(value: 'bkash', child: Text('bKash')),
                  DropdownMenuItem(value: 'nagad', child: Text('Nagad')),
                  DropdownMenuItem(value: 'rocket', child: Text('Rocket')),
                ],
                onChanged: (value) =>
                    setState(() => _provider = value ?? _provider),
                decoration: const InputDecoration(labelText: 'Provider'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _number,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Payer number'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _transactionId,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Transaction ID'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বাতিল')),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'provider': _provider,
              'paidFromNumber': _number.text.trim(),
              'transactionId': _transactionId.text.trim(),
            }),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      );
}

class _PaymentFailureReasonDialog extends StatefulWidget {
  const _PaymentFailureReasonDialog();

  @override
  State<_PaymentFailureReasonDialog> createState() =>
      _PaymentFailureReasonDialogState();
}

class _PaymentFailureReasonDialogState
    extends State<_PaymentFailureReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Payment failed হিসেবে mark করুন'),
        content: TextField(
          controller: _reason,
          autofocus: true,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'কারণ',
            hintText: 'Transaction ID মেলেনি…',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বাতিল')),
          FilledButton(
            onPressed: _reason.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, _reason.text.trim()),
            child: const Text('Payment failed'),
          ),
        ],
      );
}
