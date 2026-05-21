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

  // Modern Color Palette Constants
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

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
          backgroundColor: Colors.teal,
        ),
      );

      Navigator.pop(context, updatedRecord);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish payroll: $e'), backgroundColor: Colors.redAccent),
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
                  'Payment Report for $month',
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
                  'This is a computer generated Payment Report. Signature is not required.',
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
      final fileName = 'payment_report_${staffId}_$month.pdf';

      await savePdf(
        bytes: bytes,
        fileName: fileName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF ready for download/print'), backgroundColor: Colors.teal),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate/download PDF: $e'), backgroundColor: Colors.redAccent),
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
      backgroundColor: bgColor, // Modern Background
      appBar: AppBar(
        elevation: 0,
        title: const Text('PAYROLL DETAILS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              // Header Info Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.receipt_long_rounded, size: 32, color: primaryBlue),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        staffName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Staff ID: $staffId',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 18, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Text(
                            'Period: $month',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  'Earnings & Deductions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),

              // Inputs Group
              _buildTextField('Basic Pay', basicPayController, Icons.attach_money_rounded, isReadOnly: false),
              const SizedBox(height: 12),
              
              _buildTextField('Bonus', bonusController, Icons.add_circle_outline_rounded, isAddition: true),
              const SizedBox(height: 12),
              
              _buildTextField('Deduction', deductionController, Icons.remove_circle_outline_rounded, isDeduction: true),
              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  'Calculated Totals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),

              _buildTextField('Gross Pay (Auto)', grossPayController, Icons.account_balance_wallet_rounded, isReadOnly: true),
              const SizedBox(height: 12),
              
              _buildTextField('Net Salary (Auto)', netSalaryController, Icons.account_balance_rounded, isReadOnly: true, isHighlight: true),
              
              const SizedBox(height: 32),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: _publishing ? null : _publishPayroll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Modern green
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _publishing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.publish_rounded),
                label: Text(
                  _publishing ? 'Publishing...' : 'Publish to Staff',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              
              OutlinedButton.icon(
                onPressed: _downloading ? null : _downloadPdf,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: BorderSide(color: primaryBlue, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _downloading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _downloading ? 'Preparing PDF...' : 'Download PDF',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Modernized helper function to create text fields
  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    IconData icon,
    {bool isReadOnly = false, bool isAddition = false, bool isDeduction = false, bool isHighlight = false}
  ) {
    
    // Determine icon and text color based on field type
    Color iconColor = primaryBlue.withOpacity(0.7);
    if (isAddition) iconColor = Colors.teal;
    if (isDeduction) iconColor = Colors.redAccent;
    if (isReadOnly) iconColor = Colors.grey.shade500;
    if (isHighlight) iconColor = Colors.teal;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      readOnly: isReadOnly,
      style: TextStyle(
        fontSize: 16,
        fontWeight: isReadOnly ? FontWeight.bold : FontWeight.normal,
        color: isHighlight ? Colors.teal : (isReadOnly ? primaryBlue : const Color(0xFF1E293B)),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600, 
          fontSize: 14,
          fontWeight: isReadOnly ? FontWeight.bold : FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: iconColor, size: 22),
        filled: true,
        fillColor: isHighlight 
          ? Colors.teal.withOpacity(0.05) 
          : (isReadOnly ? primaryBlue.withOpacity(0.05) : Colors.white),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isReadOnly ? primaryBlue.withOpacity(0.3) : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      validator: (v) => _validateNumber(v, label),
      onChanged: (_) => _recalculateFromBasic(),
    );
  }
}