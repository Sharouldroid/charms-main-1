import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:charms/internshipmodels/activity.dart';
import 'package:charms/internshipmodels/schedule.dart';
import 'package:charms/internshipservices/activity_service.dart';
import 'package:charms/internshipproviders/register_provider.dart';
import 'package:charms/internshipmodels/InternAttendanceRecord.dart';
import 'package:charms/internshipservices/InternAttendanceService.dart';
import 'package:charms/internshipservices/schedule_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonitorPerformancePage extends StatefulWidget {
  final String role;
  final int userId;
  final String? internName;
  final String? internId;
  final int? preselectedInternId;

  const MonitorPerformancePage({
    super.key,
    required this.role,
    required this.userId,
    this.internName,
    this.internId,
    this.preselectedInternId,
  });

  @override
  _MonitorPerformancePageState createState() => _MonitorPerformancePageState();
}

class _MonitorPerformancePageState extends State<MonitorPerformancePage> {
  List<Activity> _activities = [];
  List<dynamic> _milestones = [];
  bool _isLoading = false;
  bool _isGeneratingReport = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ActivityService _activityService = ActivityService();
  final InternAttendanceService _attendanceService = InternAttendanceService();

  List<dynamic> _interns = [];
  int? _selectedInternId;
  String _selectedInternName = '';
  String _internDisplayName = '';
  String _internTeam = '';
  Uint8List? _cachedUmtLogo;
  Uint8List? _cachedSecondLogo;
  Uint8List? _cachedSigBytes;

