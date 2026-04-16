import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/utils/responsive_helper.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  // Current Filters
  String historyMonth = 'May';
  String historyYear = '2025';
  bool loadingHistory = false;

  // Data Containers
  List<dynamic> allHistoryItems = [];
  Map<String, List<dynamic>> groupedHistory = {};

  final List<String> facilities = [
    'Campsite',
    'Kitchen',
    'Quarters',
    'Outdoor Classroom',
    'Water Sport Area',
    'Office',
    'BalaiSaf (Surau)',
  ];

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> years = [for (int y = 2025; y <= 2030; y++) y.toString()];

  int monthNameToNumber(String month) => months.indexOf(month) + 1;

  String flutterFacilityKey(String selected) {
    if (selected == "All Facilities") return "all";
    String f = selected
        .toLowerCase()
        .replaceAll(" ", "")
        .replaceAll("(", "")
        .replaceAll(")", "");
    return f;
  }

  String normalizeStatus(String? status) {
    if (status?.toLowerCase() == 'completed') {
      return 'completed';
    }
    return 'no_action'; // Interpreted as Pending
  }

  Future<void> fetchHistoryList() async {
    setState(() => loadingHistory = true);
    final monthNumber = monthNameToNumber(historyMonth);

    final url = Uri.parse(
      'https://devcms.com.my/charmsAPI/api/maintenance/history-list?facility=all&month=$monthNumber&year=$historyYear',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        List<dynamic> activeItems =
            data
                .where((e) {
                  return normalizeStatus(e['status']) != 'completed';
                })
                .map((e) {
                  e['facility_key'] = flutterFacilityKey(
                    e['facility'] ?? 'unknown',
                  );
                  return e;
                })
                .toList();

        setState(() {
          allHistoryItems = activeItems;
          _groupItemsByFacility();
        });
      } else {
        _showSnack("❌ Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      _showSnack("❌ Connection Error: $e");
    }
    setState(() => loadingHistory = false);
  }

  void _groupItemsByFacility() {
    groupedHistory.clear();
    for (var f in facilities) {
      groupedHistory[flutterFacilityKey(f)] = [];
    }
    for (var item in allHistoryItems) {
      String key = item['facility_key'];
      if (groupedHistory.containsKey(key)) {
        groupedHistory[key]!.add(item);
      }
    }
  }

  Future<void> markAsDone(int id, String facilityKey) async {
    setState(() {
      allHistoryItems.removeWhere((item) => item['id'] == id);
      _groupItemsByFacility();
    });

    final url = Uri.parse(
      'https://devcms.com.my/charmsAPI/api/maintenance/update-status',
    );
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'status': 'completed'}),
      );

      if (response.statusCode == 200) {
        _showSnack("✅ Issue resolved!");
      } else {
        _showSnack("❌ Update failed, reloading...");
        fetchHistoryList();
      }
    } catch (e) {
      _showSnack("❌ Error: $e");
      fetchHistoryList();
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> downloadHistoryFile() async {
    final monthNumber = monthNameToNumber(historyMonth);
    final url =
        "https://devcms.com.my/charmsAPI/api/maintenance/history?facility=all&month=$monthNumber&year=$historyYear&download=1";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final htmlContent = decoded['html'] ?? '';
        final fileName = decoded['fileName'] ?? "monthly_report.html";
        final dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) await dir.create(recursive: true);
        final file = File("${dir.path}/$fileName");
        await file.writeAsString(htmlContent);
        _showSnack("✅ Saved to Downloads: $fileName");
      }
    } catch (e) {
      _showSnack("❌ Error: $e");
    }
  }

  InputDecoration dropStyle(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isDense: true,
    );
  }

  // ---------------------- ADMIN NOTES WIDGET ----------------------
  Widget _buildAdminNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                'Administrator Oversight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This dashboard displays all pending maintenance issues reported by staff. '
            'Administrators are required to inspect these reports, coordinate repairs, '
            'and "Mark as Done" once the facility is fully restored to operational standards.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade900,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchHistoryList();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Maintenance History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF05179),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchHistoryList,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              // Added the Admin Notice at the very top
              _buildAdminNotice(),

              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: historyMonth,
                        decoration: dropStyle("Month"),
                        items:
                            months
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setState(() {
                              historyMonth = v!;
                              fetchHistoryList();
                            }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: historyYear,
                        decoration: dropStyle("Year"),
                        items:
                            years
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setState(() {
                              historyYear = v!;
                              fetchHistoryList();
                            }),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: downloadHistoryFile,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text("Download Monthly Report"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    loadingHistory
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: facilities.length,
                          itemBuilder: (context, index) {
                            final facilityName = facilities[index];
                            final fKey = flutterFacilityKey(facilityName);
                            final issues = groupedHistory[fKey] ?? [];
                            final count = issues.length;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                shape: const Border.fromBorderSide(
                                  BorderSide.none,
                                ), // Fixed transparent border
                                leading: CircleAvatar(
                                  backgroundColor:
                                      count > 0
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                  child: Icon(
                                    count > 0
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                    color:
                                        count > 0 ? Colors.red : Colors.green,
                                  ),
                                ),
                                title: Text(
                                  facilityName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (count > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          "$count Issues",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const Icon(Icons.keyboard_arrow_down),
                                  ],
                                ),
                                children: [
                                  if (issues.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Text(
                                        "No pending issues.",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  else
                                    ...issues
                                        .map(
                                          (item) => _buildIssueItem(item, fKey),
                                        )
                                        ,
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueItem(Map item, String fKey) {
    String displayStatus =
        item['status'] == 'completed' ? 'Completed' : 'Pending';
    String description = item['description']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['action'] ?? 'Issue',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                item['created_at'] ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Status: $displayStatus",
            style: TextStyle(
              color: displayStatus == 'Completed' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _renderFormattedText(description),
            ),
          if (item['photo'] != null && item['photo'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['photo'],
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (c, o, s) => const SizedBox(),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: const Text("MARK AS DONE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (c) => AlertDialog(
                        title: const Text("Resolve Issue?"),
                        content: const Text(
                          "This will mark the issue as completed and remove it from this list.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(c);
                              markAsDone(item['id'], fKey);
                            },
                            child: const Text("Confirm"),
                          ),
                        ],
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderFormattedText(String text) {
    List<TextSpan> spans = [];
    List<String> parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: parts[i],
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        );
      }
    }

    return RichText(text: TextSpan(children: spans));
  }
}
