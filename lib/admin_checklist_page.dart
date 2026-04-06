import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminChecklistPage extends StatefulWidget {
  const AdminChecklistPage({super.key});

  @override
  State<AdminChecklistPage> createState() => _AdminChecklistPageState();
}

class _AdminChecklistPageState extends State<AdminChecklistPage> {
  DateTime selectedChecklistDate = DateTime.now();

  List<dynamic> checklist = [];
  bool isLoading = true;
  bool isSaving = false;

  // Schedule data for the selected month (from hardcoded list)
  Map<String, List<int>> schedule = {};

  // Custom dates selected by the user per facility (key = facility_key)
  Map<String, DateTime?> customDates = {};

  final Color primaryPink = const Color(0xFFF05179);
  final Color bgGrey = const Color(0xFFF5F7FA);
  final Color successGreen = const Color(0xFF4CAF50);
  final Color warningRed = const Color(0xFFE57373);
  final Color warningRedLight = const Color(0xFFFFEBEE);
  final Color warningOrange = const Color(0xFFFFA500);
  final Color warningOrangeLight = const Color(0xFFFFF0E0);

  // Hardcoded schedule dates (year, month, day, list of facilities)
  final List<HardcodedScheduleEntry> hardcodedSchedule = [
    // List B (kitchen, quarters, watersportarea, office, balaisafsurau, firstaid, backpacking, waterquality)
    HardcodedScheduleEntry(2026, 3, 25,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),

    HardcodedScheduleEntry(2026, 4, 8,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 4, 11, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 4, 15, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 4, 18, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 4, 22, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 4, 25, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 4, 29, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 5, 2,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 5, 6,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 5, 9,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 5, 13, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 5, 16, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 5, 20, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 5, 23, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 5, 27, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 5, 30, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 6, 3,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 6, 6,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 6, 10, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 6, 13, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 6, 17, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 6, 20, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 6, 24, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 6, 27, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 7, 1,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 7, 4,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 7, 8,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 7, 11, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 7, 15, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 7, 18, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 7, 22, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 7, 25, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 7, 29, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 8, 1,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 8, 5,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 8, 8,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 8, 12, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 8, 15, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 8, 19, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 8, 22, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 8, 26, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 8, 29, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 9, 2,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 9, 5,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 9, 9,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 9, 12, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 9, 16, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 9, 19, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 9, 23, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 9, 26, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 9, 30, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 10, 3,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 10, 7,  ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 10, 10, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 10, 14, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),
    HardcodedScheduleEntry(2026, 10, 17, ['kitchen', 'quarters', 'watersportarea', 'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality']),

    // List A (campsite, outdoorclassroom) – subset of dates
    HardcodedScheduleEntry(2026, 4, 11, ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 4, 22, ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 5, 2,  ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 5, 13, ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 5, 23, ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 6, 3,  ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 6, 17, ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 7, 4,  ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 7, 18, ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 7, 29, ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 9, 12, ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 9, 23, ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 10, 3,  ['campsite', 'outdoorclassroom']),
    HardcodedScheduleEntry(2026, 10, 17, ['campsite', 'outdoorclassroom']),
  ];

  // List of all facilities (always displayed)
  final List<String> allFacilities = const [
    'campsite', 'kitchen', 'quarters', 'outdoorclassroom', 'watersportarea',
    'office', 'balaisafsurau', 'firstaid', 'backpacking', 'waterquality'
  ];

