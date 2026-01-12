import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../../../../../providers/carrier_payments_provider.dart';
import '../../../../../../providers/auth_provider.dart';
import 'carrier_add_payment_method.dart';
import '../../../../../../core/stripe_service.dart';
import '../../common/widgets/top_navigation_bar.dart';

class CarrierPaymentPage extends StatefulWidget {
  const CarrierPaymentPage({super.key});

  @override
  State<CarrierPaymentPage> createState() => _CarrierPaymentPageState();
}

class _CarrierPaymentPageState extends State<CarrierPaymentPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter; // null means all statuses
  bool _hasStripeAccount = false;
  bool _isCheckingAccount = true;
  bool _isSettingUp = false;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Load data (uses cache if available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CarrierPaymentsProvider>();
      provider.loadPayments();
      _checkStripeAccountStatus();
    });
  }

  Future<void> _checkStripeAccountStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _hasStripeAccount = false;
          _needsOnboarding = false;
          _isCheckingAccount = false;
        });
        return;
      }

      // Check account status from Stripe
      try {
        final status = await StripeService.getConnectAccountStatus();
        final hasAccount = status['hasAccount'] as bool? ?? false;
        final needsOnboarding = status['needsOnboarding'] as bool? ?? false;

        if (mounted) {
          setState(() {
            _hasStripeAccount = hasAccount;
            _needsOnboarding = needsOnboarding;
            _isCheckingAccount = false;
          });
        }

        // If account exists but needs onboarding, automatically create Account Link
        if (hasAccount && needsOnboarding) {
          await _createOnboardingLink();
        }
      } catch (e) {
        debugPrint('Error getting Connect account status: $e');
        // Fallback to Firebase check
        final carrierDoc = await FirebaseFirestore.instance
            .collection('carriers')
            .doc(currentUser.uid)
            .get();

        if (mounted) {
          setState(() {
            _hasStripeAccount =
                carrierDoc.data()?['stripeAccountId'] != null &&
                (carrierDoc.data()?['stripeAccountId'] as String).isNotEmpty;
            _needsOnboarding =
                _hasStripeAccount; // Assume needs onboarding if we can't check
            _isCheckingAccount = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking Stripe account status: $e');
      if (mounted) {
        setState(() {
          _hasStripeAccount = false;
          _needsOnboarding = false;
          _isCheckingAccount = false;
        });
      }
    }
  }

  Future<void> _createOnboardingLink() async {
    try {
      final onboardingUrl = await StripeService.createAccountLink();
      debugPrint('Onboarding URL: $onboardingUrl');

      if (mounted) {
        // Automatically open the onboarding URL
        final uri = Uri.parse(onboardingUrl);
        try {
          if (await canLaunchUrl(uri)) {
            final launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );

            if (!launched) {
              throw Exception('Failed to launch URL');
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Your account needs activation. Please complete the onboarding process.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          } else {
            throw Exception('URL cannot be launched: $onboardingUrl');
          }
        } catch (e) {
          debugPrint('Error launching onboarding URL: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Could not open onboarding page: ${e.toString()}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error creating onboarding link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create onboarding link: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _setupStripeConnectAccount() async {
    if (_isSettingUp) return;

    setState(() {
      _isSettingUp = true;
    });

    try {
      // Step 1: Create Connect account if it doesn't exist
      try {
        await StripeService.createConnectAccount();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to create account: ${StripeService.getErrorMessage(e)}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Step 2: Create Account Link for onboarding
      String onboardingUrl;
      try {
        onboardingUrl = await StripeService.createAccountLink();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to create onboarding link: ${StripeService.getErrorMessage(e)}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Step 3: Open onboarding URL in browser
      debugPrint('Onboarding URL: $onboardingUrl');
      final uri = Uri.parse(onboardingUrl);

      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (!launched) {
            throw Exception('Failed to launch URL');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please complete the onboarding process. Return to the app when done.',
                ),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 5),
              ),
            );
          }

          // Wait a bit then check status
          await Future.delayed(const Duration(seconds: 3));
          await _checkStripeAccountStatus();
        } else {
          throw Exception('URL cannot be launched: $onboardingUrl');
        }
      } catch (e) {
        debugPrint('Error launching onboarding URL: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open onboarding page: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error setting up Stripe Connect account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${StripeService.getErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSettingUp = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectFromDate() async {
    // Unfocus any text fields before showing picker
    FocusScope.of(context).unfocus();

    final initialDate = _fromDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: _toDate ?? DateTime.now(),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        final picked = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _fromDate = picked;
        });
        await context.read<CarrierPaymentsProvider>().loadPayments(
          forceRefresh: true,
          fromDate: _fromDate,
          toDate: _toDate,
        );
      }
    }
  }

  Future<void> _selectToDate() async {
    // Unfocus any text fields before showing picker
    FocusScope.of(context).unfocus();

    final initialDate = _toDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        final picked = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _toDate = picked;
        });
        await context.read<CarrierPaymentsProvider>().loadPayments(
          forceRefresh: true,
          fromDate: _fromDate,
          toDate: _toDate,
        );
      }
    }
  }

  Future<void> _clearDateFilters() async {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    await context.read<CarrierPaymentsProvider>().loadPayments(
      forceRefresh: true,
      fromDate: null,
      toDate: null,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  String _formatTransferId(String transferId) {
    // Extract last 4 characters for display
    if (transferId.length > 4) {
      return 'RM-${transferId.substring(transferId.length - 4)}';
    }
    return 'RM-$transferId';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'completed':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'canceled':
        return 'Canceled';
      default:
        return 'Unknown';
    }
  }

  List<Map<String, dynamic>> _filterPayments(
    List<Map<String, dynamic>> payments,
  ) {
    String searchQuery = _searchController.text.toLowerCase().trim();

    return payments.where((payment) {
      // Status filter
      if (_statusFilter != null) {
        final status = payment['status'] as String? ?? 'unknown';
        final statusLower = status.toLowerCase();
        final filterLower = _statusFilter!.toLowerCase();

        // Handle multiple status values that map to the same filter
        if (filterLower == 'succeeded') {
          if (statusLower != 'succeeded' &&
              statusLower != 'completed' &&
              statusLower != 'paid') {
            return false;
          }
        } else if (statusLower != filterLower) {
          return false;
        }
      }

      // Date filter (already applied in provider, but double-check here with time component)
      if (_fromDate != null || _toDate != null) {
        final paymentDate =
            payment['succeededAt'] as DateTime? ??
            payment['completedAt'] as DateTime? ??
            payment['createdAt'] as DateTime?;

        if (paymentDate != null) {
          // For fromDate: payment must be on or after the selected date/time
          if (_fromDate != null && paymentDate.isBefore(_fromDate!)) {
            return false;
          }
          // For toDate: payment must be on or before the selected date/time (respecting time component)
          if (_toDate != null && paymentDate.isAfter(_toDate!)) {
            return false;
          }
        }
      }

      // Search filter - search by shipper name, transfer ID, amount, or load number
      if (searchQuery.isNotEmpty) {
        final transferId = _formatTransferId(
          payment['transferId'] as String? ?? '',
        ).toLowerCase();
        final shipperName = (payment['shipperName'] as String? ?? '')
            .toLowerCase();
        final amount = payment['amount'] as int? ?? 0;
        final amountStr = (amount ~/ 100).toString();
        final status = _getStatusText(
          payment['status'] as String? ?? 'unknown',
        ).toLowerCase();
        final loadNumber = (payment['loadNumber'] as String? ?? '')
            .toLowerCase();

        if (!transferId.contains(searchQuery) &&
            !shipperName.contains(searchQuery) &&
            !amountStr.contains(searchQuery) &&
            !status.contains(searchQuery) &&
            !loadNumber.contains(searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _showFilterDialog() async {
    String? selectedFilter = _statusFilter;
    const String cancelSentinel = '__CANCEL__';

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter by Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String?>(
                title: const Text('All'),
                value: null,
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
              RadioListTile<String?>(
                title: const Text('Paid'),
                value: 'succeeded',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
              RadioListTile<String?>(
                title: const Text('Pending'),
                value: 'pending',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
              RadioListTile<String?>(
                title: const Text('Processing'),
                value: 'processing',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
              RadioListTile<String?>(
                title: const Text('Failed'),
                value: 'failed',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
              RadioListTile<String?>(
                title: const Text('Canceled'),
                value: 'canceled',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, cancelSentinel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedFilter),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result != cancelSentinel) {
      setState(() {
        _statusFilter = result;
      });
    }
  }

  String _formatReceipt(
    Map<String, dynamic> payment,
    dynamic carrier, {
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('        PAYMENT RECEIPT');
    buffer.writeln('');
    buffer.writeln('Remiles Logistics');
    buffer.writeln('Payment Transfer Receipt');
    buffer.writeln('');
    buffer.writeln('----------------------------------------');
    buffer.writeln(
      'Transfer ID: ${_formatTransferId(payment['transferId'] as String? ?? '')}',
    );
    buffer.writeln(
      'Date: ${_formatDate(payment['succeededAt'] as DateTime? ?? payment['createdAt'] as DateTime?)}',
    );
    buffer.writeln(
      'Status: ${_getStatusText(payment['status'] as String? ?? 'unknown')}',
    );
    if (fromDate != null || toDate != null) {
      buffer.writeln('');
      if (fromDate != null && toDate != null) {
        buffer.writeln(
          'Period: ${_formatDate(fromDate)} to ${_formatDate(toDate)}',
        );
      } else if (fromDate != null) {
        buffer.writeln('From Date: ${_formatDate(fromDate)}');
      } else if (toDate != null) {
        buffer.writeln('To Date: ${_formatDate(toDate)}');
      }
    }
    buffer.writeln('');
    buffer.writeln(
      'From: ${payment['shipperName'] as String? ?? 'Unknown Shipper'}',
    );
    buffer.writeln('To: ${carrier?.companyName ?? carrier?.name ?? 'Carrier'}');
    buffer.writeln('');
    buffer.writeln(
      'Load ID: ${payment['loadNumber'] as String? ?? payment['loadId'] as String? ?? 'N/A'}',
    );
    buffer.writeln('');
    buffer.writeln('----------------------------------------');
    final amount = payment['amount'] as int? ?? 0;
    buffer.writeln('Amount: \$${(amount / 100).toStringAsFixed(2)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('');
    buffer.writeln('Thank you for using Remiles!');
    buffer.writeln('');
    return buffer.toString();
  }

  Future<void> _printReceipt(
    BuildContext context,
    Map<String, dynamic> payment,
  ) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;
      final receiptText = _formatReceipt(
        payment,
        carrier,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      await Printing.layoutPdf(
        onLayout: (format) async =>
            await _generateReceiptPDF(receiptText, payment, carrier),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing receipt: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generateReceiptPDF(
    String receiptText,
    Map<String, dynamic> payment,
    dynamic carrier,
  ) async {
    final pdf = pw.Document();
    final lines = receiptText.split('\n');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: lines.map((line) {
              if (line.trim().isEmpty) {
                return pw.SizedBox(height: 8);
              } else if (line.contains('PAYMENT RECEIPT')) {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                );
              } else if (line.contains('---')) {
                return pw.Divider();
              } else if (line.contains('Amount:')) {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                );
              } else {
                return pw.Text(
                  line,
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                );
              }
            }).toList(),
          );
        },
      ),
    );

    return pdf.save();
  }

  void _copyReceipt(BuildContext context, Map<String, dynamic> payment) {
    final authProvider = context.read<AuthProvider>();
    final carrier = authProvider.carrierUser;
    final receiptText = _formatReceipt(
      payment,
      carrier,
      fromDate: _fromDate,
      toDate: _toDate,
    );

    Clipboard.setData(ClipboardData(text: receiptText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showPaymentDetails(Map<String, dynamic> payment) async {
    final authProvider = context.read<AuthProvider>();
    final carrier = authProvider.carrierUser;
    final status = payment['status'] as String? ?? 'unknown';
    final amount = payment['amount'] as int? ?? 0;
    final date =
        payment['succeededAt'] as DateTime? ??
        payment['completedAt'] as DateTime? ??
        payment['createdAt'] as DateTime?;
    final transferId = payment['transferId'] as String? ?? 'N/A';
    final shipperName = payment['shipperName'] as String? ?? 'Unknown Shipper';
    final loadNumber =
        payment['loadNumber'] as String? ??
        payment['loadId'] as String? ??
        'N/A';
    final shipperId = payment['shipperId'] as String?;

    // Unfocus any text fields before showing dialog
    FocusScope.of(context).unfocus();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Transfer ID', _formatTransferId(transferId)),
              _buildDetailRow('Date & Time', _formatDate(date)),
              _buildDetailRow(
                'Status',
                _getStatusText(status),
                color: _getStatusColor(status),
              ),
              _buildDetailRow(
                'Amount',
                '\$${(amount / 100).toStringAsFixed(2)}',
                color: const Color(0xFF186230),
              ),
              const Divider(),
              _buildDetailRow('From', shipperName),
              _buildDetailRow(
                'To',
                carrier?.companyName ?? carrier?.displayName ?? 'Carrier',
              ),
              _buildDetailRow('Load Number', loadNumber),
              if (shipperId != null) _buildDetailRow('Shipper ID', shipperId),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _copyReceipt(context, payment);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _printReceipt(context, payment);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF186230),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printAllPayments(List<Map<String, dynamic>> payments) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;

      final buffer = StringBuffer();
      buffer.writeln('');
      buffer.writeln('        PAYMENTS REPORT');
      buffer.writeln('');
      buffer.writeln('Remiles Logistics');
      buffer.writeln('Payment Receipts Report');
      buffer.writeln('');
      buffer.writeln('----------------------------------------');
      buffer.writeln(
        'To: ${carrier?.companyName ?? carrier?.displayName ?? 'Carrier'}',
      );
      buffer.writeln('Report Date: ${_formatDate(DateTime.now())}');
      if (_fromDate != null || _toDate != null) {
        buffer.writeln('');
        if (_fromDate != null && _toDate != null) {
          buffer.writeln(
            'Period: ${_formatDate(_fromDate)} to ${_formatDate(_toDate)}',
          );
        } else if (_fromDate != null) {
          buffer.writeln('From Date: ${_formatDate(_fromDate)}');
        } else if (_toDate != null) {
          buffer.writeln('To Date: ${_formatDate(_toDate)}');
        }
      }
      if (_statusFilter != null) {
        buffer.writeln('Status Filter: ${_getStatusText(_statusFilter!)}');
      }
      buffer.writeln('Total Payments: ${payments.length}');
      buffer.writeln('----------------------------------------');
      buffer.writeln('');

      double totalAmount = 0;
      for (var payment in payments) {
        final amount = payment['amount'] as int? ?? 0;
        totalAmount += amount / 100;

        buffer.writeln(
          'Transfer ID: ${_formatTransferId(payment['transferId'] as String? ?? 'N/A')}',
        );
        buffer.writeln(
          'Date: ${_formatDate(payment['succeededAt'] as DateTime? ?? payment['completedAt'] as DateTime? ?? payment['createdAt'] as DateTime?)}',
        );
        buffer.writeln(
          'From: ${payment['shipperName'] as String? ?? 'Unknown Shipper'}',
        );
        buffer.writeln(
          'Load: ${payment['loadNumber'] as String? ?? payment['loadId'] as String? ?? 'N/A'}',
        );
        buffer.writeln('Amount: \$${(amount / 100).toStringAsFixed(2)}');
        buffer.writeln(
          'Status: ${_getStatusText(payment['status'] as String? ?? 'unknown')}',
        );
        buffer.writeln('---');
      }

      buffer.writeln('');
      buffer.writeln('----------------------------------------');
      buffer.writeln('Total Amount: \$${totalAmount.toStringAsFixed(2)}');
      buffer.writeln('----------------------------------------');
      buffer.writeln('');
      buffer.writeln('Thank you for using Remiles!');
      buffer.writeln('');

      final reportText = buffer.toString();

      await Printing.layoutPdf(
        onLayout: (format) async =>
            await _generateReportPDF(reportText, payments.length, totalAmount),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generateReportPDF(
    String reportText,
    int count,
    double totalAmount,
  ) async {
    final pdf = pw.Document();
    final lines = reportText.split('\n');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: lines.map((line) {
              if (line.trim().isEmpty) {
                return pw.SizedBox(height: 8);
              } else if (line.contains('PAYMENTS REPORT') ||
                  line.contains('Total Amount:')) {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                );
              } else if (line.contains('---')) {
                return pw.Divider();
              } else if (line.contains('Amount:') || line.contains('Total:')) {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                );
              } else {
                return pw.Text(
                  line,
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.black),
                );
              }
            }).toList(),
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final bool isWide = screenW >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: SafeArea(
        child: Consumer<CarrierPaymentsProvider>(
          builder: (context, provider, child) {
            final allPayments = provider.payments;
            final filteredPayments = _filterPayments(allPayments);
            final isLoading = provider.isLoading && allPayments.isEmpty;

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadPayments(
                  forceRefresh: true,
                  fromDate: _fromDate,
                  toDate: _toDate,
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    /// Top Navigation (Logo/Icons) - Full Width
                    TopNavigationBar(context),
                    const SizedBox(height: 20),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 100.0 : 20.0,
                        vertical: 20,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              /// Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Payments Received",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF186230),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              /// Summary Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF43975A),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          '${filteredPayments.length}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF186230),
                                          ),
                                        ),
                                        const Text(
                                          'Total Payments',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.grey.shade300,
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '\$${((filteredPayments.fold<int>(0, (sum, p) => sum + (p['amount'] as int? ?? 0))) / 100).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF186230),
                                          ),
                                        ),
                                        const Text(
                                          'Total Amount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              /// Stripe Connect Account Setup or Payment Methods
                              if (_isCheckingAccount)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (!_hasStripeAccount || _needsOnboarding)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFBBF7D0),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Color(0xFF166534),
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: const Text(
                                                    'Payment Setup Required',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                      color: Color(0xFF166534),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Tooltip(
                                                  triggerMode:
                                                      TooltipTriggerMode.tap,
                                                  message:
                                                      'Setting up your Stripe account is essential to receive payments directly for the loads you deliver. It ensures a secure and automated payout process.',
                                                  child: const Icon(
                                                    Icons.info_outline,
                                                    size: 16,
                                                    color: Color(0xFF166534),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              _hasStripeAccount
                                                  ? 'Please complete your payment account activation.'
                                                  : 'Please setup your payment account to receive payouts.',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF166534),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      TextButton(
                                        onPressed: _isSettingUp
                                            ? null
                                            : _setupStripeConnectAccount,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          backgroundColor: const Color(
                                            0xFF166534,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: _isSettingUp
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                _hasStripeAccount
                                                    ? 'Complete'
                                                    : 'Setup Now',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),

                              if (_hasStripeAccount && !_needsOnboarding)
                                SizedBox(
                                  width: double.infinity, // ✅ Full width
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CarrierAddPaymentMethod(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF43A047), // fresh green
                                            Color(
                                              0xFF1B5E20,
                                            ), // deep premium green
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF43A047,
                                            ).withOpacity(0.35),
                                            blurRadius: 18,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.payment_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Payment Methods',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),

                              /// Actions: Search, Filter, Date, Print
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search payments...',
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon:
                                            _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {});
                                                },
                                              )
                                            : null,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 0,
                                            ),
                                      ),
                                      onChanged: (value) => setState(() {}),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _showFilterDialog,
                                            icon: const Icon(Icons.filter_list),
                                            label: Text(
                                              _statusFilter == null
                                                  ? 'Filter'
                                                  : _getStatusText(
                                                      _statusFilter!,
                                                    ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              _printAllPayments(
                                                filteredPayments,
                                              );
                                            },
                                            icon: const Icon(Icons.print),
                                            label: const Text('Export PDF'),
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDateField(
                                            "From",
                                            _fromDate,
                                            _selectFromDate,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildDateField(
                                            "To",
                                            _toDate,
                                            _selectToDate,
                                          ),
                                        ),
                                        if (_fromDate != null ||
                                            _toDate != null)
                                          IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: _clearDateFilters,
                                            tooltip: 'Clear dates',
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// Payments List
                              if (filteredPayments.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.payment,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          allPayments.isEmpty
                                              ? 'No payments received yet'
                                              : 'No payments match your filters',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...filteredPayments.map((payment) {
                                  final status =
                                      payment['status'] as String? ?? 'unknown';
                                  final amount = payment['amount'] as int? ?? 0;
                                  final date =
                                      payment['succeededAt'] as DateTime? ??
                                      payment['completedAt'] as DateTime? ??
                                      payment['createdAt'] as DateTime?;
                                  final transferId =
                                      payment['transferId'] as String? ?? '';
                                  final shipperName =
                                      payment['shipperName'] as String? ??
                                      'Unknown Shipper';

                                  return GestureDetector(
                                    onTap: () => _showPaymentDetails(payment),
                                    child: _buildPaymentCard(
                                      _formatTransferId(transferId),
                                      _formatDate(date),
                                      amount ~/ 100,
                                      _getStatusText(status),
                                      _getStatusColor(status),
                                      shipperName,
                                      payment['loadNumber'] as String? ??
                                          payment['loadId'] as String? ??
                                          'N/A',
                                      payment,
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('MMM dd, yyyy hh:mm a').format(date)
                        : 'Select date & time',
                    style: TextStyle(
                      color: date != null ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(
    String id,
    String date,
    int amount,
    String status,
    Color statusColor,
    String shipperName,
    String loadNumber,
    Map<String, dynamic> payment,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFF43975A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shipperName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Load:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loadNumber,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "\$$amount",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF186230),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