  InternAttendanceRecord? _todayAttendance;
  List<InternAttendanceRecord> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.role == 'Admin') {
      _loadInterns();
    } else {
      _loadAll();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    // Fetch intern's own name and team for the report header
    try {
      final details = await Provider.of<RegisterProvider>(context, listen: false)
          .getInternDetails(widget.userId);
      if (mounted) {
        setState(() {
          _internDisplayName = '${details.firstName} ${details.lastName}'.trim();
        });
      }
      await _loadInternTeam(details.scheduleId);
    } catch (_) {}

    await Future.wait([
      _loadActivities(),
      _loadMilestones(widget.userId),
      _loadAttendance(widget.userId),
    ]);
  }

  Future<void> _loadInternTeam(int? scheduleId) async {
    if (scheduleId == null) return;
    try {
      final schedules = await ScheduleService().fetchSchedules();
      Schedule? s;
      try {
        s = schedules.firstWhere((sc) => sc.id == scheduleId);
      } catch (_) {}
      if (mounted && s != null) {
        final teamName = s.description;
        setState(() => _internTeam = teamName);
        _preloadPdfAssets(teamName);
      }
    } catch (_) {}
  }

  Future<void> _preloadPdfAssets(String teamName) async {
    final isFaizah = _isFaizahTeam(teamName);
    try {
      final results = await Future.wait([
        rootBundle.load('assets/images/logo/logoumt.png'),
        rootBundle.load(isFaizah
            ? 'assets/logos/seatrulogo1.png'
            : 'assets/images/logo/cmslogo.png'),
        rootBundle.load(isFaizah
            ? 'assets/Signature Dr Faizah.jpeg'
            : 'assets/Signature Dr Uzair.png'),
      ]);
      _cachedUmtLogo = results[0].buffer.asUint8List();
      _cachedSecondLogo = results[1].buffer.asUint8List();
      _cachedSigBytes = results[2].buffer.asUint8List();
    } catch (_) {}
  }

  Future<void> _loadInterns() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<RegisterProvider>(context, listen: false);
    try {
      await provider.loadInterns();
      final allInterns = provider.internList;
      if (!mounted) return;
      setState(() {
        _interns = allInterns;
        _isLoading = false;
      });
      if (widget.preselectedInternId != null) {
        _onInternSelected(widget.preselectedInternId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Failed to load interns: $e');
    }
  }

  Future<void> _loadActivities() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      List<Activity> activities;
      if (widget.role == 'Admin' && _selectedInternId != null) {
        activities =
            await _activityService.getActivitiesByIntern(_selectedInternId!);
      } else if (widget.role == 'Intern') {
        activities =
            await _activityService.getActivitiesByIntern(widget.userId);
      } else {
        activities = [];
      }
      if (!mounted) return;
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!e.toString().contains('Not Found')) {
        _showError('Failed to load activities: $e');
      }
    }
  }

  Future<void> _loadMilestones(int userId) async {
    try {
      final m = await _activityService.getMilestones(userId);
      if (mounted) setState(() => _milestones = m);
    } catch (_) {}
  }

  Future<void> _loadAttendance(int userId) async {
    try {
      final history = await _attendanceService.fetchHistory(userId);
      final today = DateTime.now();
      final todayRecord = history.cast<InternAttendanceRecord?>().firstWhere(
        (r) {
          final d = r!.workDate ?? r.clockInTime;
          return d != null &&
              d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        },
        orElse: () => null,
      );
      if (!mounted) return;
      setState(() {
        _attendanceHistory = history;
        _todayAttendance = todayRecord;
      });
    } catch (_) {}
  }

  void _onInternSelected(int? internId) {
    if (internId == null) return;
    final idx = _interns.indexWhere(
        (intern) => (intern['user_id'] as num).toInt() == internId);
    if (idx == -1) return;
    final selected = _interns[idx];
    setState(() {
      _selectedInternId = internId;
      final first = selected['first_name'] ?? '';
      final last = selected['last_name'] ?? '';
      _selectedInternName = '$first $last'.trim();
      if (_selectedInternName.isEmpty) _selectedInternName = 'Unknown';
      _todayAttendance = null;
      _attendanceHistory = [];
      _milestones = [];
      _internTeam = '';
      _cachedUmtLogo = null;
      _cachedSecondLogo = null;
      _cachedSigBytes = null;
    });
    _loadActivities();
    _loadMilestones(internId);
    _loadAttendance(internId);
    final rawScheduleId = selected['schedule_id'];
    if (rawScheduleId != null) {
      _loadInternTeam((rawScheduleId as num).toInt());
    }
  }

  bool _isEditableToday(Activity activity) {
    final now = DateTime.now();
    final logged = activity.createdAt.toLocal();
    return logged.year == now.year &&
        logged.month == now.month &&
        logged.day == now.day;
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  void _showAddActivityDialog() {
    _titleController.clear();
    _descController.clear();
    _showActivityDialog(
      heading: 'Log Activity',
      onSubmit: _addActivity,
    );
  }

  void _showEditActivityDialog(Activity activity) {
    _titleController.text = activity.title ?? '';
    _descController.text = activity.activityDescription;
    _showActivityDialog(
      heading: 'Edit Activity',
      submitLabel: 'Update',
      submitColor: Colors.deepPurple,
      showMilestone: false,
      onSubmit: (_) => _editActivity(activity),
    );
  }

  void _showActivityDialog({
    required String heading,
    required Function(bool isMilestone) onSubmit,
    String submitLabel = 'Submit',
    Color submitColor = Colors.blueAccent,
    bool showMilestone = true,
  }) {
    bool isMilestone = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: submitColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          heading == 'Edit Activity'
                              ? Icons.edit
                              : Icons.edit_note,
                          color: submitColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(heading,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Title ──────────────────────────────────────────────
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g. Day 1 — Lab Orientation',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: submitColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Description ────────────────────────────────────────
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'What did you work on today?',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: submitColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),

                  // ── Milestone toggle ───────────────────────────────────
                  if (showMilestone) ...[
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color:
                            isMilestone ? Colors.amber[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMilestone
                              ? Colors.amber
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: SwitchListTile(
                        title: Row(
                          children: [
                            Icon(Icons.star,
                                color: isMilestone
                                    ? Colors.amber
                                    : Colors.grey,
                                size: 18),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text('Mark as Milestone',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                        subtitle: isMilestone
                            ? const Text('Saved as a key achievement',
                                style: TextStyle(fontSize: 12))
                            : null,
                        value: isMilestone,
                        activeThumbColor: Colors.amber,
                        dense: true,
                        onChanged: (val) =>
                            setDialogState(() => isMilestone = val),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Buttons ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_titleController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a title'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                            onSubmit(isMilestone);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: submitColor,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(submitLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── CRUD actions ─────────────────────────────────────────────────────────

  Future<void> _addActivity(bool isMilestone) async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _activityService.addActivity(
        widget.userId,
        desc.isEmpty ? title : desc,
        title: title,
      );
      if (isMilestone) {
        await _activityService.addMilestone(
            widget.userId, title, desc.isEmpty ? null : desc);
      }
      _titleController.clear();
      _descController.clear();
      await _loadActivities();
      if (isMilestone) await _loadMilestones(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              isMilestone ? 'Activity & milestone saved!' : 'Activity logged!'),
          backgroundColor: isMilestone ? Colors.amber[700] : Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Failed to log activity: $e');
    }
  }

  Future<void> _editActivity(Activity activity) async {
    if (activity.id == null) {
      _showError('Cannot edit this activity: missing ID');
      return;
    }
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _activityService.updateActivity(
        activity.id!,
        desc.isEmpty ? title : desc,
        title: title,
      );
      _titleController.clear();
      _descController.clear();
      await _loadActivities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Activity updated!'),
          backgroundColor: Colors.deepPurple,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Failed to update activity: $e');
    }
  }

  // ── Report ───────────────────────────────────────────────────────────────

  bool _isFaizahTeam(String team) =>
      team == 'Administration Team' || team == 'Digital Team';

  Future<void> _generateReport() async {
    setState(() => _isGeneratingReport = true);
    try {
      final name = widget.role == 'Admin'
          ? _selectedInternName
          : (_internDisplayName.isNotEmpty
              ? _internDisplayName
              : (widget.internName ?? 'Intern'));
      final dateNow = DateFormat('dd MMMM yyyy').format(DateTime.now());

      final totalMinutes = _attendanceHistory.fold<int>(
          0, (sum, r) => sum + (r.shiftDuration?.inMinutes ?? 0));
      final totalHours = totalMinutes ~/ 60;
      final remainMin = totalMinutes % 60;

      // Use pre-cached assets or load all three in parallel
      final isFaizah = _isFaizahTeam(_internTeam);
      final sigName = isFaizah ? 'Dr. Faizah' : 'Dr. Uzair';

      final Uint8List umtLogoBytes;
      final Uint8List secondLogoBytes;
      final Uint8List sigBytes;

      if (_cachedUmtLogo != null &&
          _cachedSecondLogo != null &&
          _cachedSigBytes != null) {
        umtLogoBytes = _cachedUmtLogo!;
        secondLogoBytes = _cachedSecondLogo!;
        sigBytes = _cachedSigBytes!;
      } else {
        final results = await Future.wait([
          rootBundle.load('assets/images/logo/logoumt.png'),
          rootBundle.load(isFaizah
              ? 'assets/logos/seatrulogo1.png'
              : 'assets/images/logo/cmslogo.png'),
          rootBundle.load(isFaizah
              ? 'assets/Signature Dr Faizah.jpeg'
              : 'assets/Signature Dr Uzair.png'),
        ]);
        umtLogoBytes = results[0].buffer.asUint8List();
        secondLogoBytes = results[1].buffer.asUint8List();
        sigBytes = results[2].buffer.asUint8List();
      }

      final umtLogo = pw.MemoryImage(umtLogoBytes);
      final secondLogo = pw.MemoryImage(secondLogoBytes);
      final sigImage = pw.MemoryImage(sigBytes);

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            // ── Logo row ─────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(umtLogo, height: 48),
                pw.Image(secondLogo, height: 48),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── Report header ────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Internship Performance Report',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Intern: $name',
                      style: pw.TextStyle(
                          color: PdfColor(1, 1, 1, 0.7), fontSize: 12)),
                  pw.Text('Generated: $dateNow',
                      style: pw.TextStyle(
                          color: PdfColor(1, 1, 1, 0.7), fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Attendance summary ───────────────────────────────────────
            pw.Text('Attendance Summary',
                style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                ['Total Days Attended', '${_attendanceHistory.length} days'],
                ['Total Hours', '${totalHours}h ${remainMin}m'],
              ],
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue600),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: pw.TableBorder.all(color: PdfColors.grey300),
            ),
            if (_attendanceHistory.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Date',
                  'Clock In',
                  'Clock Out',
                  'Duration',
                  'Location'
                ],
                data: _attendanceHistory
                    .map((r) => [
                          r.workDate != null
                              ? DateFormat('dd MMM yyyy').format(r.workDate!)
                              : '-',
                          r.clockInTime != null
                              ? DateFormat('hh:mm a')
                                  .format(r.clockInTime!.toLocal())
                              : '-',
                          r.clockOutTime != null
                              ? DateFormat('hh:mm a')
                                  .format(r.clockOutTime!.toLocal())
                              : '-',
                          r.shiftDurationFormatted,
                          r.clockInLocation ?? '-',
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 9),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blueAccent),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                border: pw.TableBorder.all(color: PdfColors.grey300),
              ),
            ],
            pw.SizedBox(height: 20),

            // ── Milestones ───────────────────────────────────────────────
            if (_milestones.isNotEmpty) ...[
              pw.Text('Milestones',
                  style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber700)),
              pw.SizedBox(height: 8),
              ..._milestones.map((m) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber50,
                      border: pw.Border.all(color: PdfColors.amber300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('★ ${m['title'] ?? ''}',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                        if ((m['notes'] ?? '').toString().isNotEmpty)
                          pw.Text(m['notes'].toString(),
                              style: const pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.grey700)),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 20),
            ],

            // ── Activities ───────────────────────────────────────────────
            pw.Text('Activity Log',
                style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700)),
            pw.SizedBox(height: 8),
            if (_activities.isEmpty)
              pw.Text('No activities recorded.',
                  style: const pw.TextStyle(color: PdfColors.grey))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Num', 'Date', 'Title', 'Description'],
                data: _activities
                    .asMap()
                    .entries
                    .map((e) => [
                          '${e.key + 1}',
                          DateFormat('dd MMM yyyy')
                              .format(e.value.createdAt.toLocal()),
                          e.value.title ?? '-',
                          e.value.activityDescription,
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 9),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue600),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                border: pw.TableBorder.all(color: PdfColors.grey300),
              ),

            // ── Supervisor Signature ─────────────────────────────────────
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Company Supervisor',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 6),
                    pw.Image(sigImage, height: 60),
                    pw.Container(
                      width: 160,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            top: pw.BorderSide(color: PdfColors.grey500)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(sigName,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'report_${name.replaceAll(' ', '_')}_$dateNow.pdf',
      );
    } catch (e) {
      _showError('Failed to generate report: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy').format(dt.toLocal());
  String _formatTime(DateTime dt) =>
      DateFormat('hh:mm a').format(dt.toLocal());

  InternAttendanceRecord? _getAttendanceForDate(DateTime date) {
    final local = date.toLocal();
    return _attendanceHistory.cast<InternAttendanceRecord?>().firstWhere(
      (r) {
        final d = r!.workDate ?? r.clockInTime?.toLocal();
        return d != null &&
            d.year == local.year &&
            d.month == local.month &&
            d.day == local.day;
      },
      orElse: () => null,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final showReportBtn =
        widget.role == 'Intern' || (widget.role == 'Admin' && _selectedInternId != null);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            widget.role == 'Admin' ? 'Monitor Performance' : 'My Activities'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (showReportBtn)
            _isGeneratingReport
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Download Report',
                    icon: const Icon(Icons.download_rounded),
                    onPressed: _generateReport,
                  ),
        ],
      ),
      body: Column(
        children: [
          // ── Gradient header ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent,
                  Color.fromARGB(255, 123, 64, 251),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: widget.role == 'Admin'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Intern to Monitor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          hint: const Text('Choose an intern'),
                          initialValue: _selectedInternId,
                          items: _interns.map((intern) {
                            final first = intern['first_name'] ?? '';
                            final last = intern['last_name'] ?? '';
                            final name = '$first $last'.trim();
                            return DropdownMenuItem<int>(
                              value: (intern['user_id'] as num).toInt(),
                              child: Text(name.isEmpty ? 'Unknown' : name),
                            );
                          }).toList(),
                          onChanged: _onInternSelected,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        radius: 24,
                        child: Icon(Icons.person,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Activity Log',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_activities.length} activit${_activities.length == 1 ? 'y' : 'ies'} logged',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          // ── Admin selected intern bar ───────────────────────────────────
          if (widget.role == 'Admin' && _selectedInternId != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.green[50],
              child: Row(
                children: [
                  Icon(Icons.person_pin,
                      color: Colors.green[700], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$_selectedInternName — ${_activities.length} activit${_activities.length == 1 ? 'y' : 'ies'}',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // ── Today's Attendance card ─────────────────────────────────────
          if (widget.role == 'Intern' ||
              (widget.role == 'Admin' && _selectedInternId != null))
            _buildAttendanceCard(),

          // ── Milestones horizontal row ───────────────────────────────────
          if (_milestones.isNotEmpty) _buildMilestonesRow(),

          // ── Activity list ───────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activities.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadActivities();
                          final uid = widget.role == 'Admin'
                              ? (_selectedInternId ?? widget.userId)
                              : widget.userId;
                          await Future.wait([
                            _loadMilestones(uid),
                            _loadAttendance(uid),
                          ]);
                        },
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _activities.length,
                          itemBuilder: (context, index) =>
                              _buildActivityTile(index),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.role == 'Intern'
          ? FloatingActionButton.extended(
              onPressed: _showAddActivityDialog,
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Log Activity'),
            )
          : null,
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildAttendanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.role == 'Admin'
                    ? "Today's Attendance"
                    : "Today's Attendance",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              if (_todayAttendance != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _todayAttendance!.hasClockOut
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _todayAttendance!.hasClockOut
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  child: Text(
                    _todayAttendance!.hasClockOut
                        ? 'Completed'
                        : 'In Progress',
                    style: TextStyle(
                      fontSize: 11,
                      color: _todayAttendance!.hasClockOut
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_todayAttendance == null)
            Text(
              'No attendance recorded today.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _attendanceStat(
                    Icons.login,
                    'Clock In',
                    _todayAttendance!.clockInTime != null
                        ? _formatTime(_todayAttendance!.clockInTime!)
                        : '-',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _attendanceStat(
                    Icons.logout,
                    'Clock Out',
                    _todayAttendance!.clockOutTime != null
                        ? _formatTime(_todayAttendance!.clockOutTime!)
                        : '-',
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _attendanceStat(
                    Icons.timer_outlined,
                    'Duration',
                    _todayAttendance!.shiftDurationFormatted,
                    Colors.blueAccent,
                  ),
                ),
              ],
            ),
            if (_todayAttendance!.clockInLocation != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _todayAttendance!.clockInLocation!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _attendanceStat(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildMilestonesRow() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 15),
                const SizedBox(width: 4),
                Text(
                  'Milestones (${_milestones.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _milestones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final m = _milestones[i];
                return Tooltip(
                  message: (m['notes'] ?? '').toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          m['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            widget.role == 'Admin'
                ? (_selectedInternId == null
                    ? 'Select an intern to view activities'
                    : 'No activities logged yet')
                : 'No activities logged yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (widget.role == 'Intern') ...[
            const SizedBox(height: 8),
            Text(
              'Tap + to log your first activity',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTile(int index) {
    final activity = _activities[index];
    final isFirst = index == 0;
    final canEdit = widget.role == 'Intern' && _isEditableToday(activity);
    final attendance = _getAttendanceForDate(activity.createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isFirst
                    ? Colors.blueAccent
                    : Colors.blueAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check,
                  color:
                      isFirst ? Colors.white : Colors.blueAccent,
                  size: 18),
            ),
            if (index < _activities.length - 1)
              Container(
                  width: 2,
                  height: 60,
                  color: Colors.blueAccent.withValues(alpha: 0.15)),
          ],
        ),
        const SizedBox(width: 12),

        // Activity card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activity.title != null &&
                              activity.title!.isNotEmpty)
                            Text(
                              activity.title!,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                          if (activity.activityDescription.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                  top: activity.title != null ? 4 : 0),
                              child: Text(
                                activity.activityDescription,
                                style: TextStyle(
                                  fontSize:
                                      activity.title != null ? 13 : 15,
                                  color: activity.title != null
                                      ? Colors.grey[700]
                                      : Colors.black87,
                                  fontWeight: activity.title != null
                                      ? FontWeight.normal
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (canEdit) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Edit activity',
                        child: InkWell(
                          onTap: () => _showEditActivityDialog(activity),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  Colors.deepPurple.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.edit_outlined,
                                size: 16, color: Colors.deepPurple),
                          ),
                        ),
                      ),
                    ] else if (widget.role == 'Intern') ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: "Can only edit today's activities",
                        child: Icon(Icons.lock_outline,
                            size: 14, color: Colors.grey[300]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(_formatDate(activity.createdAt),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(_formatTime(activity.createdAt),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                  ],
                ),

                // ── Clock In / Clock Out ──────────────────────────────
                if (attendance != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Clock In box
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.login,
                                      size: 13, color: Colors.blue[600]),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Clock In',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue[600])),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                attendance.clockInTime != null
                                    ? _formatTime(attendance.clockInTime!)
                                    : '-',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Clock Out box
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: attendance.hasClockOut
                                ? Colors.green[50]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.logout,
                                      size: 13,
                                      color: attendance.hasClockOut
                                          ? Colors.green[600]
                                          : Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Clock Out',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: attendance.hasClockOut
                                                ? Colors.green[600]
                                                : Colors.grey[500])),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                attendance.clockOutTime != null
                                    ? _formatTime(attendance.clockOutTime!)
                                    : 'Not yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: attendance.hasClockOut
                                      ? Colors.green[700]
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: attendance.hasClockOut
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        child: Text(
                          attendance.hasClockOut ? 'Done' : 'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: attendance.hasClockOut
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Duration + Location
                  if (attendance.hasClockOut) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Duration: ${attendance.shiftDurationFormatted}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                  if (attendance.clockInLocation != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            attendance.clockInLocation!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