  // Build default checklist entries (all facilities with default values)
  List<dynamic> _buildDefaultChecklist() {
    return allFacilities.map((facility) {
      return {
        'facility_key': facility,
        'is_completed': false,
        'issue_date': null,
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Initialize checklist with default values immediately
    checklist = _buildDefaultChecklist();
    _computeScheduleForCurrentMonth();
    fetchChecklist();
  }

  // Compute schedule map from hardcoded dates for the selected date's year and month
  void _computeScheduleForCurrentMonth() {
    final year = selectedChecklistDate.year;
    final month = selectedChecklistDate.month;
    final Map<String, List<int>> newSchedule = {};

    for (var entry in hardcodedSchedule) {
      if (entry.year == year && entry.month == month) {
        for (String facility in entry.facilities) {
          newSchedule.putIfAbsent(facility, () => []).add(entry.day);
        }
      }
    }

    // Ensure all facilities have a list (even if empty)
    for (var f in allFacilities) {
      newSchedule.putIfAbsent(f, () => []);
    }

    setState(() {
      schedule = newSchedule;
    });
  }

  // --------------------------------------------------------------------------
  // API Calls
  // --------------------------------------------------------------------------
  Future<void> fetchChecklist() async {
    setState(() => isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedChecklistDate);
    final url = "https://devcms.com.my/charmsAPI/api/maintenance/checklist?date=$dateStr";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> rawData = jsonDecode(response.body);

        // Build a map of existing reports by facility_key
        final Map<String, dynamic> existingReports = {};
        for (var item in rawData) {
          final key = item['facility_key'].toString();
          if (key != 'replacementitems') {
            existingReports[key] = item;
          }
        }

        // Merge existing reports into the default checklist
        final updatedChecklist = _buildDefaultChecklist(); // start fresh with defaults
        for (var i = 0; i < updatedChecklist.length; i++) {
          final facility = updatedChecklist[i]['facility_key'];
          if (existingReports.containsKey(facility)) {
            updatedChecklist[i]['is_completed'] = existingReports[facility]['is_completed'];
            updatedChecklist[i]['issue_date'] = existingReports[facility]['issue_date'];
          }
        }

        setState(() {
          checklist = updatedChecklist;
          isLoading = false;
          customDates.clear();
        });
        checkMissingReportsAndNotify();
      } else {
        // If API fails, we still have the default checklist; just stop loading
        setState(() => isLoading = false);
        // Optionally show a snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load reports, but default list is shown"), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching checklist: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> checkMissingReportsAndNotify() async {
    final DateTime now = DateTime.now();
    final DateTime todayDate = DateTime(now.year, now.month, now.day);
    // Only notify for past or today (not future)
    if (selectedChecklistDate.isAfter(todayDate)) return;

    final missing = <String>[];
    for (var item in checklist) {
      final facilityKey = item['facility_key'];
      final isCompleted = item['is_completed'] == true;
      final scheduledDays = schedule[facilityKey] ?? [];
      if (scheduledDays.contains(selectedChecklistDate.day) && !isCompleted) {
        missing.add(facilityKey);
      }
    }

    if (missing.isEmpty) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedChecklistDate);
    final url = "https://devcms.com.my/charmsAPI/api/maintenance/notify-missing";

    try {
      await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'date': dateStr,
          'missing_facilities': missing,
        }),
      );
      debugPrint("Notification sent for missing reports on $dateStr");
    } catch (e) {
      debugPrint("Failed to send missing reports notification: $e");
    }
  }

  Future<void> submitChecklist() async {
    setState(() => isSaving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedChecklistDate);
    const url = "https://devcms.com.my/charmsAPI/api/maintenance/checklist/save";

    try {
      List<Map<String, dynamic>> payload = checklist.map((item) {
        final facilityKey = item['facility_key'];
        final DateTime? custom = customDates[facilityKey];
        final String? issueDate = custom != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(custom)
            : item['issue_date'];

        return {
          'facility_key': facilityKey,
          'is_completed': item['is_completed'],
          'issue_date': issueDate,
        };
      }).toList();

      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          'date': dateStr,
          'items': payload,
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Verified & Saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Failed to save checklist");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  // --------------------------------------------------------------------------
  // UI Helpers
  // --------------------------------------------------------------------------
  String _formatFacilityName(String key) {
    switch (key.toLowerCase()) {
      case 'outdoorclassroom': return 'Outdoor Classroom';
      case 'watersportarea': return 'Watersport Area';
      case 'balaisafsurau': return 'Balai Saf / Surau';
      case 'firstaid': return 'First Aid';
      case 'backpacking': return 'Backpacking';
      case 'waterquality': return 'Water Quality';
      default: return key[0].toUpperCase() + key.substring(1);
    }
  }

  IconData _getFacilityIcon(String key) {
    switch (key.toLowerCase()) {
      case 'campsite': return Icons.holiday_village;
      case 'kitchen': return Icons.restaurant;
      case 'quarters': return Icons.bed;
      case 'outdoorclassroom': return Icons.park;
      case 'watersportarea': return Icons.pool;
      case 'office': return Icons.computer;
      case 'balaisafsurau': return Icons.mosque;
      case 'firstaid': return Icons.medical_services;
      case 'backpacking': return Icons.backpack;
      case 'waterquality': return Icons.water_drop;
      default: return Icons.build;
    }
  }

  bool _isScheduledForToday(String facilityKey) {
    final days = schedule[facilityKey] ?? [];
    return days.contains(selectedChecklistDate.day);
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime todayDate = DateTime(now.year, now.month, now.day);
    final bool isToday = selectedChecklistDate == todayDate;
    final bool isTomorrow = selectedChecklistDate == todayDate.add(const Duration(days: 1));
    final bool isPast = selectedChecklistDate.isBefore(todayDate);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text("Admin Verification", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryPink,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header Date Picker
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedChecklistDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2030),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: primaryPink)),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    selectedChecklistDate = picked;
                  });
                  _computeScheduleForCurrentMonth();
                  await fetchChecklist();
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("VERIFICATION DATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  Row(
                    children: [
                      Text(DateFormat('dd MMM yyyy').format(selectedChecklistDate), style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_month, size: 20, color: primaryPink),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryPink))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: checklist.length,
                    itemBuilder: (context, index) {
                      final item = checklist[index];
                      bool isChecked = item['is_completed'] == true;
                      final facilityKey = item['facility_key'];

                      final DateTime? customDate = customDates[facilityKey];
                      final bool hasCustomDate = customDate != null;
                      final String reportDateDisplay = hasCustomDate
                          ? DateFormat('dd MMM yyyy, h:mm a').format(customDate!)
                          : (item['issue_date'] != null
                              ? DateFormat('dd MMM yyyy, h:mm a').format(DateTime.parse(item['issue_date']))
                              : "No reports found");

                      bool isScheduled = _isScheduledForToday(facilityKey);

                      String statusMessage = "Pending";
                      Color statusColor = Colors.grey;
                      Color borderColor = Colors.transparent;
                      Color cardBgColor = Colors.white;
                      bool showDueBadge = false;

                      if (isScheduled) {
                        if (isPast) {
                          if (!isChecked) {
                            statusMessage = "MISSING: Report not submitted";
                            statusColor = warningRed;
                            borderColor = warningRed;
                            cardBgColor = warningRedLight;
                          } else {
                            statusMessage = "Verified (on time)";
                            statusColor = successGreen;
                            borderColor = successGreen.withOpacity(0.5);
                          }
                        } else if (isToday) {
                          if (!isChecked) {
                            statusMessage = "MISSING: Report not submitted today";
                            statusColor = warningRed;
                            borderColor = warningRed;
                            cardBgColor = warningRedLight;
                          } else {
                            statusMessage = "Verified (today)";
                            statusColor = successGreen;
                            borderColor = successGreen.withOpacity(0.5);
                          }
                        } else if (isTomorrow) {
                          if (!isChecked) {
                            statusMessage = "DUE TOMORROW: Please prepare report";
                            statusColor = warningOrange;
                            borderColor = warningOrange;
                            cardBgColor = warningOrangeLight;
                            showDueBadge = true;
                          } else {
                            statusMessage = "Verified (in advance)";
                            statusColor = successGreen;
                            borderColor = successGreen.withOpacity(0.5);
                          }
                        } else {
                          // future date beyond tomorrow
                          if (!isChecked) {
                            statusMessage = "Pending (future schedule)";
                            statusColor = Colors.grey;
                          } else {
                            statusMessage = "Verified (in advance)";
                            statusColor = successGreen;
                            borderColor = successGreen.withOpacity(0.5);
                          }
                        }
                      } else {
                        // not scheduled – keep as is
                        if (isChecked) {
                          statusMessage = "Verified (unscheduled)";
                          statusColor = successGreen;
                          borderColor = successGreen.withOpacity(0.5);
                        } else {
                          statusMessage = "No schedule";
                          statusColor = Colors.grey;
                        }
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: borderColor != Colors.transparent ? BorderSide(color: borderColor, width: 1.5) : BorderSide.none,
                        ),
                        color: cardBgColor,
                        child: Column(
                          children: [
                            CheckboxListTile(
                              activeColor: successGreen,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isChecked ? successGreen.withOpacity(0.1) : Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_getFacilityIcon(facilityKey), color: isChecked ? successGreen : Colors.grey),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatFacilityName(facilityKey),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  if (showDueBadge)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: warningOrange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "Due Tomorrow",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                statusMessage,
                                style: TextStyle(color: statusColor, fontSize: 12),
                              ),
                              value: isChecked,
                              onChanged: (val) {
                                setState(() {
                                  checklist[index]['is_completed'] = val;
                                });
                              },
                            ),
                            const Divider(height: 1, indent: 70),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(70, 12, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.history, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text("Last Reported: ", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      Expanded(
                                        child: Text(
                                          reportDateDisplay,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: (hasCustomDate || item['issue_date'] != null) ? Colors.black87 : Colors.grey[400],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_calendar, size: 18),
                                        onPressed: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: customDate ?? (item['issue_date'] != null ? DateTime.parse(item['issue_date']) : DateTime.now()),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                            builder: (ctx, child) => Theme(
                                              data: ThemeData.light().copyWith(
                                                colorScheme: ColorScheme.light(primary: primaryPink),
                                              ),
                                              child: child!,
                                            ),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              customDates[facilityKey] = picked;
                                            });
                                          }
                                        },
                                        tooltip: "Set custom date",
                                      ),
                                      if (hasCustomDate)
                                        IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              customDates.remove(facilityKey);
                                            });
                                          },
                                          tooltip: "Clear custom date",
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        hasCustomDate ? "Custom date set" : "Tap to set custom date",
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  if (isScheduled && (isPast || isToday || isTomorrow)) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isPast || isToday) && !isChecked
                                            ? warningRed.withOpacity(0.1)
                                            : (isTomorrow && !isChecked
                                                ? warningOrange.withOpacity(0.1)
                                                : successGreen.withOpacity(0.1)),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: (isPast || isToday) && !isChecked
                                              ? warningRed
                                              : (isTomorrow && !isChecked
                                                  ? warningOrange
                                                  : successGreen),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            (isPast || isToday) && !isChecked
                                                ? Icons.warning_amber_rounded
                                                : (isTomorrow && !isChecked
                                                    ? Icons.timer
                                                    : Icons.check_circle),
                                            size: 14,
                                            color: (isPast || isToday) && !isChecked
                                                ? warningRed
                                                : (isTomorrow && !isChecked
                                                    ? warningOrange
                                                    : successGreen),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            statusMessage,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: (isPast || isToday) && !isChecked
                                                  ? warningRed
                                                  : (isTomorrow && !isChecked
                                                      ? warningOrange
                                                      : successGreen),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : submitChecklist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SUBMIT VERIFICATION", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for hardcoded schedule entries
class HardcodedScheduleEntry {
  final int year;
  final int month;
  final int day;
  final List<String> facilities;

  HardcodedScheduleEntry(this.year, this.month, this.day, this.facilities);
}