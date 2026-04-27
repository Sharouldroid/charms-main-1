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

class _StaffPayrollDetailsScreenState
    extends State<StaffPayrollDetailsScreen> {
  bool _downloading = false;

  // ── Matches StaffDashboardScreen palette ─────────────────────────────────────
  static const Color staffPrimary = Color(0xFF4F46E5);
  static const Color staffBg = Color(0xFFF8FAFC);
  static const Color staffCardBorder = Color(0xFFE2E8F0);

  String _rm(num value) => 'RM ${value.toStringAsFixed(2)}';

  // ── PDF generation (unchanged) ───────────────────────────────────────────────
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
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Payslip for ${widget.month} ${widget.year}',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              _pdfRow('Staff ID', widget.staffId),
              _pdfRow('Name', widget.staffName),
              _pdfRow('Basic Pay', _rm(widget.basicPay)),
              _pdfRow('Total Bonus', _rm(widget.totalBonus)),
              _pdfRow('Total Deduction', _rm(widget.totalDeduction)),
              pw.Divider(),
              _pdfRow(
                'Total Salary',
                _rm(widget.totalSalary),
                valueStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 13),
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

  pw.Widget _pdfRow(String label, String value,
      {pw.TextStyle? valueStyle}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        children: [
          pw.Expanded(
              flex: 2,
              child: pw.Text(label,
                  style: const pw.TextStyle(fontSize: 12))),
          pw.Expanded(
            flex: 3,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(value,
                  style:
                      valueStyle ?? const pw.TextStyle(fontSize: 12)),
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
      final safeMonth =
          widget.month.replaceAll(' ', '_').replaceAll('/', '-');
      final fileName =
          'payslip_${widget.staffId}_${safeMonth}_${widget.year}.pdf';
      await savePdf(bytes: bytes, fileName: fileName);
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

  // ── Row for payslip detail lines ─────────────────────────────────────────────
  Widget _detailRow(String label, String value,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isTotal ? FontWeight.w800 : FontWeight.w500,
                color: isTotal
                    ? const Color(0xFF1E293B)
                    : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight:
                      isTotal ? FontWeight.w900 : FontWeight.w600,
                  color: isTotal ? staffPrimary : const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Small labeled info chip (Staff ID / Name row) ─────────────────────────────
  Widget _infoChip(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: staffPrimary.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: staffPrimary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: staffBg,
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'PAYROLL DETAILS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          backgroundColor: staffPrimary,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Indigo header banner ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 20, bottom: 48, left: 24, right: 24),
              decoration: const BoxDecoration(
                color: staffPrimary,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.month} ${widget.year}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payslip Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo.shade200,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Staff info chips
                  Row(
                    children: [
                      _infoChip(Icons.badge_rounded, 'Staff ID',
                          widget.staffId),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _infoChip(Icons.person_rounded, 'Name',
                            widget.staffName),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Payslip card (pulled up over banner) ────────────────────
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  children: [
                    // ── Earnings & Deductions card ─────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: staffCardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section label
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      staffPrimary.withOpacity(0.10),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 16,
                                    color: staffPrimary),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Breakdown',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _detailRow('Basic Pay',
                              _rm(widget.basicPay)),
                          _buildDivider(),
                          _detailRow('Total Bonus',
                              _rm(widget.totalBonus)),
                          _buildDivider(),
                          _detailRow('Total Deduction',
                              _rm(widget.totalDeduction)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Total salary highlight card ────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: staffPrimary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: staffPrimary.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Salary',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.indigo.shade200,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _rm(widget.totalSalary),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 28),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Disclaimer ─────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: staffCardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16,
                              color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is a computer generated payslip. Signature is not required.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Download button ──────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _downloading ? null : _downloadPdf,
            icon: _downloading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded,
                    color: Colors.white),
            label: Text(
              _downloading ? 'Preparing PDF...' : 'Download Payslip',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: staffPrimary,
              disabledBackgroundColor:
                  staffPrimary.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(
        color: staffCardBorder,
        height: 1,
        thickness: 1,
      );
}