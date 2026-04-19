import 'dart:typed_data';
import 'package:charms/utils/pdf_download.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StaffPayrollDetailsScreen extends StatefulWidget {
  final String month;
  final int year;
  final String staffId;
  final String staffName;
  final String workingDays;
  final double basicPay;
  final double totalBonus;
  final double totalDeduction;
  final double totalSalary;

  const StaffPayrollDetailsScreen({
    super.key,
    required this.month,
    required this.year,
    required this.staffId,
    required this.staffName,
    required this.workingDays,
    required this.basicPay,
    required this.totalBonus,
    required this.totalDeduction,
    required this.totalSalary,
  });

  @override
  State<StaffPayrollDetailsScreen> createState() =>
      _StaffPayrollDetailsScreenState();
}

class _StaffPayrollDetailsScreenState extends State<StaffPayrollDetailsScreen> {
  bool _downloading = false;

  String _rm(num value) => 'RM ${value.toStringAsFixed(2)}';

  Future<Uint8List> _generatePayslipPdfBytes() async {
    final pdf = pw.Document();

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
                  'Payslip for ${widget.month} ${widget.year}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              _pdfRow('Staff ID', widget.staffId),
              _pdfRow('Name', widget.staffName),
              _pdfRow('Working Days', widget.workingDays),
              _pdfRow('Basic Pay', _rm(widget.basicPay)),
              _pdfRow('Total Bonus', _rm(widget.totalBonus)),
              _pdfRow('Total Deduction', _rm(widget.totalDeduction)),
              pw.Divider(),
              _pdfRow(
                'Total Salary',
                _rm(widget.totalSalary),
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
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
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

    setState(() => _downloading = true);
    try {
      final bytes = await _generatePayslipPdfBytes();
      final safeMonth = widget.month.replaceAll(' ', '_').replaceAll('/', '-');
      final fileName = 'payslip_${widget.staffId}_${safeMonth}_${widget.year}.pdf';

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
        SnackBar(content: Text('Failed to download PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 18)),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(value, style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Details', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              color: Colors.grey.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'SEATRU X CMS',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Payslip for ${widget.month} ${widget.year}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Divider(thickness: 1.2),
                    _detailRow('Staff ID', widget.staffId),
                    _detailRow('Name', widget.staffName),
                    _detailRow('Working Days', widget.workingDays),
                    _detailRow('Basic Pay', _rm(widget.basicPay)),
                    _detailRow('Total Bonus', _rm(widget.totalBonus)),
                    _detailRow('Total Deduction', _rm(widget.totalDeduction)),
                    const Divider(thickness: 1.2),
                    _detailRow('Total Salary', _rm(widget.totalSalary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'This is a computer Generated PaySlip. Signature is not required',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _downloading ? null : _downloadPdf,
            icon: _downloading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.white),
            label: Text(
              _downloading ? 'Preparing PDF...' : 'Download PDF',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ),
      ),
    );
  }
}