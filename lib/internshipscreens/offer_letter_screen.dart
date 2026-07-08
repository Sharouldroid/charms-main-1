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

  // ── Field positions ─────────────────────────────────────────────────────
  // Measured DIRECTLY from the official example PDF's text layer (pymupdf).
  // These are top-of-box Y values (y0), exactly what the pdf package's
  // Positioned.top expects — NO baseline conversion needed.
  static const _kDebug = false;

  // Right header block — value text column starts at x0≈403.3
  static const _kHeaderValueX = 403.3;
  static const _kRujukanY     = 114.3;  // "SEATRU/2026/LI/.." top-of-box
  static const _kTarikhY      = 127.6;  // "10 FEBRUARI 2026"  top-of-box

  // Paragraph 2 — bold name starts right after "menerima" at x0≈126.1
  static const _kNameX        = 126.1;
  static const _kNameLineY    = 231.3;  // name + IC line, top-of-box

  // IC number — centered INSIDE the template's printed ( ) placeholder.
  // Official text layer: "(" left edge ≈386.8, ")" right edge ≈490.5.
  // We place a fixed-width box spanning the inside of the parens and
  // center the IC within it, so it's always centered regardless of length.
  static const _kIcParenLeft  = 388.0;  // just inside "("
  static const _kIcParenRight = 489.0;  // just inside ")"
  static const _kIcY          = 231.3;  // same line as the name

  // Details table — "Tempoh :" value column starts at x0≈188.8
  static const _kTableValueX  = 188.8;
  static const _kTempohY      = 337.5;  // "28 Mac 2026 ..." top-of-box

  // "Kemudahan : diberikan ● Elaun" bullet — V2 template leaves the amount
  // blank. Value starts right after "● " at x0≈206.8 (same column as the
  // Skop latihan bullets). A white box first covers that span in case any
  // leftover "(RM .../bulan)" text remains underneath in the template.
  static const _kElaunX       = 206.8;
  static const _kElaunY       = 430.4;  // "Elaun" top-of-box
  static const _kElaunMaskX   = 204.0;
  static const _kElaunMaskW   = 250.0;
  static const _kElaunMaskH   = 16.0;

  // Default body font size for overlays (matches template body text)
  static const _kFontSize     = 11.0;

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

  Future<Uint8List> _buildPdf() async {
    // Raster template page 1 → PNG background
    final templateData = await rootBundle.load(
      'assets/Surat_Tawaran_Latihan_Industri_SEATRU_2026_V2Templatepdf.pdf',
    );
    final templateBytes = templateData.buffer.asUint8List();

    Uint8List? bgPng;
    await for (final raster in Printing.raster(templateBytes, pages: [0], dpi: 150)) {
      bgPng = await raster.toPng();
      break;
    }

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
            '-')
        .toString()
        .trim();

    // Name WITHOUT brackets — the IC goes into the template's own ( ).
    final nameOnly = fullName;

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
    final elaunText = 'Elaun (RM '
        '${allowanceAmount != null ? allowanceAmount.toStringAsFixed(0) : '550'}'
        '/bulan)';

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Stack(
          children: [
            // Template as full-page background
            if (bgPng != null)
              pw.Positioned.fill(
                child: pw.Image(pw.MemoryImage(bgPng), fit: pw.BoxFit.fill),
              ),

            // Debug grid: 50-pt lines with coordinate labels.
            // Set _kDebug = false once field positions are calibrated.
            if (_kDebug) ..._debugGrid(),

            // ── Text overlays (match official layout — image 2) ────────
            // Header (top-right): reference + date (top-of-box Y, measured).
            _field(rujukan, left: _kHeaderValueX, top: _kRujukanY),
            _field(today,   left: _kHeaderValueX, top: _kTarikhY),

            // Name (bold, no brackets) right after "menerima".
            _field(nameOnly,
                left: _kNameX, top: _kNameLineY, bold: true),

            // IC number CENTERED inside the template's printed ( ) placeholder.
            if (icNumber != '-' && icNumber.isNotEmpty)
              pw.Positioned(
                left: _kIcParenLeft,
                top: _kIcY,
                child: pw.SizedBox(
                  width: _kIcParenRight - _kIcParenLeft,
                  child: pw.Text(
                    icNumber,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: _kFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Tempoh date range
            _field(tempoh, left: _kTableValueX, top: _kTempohY),

            // Elaun (allowance) — mask any leftover template text, then
            // draw the admin-adjustable amount.
            pw.Positioned(
              left: _kElaunMaskX,
              top: _kElaunY - 2,
              child: pw.Container(
                width: _kElaunMaskW,
                height: _kElaunMaskH,
                color: PdfColors.white,
              ),
            ),
            _field(elaunText, left: _kElaunX, top: _kElaunY),

            // (No report date — official template has no placeholder in para 3)
          ],
        ),
      ),
    );

    return doc.save();
  }

  // Positioned single-line text overlay helper
  pw.Widget _field(
    String text, {
    required double left,
    required double top,
    double fontSize = _kFontSize,
    bool bold = false,
  }) =>
      pw.Positioned(
        left: left,
        top: top,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  // Semi-transparent 50-pt coordinate grid for calibrating field positions.
  // Each intersection is labelled "x,y" in grey so you can read exact coords.
  List<pw.Widget> _debugGrid() {
    const step = 50.0;
    const w = 595.28;
    const h = 841.89;
    final widgets = <pw.Widget>[];

    // Horizontal rules
    for (double y = 0; y <= h; y += step) {
      widgets.add(pw.Positioned(
        left: 0, top: y,
        child: pw.Container(
          width: w, height: 0.3,
          color: PdfColor.fromHex('#AAAAAA'),
        ),
      ));
    }
    // Vertical rules
    for (double x = 0; x <= w; x += step) {
      widgets.add(pw.Positioned(
        left: x, top: 0,
        child: pw.Container(
          width: 0.3, height: h,
          color: PdfColor.fromHex('#AAAAAA'),
        ),
      ));
    }
    // Coordinate labels at each intersection
    for (double y = 0; y <= h; y += step) {
      for (double x = 0; x <= w; x += step) {
        widgets.add(pw.Positioned(
          left: x + 1, top: y + 1,
          child: pw.Text(
            '${x.toInt()},${y.toInt()}',
            style: pw.TextStyle(
              fontSize: 5,
              color: PdfColor.fromHex('#CC0000'),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

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