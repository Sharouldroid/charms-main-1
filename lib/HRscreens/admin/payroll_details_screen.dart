import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:charms/utils/pdf_download.dart';

class PayrollDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> payrollRecord;

  const PayrollDetailsScreen({
    super.key,
    required this.payrollRecord,
  });

  @override
  State<PayrollDetailsScreen> createState() => _PayrollDetailsScreenState();
}

class _PayrollDetailsScreenState extends State<PayrollDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController basicPayController;
  late TextEditingController grossPayController;
  late TextEditingController netSalaryController;
  late TextEditingController bonusController;
  late TextEditingController deductionController;

  bool _publishing = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();

    basicPayController = TextEditingController(
      text: (widget.payrollRecord['basicPay'] ?? 0).toString(),
    );
    grossPayController = TextEditingController(
      text: (widget.payrollRecord['grossPay'] ?? 0).toString(),
    );
    netSalaryController = TextEditingController(
      text: (widget.payrollRecord['netSalary'] ?? 0).toString(),
    );
    bonusController = TextEditingController(
      text: (widget.payrollRecord['bonus'] ?? 0).toString(),
    );
    deductionController = TextEditingController(
      text: (widget.payrollRecord['deduction'] ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    basicPayController.dispose();
    grossPayController.dispose();
    netSalaryController.dispose();
    bonusController.dispose();
    deductionController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return '$field must be a valid number';
    if (parsed < 0) return '$field cannot be negative';
    return null;
  }

  double _toDouble(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  String _rm(num value) => 'RM ${value.toStringAsFixed(2)}';

  void _recalculateFromBasic() {
    final basic = _toDouble(basicPayController);
    final bonus = _toDouble(bonusController);
    final deduction = _toDouble(deductionController);

    final gross = basic + bonus;
    final net = gross - deduction;

    grossPayController.text = gross.toStringAsFixed(2);
    netSalaryController.text = net.toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _publishPayroll() async {
    if (_publishing) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _publishing = true);

    try {
      final updatedRecord = <String, dynamic>{
        ...widget.payrollRecord,
        'basicPay': _toDouble(basicPayController),
        'bonus': _toDouble(bonusController),
        'deduction': _toDouble(deductionController),
        'grossPay': _toDouble(grossPayController),
        'netSalary': _toDouble(netSalaryController),
        'published': true,
        'publishedAt': DateTime.now().toIso8601String(),
      };

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payroll published for ${widget.payrollRecord['staffName'] ?? 'staff'}',
          ),
        ),
      );

      Navigator.pop(context, updatedRecord);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish payroll: $e')),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<Uint8List> _generatePayrollPdfBytes() async {
    final pdf = pw.Document();

    final staffName = '${widget.payrollRecord['staffName'] ?? '-'}';
    final staffId = '${widget.payrollRecord['staffId'] ?? '-'}';
    final month = '${widget.payrollRecord['month'] ?? '-'}';

    final basic = _toDouble(basicPayController);
    final bonus = _toDouble(bonusController);
    final deduction = _toDouble(deductionController);
    final gross = _toDouble(grossPayController);
    final net = _toDouble(netSalaryController);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'SEATRU X CMS',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Payslip for $month',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              _pdfRow('Staff ID', staffId),
              _pdfRow('Name', staffName),
              _pdfRow('Basic Pay', _rm(basic)),
              _pdfRow('Total Bonus', _rm(bonus)),
              _pdfRow('Total Deduction', _rm(deduction)),
              _pdfRow('Gross Pay', _rm(gross)),
              pw.Divider(),
              _pdfRow(
                'Total Salary',
                _rm(net),
                valueStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'This is a computer generated Payslip. Signature is not required.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfRow(
    String label,
    String value, {
    pw.TextStyle? valueStyle,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                value,
                style: valueStyle ?? const pw.TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _downloading = true);
    try {
      final bytes = await _generatePayrollPdfBytes();
      final staffId = '${widget.payrollRecord['staffId'] ?? 'staff'}';
      final month = ('${widget.payrollRecord['month'] ?? 'month'}')
          .replaceAll(' ', '_')
          .replaceAll('/', '-');
      final fileName = 'payslip_${staffId}_$month.pdf';

      await savePdf(
        bytes: bytes,
        fileName: fileName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF ready for download/print')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate/download PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffName = widget.payrollRecord['staffName'] ?? '-';
    final staffId = widget.payrollRecord['staffId'] ?? '-';
    final month = widget.payrollRecord['month'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Payroll Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Staff Name', '$staffName'),
                  _buildInfoRow('Staff ID', '$staffId'),
                  _buildInfoRow('Payroll Month', '$month'),
                  const Divider(height: 28),
                  TextFormField(
                    controller: basicPayController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Basic Pay',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _validateNumber(v, 'Basic Pay'),
                    onChanged: (_) => _recalculateFromBasic(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bonusController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Bonus',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _validateNumber(v, 'Bonus'),
                    onChanged: (_) => _recalculateFromBasic(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: deductionController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Deduction',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _validateNumber(v, 'Deduction'),
                    onChanged: (_) => _recalculateFromBasic(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: grossPayController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Gross Pay (Auto)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: netSalaryController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Net Salary (Auto)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _publishing ? null : _publishPayroll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _publishing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.publish, color: Colors.white),
                      label: Text(
                        _publishing ? 'Publishing...' : 'Publish to Staff',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _downloading ? null : _downloadPdf,
                      icon: _downloading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label:
                          Text(_downloading ? 'Preparing PDF...' : 'Download PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}