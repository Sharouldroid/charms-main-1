import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/assessment_provider.dart';
import 'package:charms/internshipscreens/assesstment_screen.dart';
import 'package:charms/internshipmodels/register.dart';
import 'package:charms/internshipmodels/schedule.dart';
import 'package:charms/internshipservices/register_service.dart';
import 'package:charms/internshipservices/schedule_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charms/main.dart';

class AssessmentInternPage extends StatefulWidget {
  final int internId;
  final String? photoUrl;
  final bool canAssess;

  const AssessmentInternPage({
    super.key,
    required this.internId,
    this.photoUrl,
    this.canAssess = false,
  });

  @override
  _AssessmentInternPageState createState() => _AssessmentInternPageState();
}

class _AssessmentInternPageState extends State<AssessmentInternPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String? _resolvedPhotoUrl;
  Register? _internDetails;
  Schedule? _internSchedule;

  final Map<String, String> _criterionLabels = {
    'criterion_1': 'Communication Skills',
    'criterion_2': 'Problem Solving',
    'criterion_3': 'Teamwork',
    'criterion_4': 'Punctuality',
    'criterion_5': 'Adaptability',
  };

  final Map<String, IconData> _criterionIcons = {
    'criterion_1': Icons.chat_bubble_outline_rounded,
    'criterion_2': Icons.lightbulb_outline_rounded,
    'criterion_3': Icons.group_outlined,
    'criterion_4': Icons.access_time_rounded,
    'criterion_5': Icons.shuffle_rounded,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final futures = <Future>[
        Provider.of<AssessmentProvider>(context, listen: false)
            .loadAssessmentData(widget.internId),
        _loadPhoto(),
      ];
      if (widget.canAssess) {
        futures.add(_loadInternDetails());
      }
      await Future.wait(futures);
      _animController.forward();
    });
  }

  Future<void> _loadPhoto() async {
    if (widget.photoUrl != null) {
      setState(() => _resolvedPhotoUrl = widget.photoUrl);
      return;
    }
    try {
      final response = await http.get(Uri.parse(
        '${AppConfig.hostname}/api/internship/registers/${widget.internId}/with-photo',
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final filepath = data['filepath'];
        if (filepath != null && filepath.toString().isNotEmpty) {
          setState(() {
            _resolvedPhotoUrl =
                'https://devcms.com.my/charmsAPI/public/storage/$filepath';
          });
        }
      }
    } catch (e) {
      // fail silently
    }
  }

  Future<void> _loadInternDetails() async {
    try {
      final register =
          await RegisterService().getInternDetails(widget.internId);

      Schedule? schedule;
      try {
        final schedules = await ScheduleService().fetchSchedules();
        final idx = schedules.indexWhere((s) => s.id == register.scheduleId);
        if (idx != -1) schedule = schedules[idx];
      } catch (_) {
        // schedule lookup failed – leave null
      }

      if (mounted) {
        setState(() {
          _internDetails = register;
          _internSchedule = schedule;
        });
      }
    } catch (e) {
      // fail silently – PDF will show placeholders
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _barColor(int score) {
    if (score >= 4) return const Color(0xFF1D9E75);
    if (score == 3) return const Color(0xFFEF9F27);
    return const Color(0xFFD85A30);
  }

  Color _badgeBg(int score) {
    if (score >= 4) return const Color(0xFFE1F5EE);
    if (score == 3) return const Color(0xFFFAEEDA);
    return const Color(0xFFFAECE7);
  }

  Color _badgeText(int score) {
    if (score >= 4) return const Color(0xFF0F6E56);
    if (score == 3) return const Color(0xFF854F0B);
    return const Color(0xFF993C1D);
  }

  String _badgeLabel(int score) {
    if (score == 5) return 'Excellent';
    if (score == 4) return 'Good';
    if (score == 3) return 'Average';
    return 'Needs work';
  }

  double _calculateAverage(Map<String, int> ratings) {
    if (ratings.isEmpty) return 0.0;
    return ratings.values.reduce((a, b) => a + b) / ratings.length;
  }

  Widget _starRow(int score, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < score ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i < score ? const Color(0xFFEF9F27) : Colors.grey[300],
        ),
      ),
    );
  }

  // ── PDF helpers ───────────────────────────────────────────────────────────

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Text(
            ':  ',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  // ── Generate & share the assessment PDF ──────────────────────────────────

  Future<void> _downloadReport(
    Map<String, int> ratings,
    Map<String, String> customLabels,
  ) async {
    final df = DateFormat('dd MMMM yyyy');
    final avg = _calculateAverage(ratings);

    final internName = _internDetails != null
        ? '${_internDetails!.firstName} ${_internDetails!.lastName}'
        : 'Intern #${widget.internId}';
    final university = _internDetails?.institutionName ?? '-';
    final scheduleName = _internSchedule?.description ?? '-';
    final schedulePeriod = _internSchedule != null
        ? '${df.format(_internSchedule!.startDate)} to ${df.format(_internSchedule!.endDate)}'
        : '-';

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) => [
          // ── Header ─────────────────────────────────────────────────
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Intern Assessment Report',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated: ${df.format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey300,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Intern Information ──────────────────────────────────────
          pw.Text(
            'Intern Information',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(thickness: 1, color: PdfColors.blue100),
          pw.SizedBox(height: 4),
          _pdfRow('Name', internName),
          _pdfRow('University', university),

          pw.SizedBox(height: 16),

          // ── Schedule ────────────────────────────────────────────────
          pw.Text(
            'Schedule',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(thickness: 1, color: PdfColors.blue100),
          pw.SizedBox(height: 4),
          _pdfRow('Schedule Name', scheduleName),
          _pdfRow('Period', schedulePeriod),

          pw.SizedBox(height: 20),

          // ── Assessment Results ──────────────────────────────────────
          pw.Text(
            'Assessment Results',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(thickness: 1, color: PdfColors.blue100),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableCell('Criterion', isHeader: true),
                  _tableCell('Score', isHeader: true),
                  _tableCell('Rating', isHeader: true),
                ],
              ),
              ...ratings.keys.map((key) {
                final score = ratings[key]!;
                final label = _criterionLabels[key] ??
                    customLabels[key] ??
                    key.replaceAll('_', ' ');
                return pw.TableRow(
                  children: [
                    _tableCell(label),
                    _tableCell('$score / 5'),
                    _tableCell(_badgeLabel(score)),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── Overall Score ───────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.blue200, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Overall Score',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${avg.toStringAsFixed(1)} / 5.0  ·  ${_badgeLabel(avg.round())}',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'Assessment_${internName.replaceAll(' ', '_')}.pdf',
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AssessmentProvider>(context);
    final ratings = provider.ratings;
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;
    final avg = _calculateAverage(ratings);
    final hasData = ratings.isNotEmpty && errorMessage == null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Performance Overview'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.canAssess && hasData)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download Report',
              onPressed: () => _downloadReport(
                ratings,
                provider.customCriteriaLabels,
              ),
            ),
        ],
      ),

      // FAB: only shown to supervisor
      floatingActionButton: widget.canAssess
          ? FloatingActionButton.extended(
              onPressed: () {
                Provider.of<AssessmentProvider>(context, listen: false)
                    .resetRatings();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NextPage(internId: widget.internId),
                  ),
                ).then((_) {
                  _animController.reset();
                  Provider.of<AssessmentProvider>(context, listen: false)
                      .loadAssessmentData(widget.internId)
                      .then((_) => _animController.forward());
                });
              },
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.rate_review),
              label: Text(hasData ? 'Re-assess Intern' : 'Assess Intern'),
            )
          : null,

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  // ── Header card ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar + title row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blue[50],
                              backgroundImage: _resolvedPhotoUrl != null
                                  ? NetworkImage(_resolvedPhotoUrl!)
                                  : null,
                              child: _resolvedPhotoUrl == null
                                  ? Text(
                                      'A',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[700],
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Intern Assessment',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Internship performance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Divider(color: Colors.grey[100], height: 28),

                        // Score section: only show when data exists
                        if (hasData) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overall score',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        avg.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '/ 5.0',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                  _starRow(avg.round()),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _badgeBg(avg.round()),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  _badgeLabel(avg.round()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _badgeText(avg.round()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // No data yet
                          Row(
                            children: [
                              Icon(Icons.pending_outlined,
                                  color: Colors.grey[400], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Not yet assessed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          if (widget.canAssess) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Assess Intern" below to submit an evaluation.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Error banner (non-blocking) ──────────────────────────
                  if (errorMessage != null &&
                      errorMessage != 'No assessment data found')
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── "No assessment" info banner ──────────────────────────
                  if (errorMessage == 'No assessment data found')
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.canAssess
                                  ? 'No assessment submitted yet. Use the button below to assess this intern.'
                                  : 'No assessment data found.',
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Criterion cards (only when data exists) ──────────────
                  if (hasData)
                    ...ratings.keys.map((key) {
                      final score = ratings[key]!;
                      final label = _criterionLabels[key] ??
                          provider.customCriteriaLabels[key] ??
                          key.replaceAll('_', ' ').capitalize();
                      final icon =
                          _criterionIcons[key] ?? Icons.star_outline;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        Icon(icon,
                                            size: 18,
                                            color: Colors.grey[400]),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _starRow(score, size: 14),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _badgeBg(score),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                        child: Text(
                                          _badgeLabel(score),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: _badgeText(score),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Animated progress bar
                              AnimatedBuilder(
                                animation: _animController,
                                builder: (_, __) => ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value:
                                        (score / 5) * _animController.value,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[100],
                                    valueColor: AlwaysStoppedAnimation(
                                        _barColor(score)),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$score / 5',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 8),

                  // ── Reload button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        _animController.reset();
                        final p = Provider.of<AssessmentProvider>(
                            context,
                            listen: false);
                        await p.loadAssessmentData(widget.internId);
                        _animController.forward();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reload assessment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
