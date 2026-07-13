import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:charms/main.dart';
import 'package:charms/utils/pdf_download.dart';

// Offer letter assets — extracted from the official (genuinely blank, no
// leaked data) SEATRU offer letter Word template.
const _kLetterheadImg = 'assets/offer_letter/letterhead_banner.png';
const _kFooterImg     = 'assets/offer_letter/footer_banner.jpeg';
const _kSignatureImg  = 'assets/offer_letter/signature.png';
const _kPhoneIconImg  = 'assets/offer_letter/icon_phone.png';
const _kEmailIconImg  = 'assets/offer_letter/icon_email.png';

class OfferLetterScreen extends StatefulWidget {
  /// The intern's user_id. For Admin/Supervisor, pass the intern's user_id.
  final int userId;

  /// 'Intern' can download; 'Admin' or 'Supervisor' can only view.
  final String role;

  const OfferLetterScreen({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<OfferLetterScreen> createState() => _OfferLetterScreenState();
}

class _OfferLetterScreenState extends State<OfferLetterScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _reg;
  Map<String, dynamic>? _sched;
  Uint8List? _pdfBytes;

  static const _months = [
    '',
    'JANUARI',
    'FEBRUARI',
    'MAC',
    'APRIL',
    'MEI',
    'JUN',
    'JULAI',
    'OGOS',
    'SEPTEMBER',
    'OKTOBER',
    'NOVEMBER',
    'DISEMBER',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Title-case Malay months (for Tempoh row, e.g. "28 Mac 2026")
  static const _monthsTitle = [
    '', 'Januari', 'Februari', 'Mac', 'April', 'Mei', 'Jun',
    'Julai', 'Ogos', 'September', 'Oktober', 'November', 'Disember',
  ];

  // ALL-CAPS date (used for header Tarikh, e.g. "10 FEBRUARI 2026")
  String _toMalayDate(DateTime d) => '${d.day} ${_months[d.month]} ${d.year}';

  // Title-case date (used for Tempoh, e.g. "28 Mac 2026")
  String _toMalayDateTitle(DateTime d) =>
      '${d.day} ${_monthsTitle[d.month]} ${d.year}';

  bool get _isIntern => widget.role == 'Intern';

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _load() async {
    const timeout = Duration(seconds: 20);

    try {
      // 1. Fetch registration record(s) for this user
      final regResp = await http
          .get(Uri.parse(
              '${AppConfig.hostname}/api/internship/registers/by-user/${widget.userId}'))
          .timeout(timeout);

      if (regResp.statusCode != 200) {
        _setError('No registration record found.\nPlease register for a schedule first.');
        return;
      }

      final body = jsonDecode(regResp.body);
      List raw = [];
      if (body is Map && body['data'] != null) {
        final d = body['data'];
        if (d is List) {
          raw = d;
        } else if (d is Map) {
          raw = [d];
        }
      } else if (body is List) {
        raw = body;
      } else if (body is Map && body['id'] != null) {
        raw = [body];
      }

      if (raw.isEmpty) {
        _setError(
            'No registration record found.\nPlease register for a schedule first.');
        return;
      }

      final latestReg = raw.last as Map<String, dynamic>;

      // 2. Ensure we have full name — fallback to /registers/{id} if missing
      if (latestReg['first_name'] == null) {
        final regId = latestReg['id'];
        if (regId != null) {
          try {
            final fullResp = await http
                .get(Uri.parse(
                    '${AppConfig.hostname}/api/internship/registers/$regId'))
                .timeout(timeout);
            if (fullResp.statusCode == 200) {
              final fullBody = jsonDecode(fullResp.body);
              _reg = (fullBody is Map ? fullBody : latestReg)
                  as Map<String, dynamic>;
              _reg!['schedule_id'] ??= latestReg['schedule_id'];
            } else {
              _reg = latestReg;
            }
          } catch (_) {
            _reg = latestReg;
          }
        } else {
          _reg = latestReg;
        }
      } else {
        _reg = latestReg;
      }

      // 3. For Intern role: check that at least one document is approved
      if (_isIntern) {
        try {
          final docResp = await http
              .get(Uri.parse(
                  '${AppConfig.hostname}/api/internship/documents/submissions/${widget.userId}'))
              .timeout(timeout);
          if (docResp.statusCode == 200) {
            final docs = jsonDecode(docResp.body);
            final list = docs is List ? docs : <dynamic>[];
            final hasApproved = list.any((d) =>
                d['status']?.toString().toLowerCase() == 'approved');
            if (!hasApproved) {
              _setError(
                  'Your offer letter is not available yet.\n\nPlease wait until your documents have been verified (approved) by the Admin or Supervisor.');
              return;
            }
          }
        } catch (_) {
          // If check fails, allow through — avoids blocking on network error
        }
      }

      // 4. Fetch schedule
      final sid = _reg!['schedule_id'];
      if (sid != null) {
        try {
          final schResp = await http
              .get(Uri.parse('${AppConfig.hostname}/api/internship/schedules'))
              .timeout(timeout);
          if (schResp.statusCode == 200) {
            final list = jsonDecode(schResp.body);
            if (list is List) {
              final matches = list.where((s) => s['id'] == sid).toList();
              if (matches.isNotEmpty) {
                _sched = matches.first as Map<String, dynamic>;
              }
            }
          }
        } catch (_) {
          // Schedule fetch failed — letter will still generate without dates
        }
      }

      // 5. Generate PDF
      try {
        _pdfBytes = await _buildPdf();
      } catch (e) {
        _setError('Ralat jana surat tawaran: $e');
        return;
      }

      if (mounted) setState(() => _isLoading = false);
    } on TimeoutException {
      _setError(
          'Request timed out. Please check your internet connection and try again.');
    } catch (e) {
      _setError('Ralat: $e');
    }
  }

  void _setError(String msg) {
    if (mounted) setState(() { _error = msg; _isLoading = false; });
  }

  // ── PDF generation ─────────────────────────────────────────────────────────
  // Built natively — real flowing text and images, not a rasterized
  // background image with pixel-positioned text on top. The old
  // rasterize-and-overlay approach was fragile: different platforms' PDF
  // rasterizers didn't render the old template's covering boxes identically,
  // so leaked hidden text from a previously-filled copy could bleed through
  // on some platforms (seen on Android) but not others (not seen on web).
  // Generating the letter ourselves avoids that failure mode entirely —
  // there's no rasterization step and no old data that could possibly leak;
  // every word on the page is either static text we wrote or a value we
  // filled in, so it renders identically everywhere.

  static const _kBodyFontSize = 10.5;
  static const _kLabelWidth = 92.0;
  static const _kContentWidth = 515.0; // A4 (595.28) minus 40pt side margins

  pw.TextStyle get _bodyStyle => const pw.TextStyle(fontSize: _kBodyFontSize);
  pw.TextStyle get _boldStyle => pw.TextStyle(
      fontSize: _kBodyFontSize, fontWeight: pw.FontWeight.bold);
  pw.TextStyle get _boldItalicStyle => pw.TextStyle(
      fontSize: _kBodyFontSize,
      fontWeight: pw.FontWeight.bold,
      fontStyle: pw.FontStyle.italic);

  Future<Uint8List> _buildPdf() async {
    final letterheadImage =
        pw.MemoryImage((await rootBundle.load(_kLetterheadImg)).buffer.asUint8List());
    final footerImage =
        pw.MemoryImage((await rootBundle.load(_kFooterImg)).buffer.asUint8List());
    final signatureImage =
        pw.MemoryImage((await rootBundle.load(_kSignatureImg)).buffer.asUint8List());
    final phoneIcon =
        pw.MemoryImage((await rootBundle.load(_kPhoneIconImg)).buffer.asUint8List());
    final emailIcon =
        pw.MemoryImage((await rootBundle.load(_kEmailIconImg)).buffer.asUint8List());

    // Prepare field values
    final reg       = _reg!;
    final firstName = (reg['first_name'] ?? '').toString().trim();
    final lastName  = (reg['last_name']  ?? '').toString().trim();
    final fullName  = '$firstName $lastName'.trim().toUpperCase();
    final today     = _toMalayDate(DateTime.now());
    final regId     = reg['id'];
    final rujukan   = regId != null
        ? 'SEATRU/2026/LI/${regId.toString().padLeft(2, '0')}'
        : 'SEATRU/2026/LI';
    final icNumber  = (reg['ic_number'] ??
            reg['nric'] ??
            reg['no_ic'] ??
            reg['identification_number'] ??
            '')
        .toString()
        .trim();

    String startDate = '-', endDate = '-';
    if (_sched != null) {
      final s = DateTime.tryParse(_sched!['start_date']?.toString() ?? '');
      final e = DateTime.tryParse(_sched!['end_date']?.toString() ?? '');
      if (s != null) {
        startDate = _toMalayDateTitle(s);
      }
      if (e != null) endDate = _toMalayDateTitle(e);
    }

    final tempoh = (startDate != '-' && endDate != '-')
        ? '$startDate Hingga $endDate'
        : '-';

    // Allowance amount — admin-adjustable per schedule (falls back to the
    // long-standing default of RM 550/bulan if the backend hasn't set one).
    final allowanceRaw = _sched?['allowance'] ?? reg['allowance'];
    final allowanceAmount = allowanceRaw != null
        ? num.tryParse(allowanceRaw.toString())
        : null;
    final elaunAmount =
        allowanceAmount != null ? allowanceAmount.toStringAsFixed(0) : '550';

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(left: 40, right: 40, top: 24, bottom: 24),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          // Aspect ratio 1727x291 from the source letterhead image.
          child: pw.Image(letterheadImage, width: _kContentWidth, height: 86.8),
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          // Aspect ratio 1637x124 from the source footer image.
          child: pw.Image(footerImage, width: _kContentWidth, height: 39.0),
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 260,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _labelValueRow('Rujukan Kami', rujukan),
                    _labelValueRow('Tarikh', today),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Assalamualaikum dan Salam Sejahtera.', style: _bodyStyle),
          pw.SizedBox(height: 10),
          pw.Text(
            'PENEMPATAN LATIHAN INDUSTRI DI UNIT PENYELIDIKAN PENYU LAUT '
            '(SEATRU), UNIVERSITI MALAYSIA TERENGGANU',
            style: _boldStyle,
          ),
          pw.SizedBox(height: 10),
          pw.RichText(
            text: pw.TextSpan(style: _bodyStyle, children: [
              const pw.TextSpan(
                  text: '2.   Sukacita dimaklumkan bahawa Sea '
                      'Turtle Research Unit ('),
              pw.TextSpan(text: 'SEATRU', style: _boldStyle),
              const pw.TextSpan(text: ') bersetuju menerima '),
              pw.TextSpan(
                  text: fullName.isNotEmpty ? fullName : '-',
                  style: _boldStyle),
              if (icNumber.isNotEmpty) ...[
                const pw.TextSpan(text: ' ('),
                pw.TextSpan(text: icNumber, style: _boldStyle),
                const pw.TextSpan(text: ')'),
              ],
              const pw.TextSpan(
                  text: ' untuk menjalani latihan industri bersama kami '
                      'mengenai konservasi dan penyelidikan penyu di Stesen '
                      'Penyelidikan Alami Penyu Chagar Hutang, Pulau Redang, '
                      'Terengganu. Perincian latihan industri adalah seperti '
                      'berikut:'),
            ]),
          ),
          pw.SizedBox(height: 10),
          _labelBulletsRow('Lokasi', [
            _richBullet('Pejabat Sea Turtle Research Unit (', 'SEATRU', ')'),
            pw.Text(
                'Santuari Penyu Chagar Hutang, Pulau Redang, Terengganu',
                style: _bodyStyle),
          ]),
          pw.SizedBox(height: 8),
          _labelValueRow('Tempoh', tempoh),
          pw.SizedBox(height: 8),
          _labelBulletsRow('Skop latihan', [
            pw.Text('Membantu dalam membina aplikasi mobile', style: _bodyStyle),
            pw.Text(
                'Menjalankan aktiviti penyelidikan penyu bersama penyelidik SEATRU',
                style: _bodyStyle),
            pw.Text('Membantu melaksanakan aktiviti konservasi penyu',
                style: _bodyStyle),
          ]),
          pw.SizedBox(height: 8),
          _labelBulletsRow('Kemudahan', [
            pw.Text('Elaun (RM $elaunAmount/bulan)', style: _bodyStyle),
          ]),
          pw.SizedBox(height: 10),
          pw.RichText(
            text: pw.TextSpan(style: _bodyStyle, children: [
              const pw.TextSpan(
                  text: '3.   Sehubungan itu, anda diminta '
                      'untuk menghadirkan diri ke '),
              pw.TextSpan(text: 'Pejabat SEATRU', style: _boldStyle),
              const pw.TextSpan(
                  text: ' bagi urusan lapor diri dan taklimat. Sebarang '
                      'pertanyaan boleh dilakukan dengan menghubungi Adriana '
                      'Dania Hemizan (+60 19-3397 104) atau Mustaqim Rosdan '
                      '(+60 11-3166 0266).'),
            ]),
          ),
          pw.SizedBox(height: 10),
          pw.Text('"MALAYSIA MADANI"', style: _boldItalicStyle),
          pw.Text('"BERKHIDMAT UNTUK NEGARA"', style: _boldItalicStyle),
          pw.SizedBox(height: 10),
          pw.Text('Yang benar,', style: _bodyStyle),
          pw.SizedBox(height: 4),
          pw.Image(signatureImage, height: 45, width: 76.7),
          pw.SizedBox(height: 2),
          pw.Text('MOHD UZAIR RUSLI, PhD', style: _boldStyle),
          pw.Text('Ketua Makmal Penyelidikan Luar', style: _bodyStyle),
          pw.Text('Unit Penyelidikan Penyu (SEATRU)', style: _bodyStyle),
          pw.Text('Institut Oseanografi dan Sekitaran', style: _bodyStyle),
          pw.Text('Universiti Malaysia Terengganu', style: _bodyStyle),
          pw.SizedBox(height: 4),
          pw.Row(children: [
            pw.Image(phoneIcon, width: 10, height: 10),
            pw.SizedBox(width: 5),
            pw.Text('09-6683846', style: _bodyStyle),
          ]),
          pw.SizedBox(height: 2),
          pw.Row(children: [
            pw.Image(emailIcon, width: 11, height: 9),
            pw.SizedBox(width: 5),
            pw.Text('uzair@umt.edu.my', style: _bodyStyle),
          ]),
          pw.SizedBox(height: 2),
          pw.Text('s.k   Fail', style: _bodyStyle),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _labelValueRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
                width: _kLabelWidth, child: pw.Text(label, style: _bodyStyle)),
            pw.Text(':  ', style: _bodyStyle),
            pw.Expanded(child: pw.Text(value, style: _bodyStyle)),
          ],
        ),
      );

  pw.Widget _labelBulletsRow(String label, List<pw.Widget> bullets) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
              width: _kLabelWidth, child: pw.Text(label, style: _bodyStyle)),
          pw.Text(':  ', style: _bodyStyle),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: bullets
                  .map((w) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: w,
                      ))
                  .toList(),
            ),
          ),
        ],
      );

  pw.Widget _richBullet(String pre, String bold, String post) => pw.RichText(
        text: pw.TextSpan(style: _bodyStyle, children: [
          pw.TextSpan(text: pre),
          pw.TextSpan(text: bold, style: _boldStyle),
          pw.TextSpan(text: post),
        ]),
      );

  // ── Download ───────────────────────────────────────────────────────────────

  Future<void> _download() async {
    if (_pdfBytes == null) return;
    final name =
        (_reg?['first_name'] ?? 'intern').toString().replaceAll(' ', '_');
    await savePdf(bytes: _pdfBytes!, fileName: 'OfferLetter_$name.pdf');
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer Letter'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          if (_isIntern && _pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download Offer Letter',
              onPressed: _download,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : PdfPreview(
                  build: (_) async => _pdfBytes!,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}