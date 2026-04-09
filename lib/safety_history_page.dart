import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charms/utils/responsive_helper.dart';

class SafetyHistoryPage extends StatefulWidget {
  const SafetyHistoryPage({super.key});

  @override
  State<SafetyHistoryPage> createState() => _SafetyHistoryPageState();
}

class _SafetyHistoryPageState extends State<SafetyHistoryPage> {
  // Current Filters
  String selectedMonth = 'May';
  String selectedYear = '2025';
  bool isLoading = false;

  // Data Containers
  List<dynamic> allHistoryItems = [];
  Map<String, List<dynamic>> groupedHistory = {};

  final List<String> resourceTypes = [
    'First Aid',
    'Backpacking',
    'Landscape',
    'Water Quality',
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

  int getMonthNumber(String month) => months.indexOf(month) + 1;

  // --- API Functions ---

  Future<void> fetchHistory() async {
    setState(() => isLoading = true);

    final monthNum = getMonthNumber(selectedMonth);

    final url = Uri.parse(
      'https://devcms.com.my/charmsAPI/api/safety/history?type=all&month=$monthNum&year=$selectedYear',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        setState(() {
          allHistoryItems = data;
          _groupItemsByCategory();
        });
      } else {
        _showSnack("❌ Error: ${response.statusCode}");
      }
    } catch (e) {
      _showSnack("❌ Connection Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _groupItemsByCategory() {
    groupedHistory.clear();

    for (var type in resourceTypes) {
      groupedHistory[type] = [];
    }

    for (var item in allHistoryItems) {
      String category = item['category'] ?? 'Other';
      if (!groupedHistory.containsKey(category)) {
        groupedHistory[category] = [];
      }
      groupedHistory[category]!.add(item);
    }
  }

  Future<void> markAsDone(int id, String status) async {
    setState(() {
      allHistoryItems.removeWhere((item) => item['id'] == id);
      _groupItemsByCategory();
    });

    final url = Uri.parse(
      'https://devcms.com.my/charmsAPI/api/safety/update-status',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'status': 'Completed'}),
      );

      if (response.statusCode == 200) {
        _showSnack('✅ Marked as Done!');
      } else {
        _showSnack('❌ Failed to update. Reloading...');
        fetchHistory();
      }
    } catch (e) {
      _showSnack('⚠️ Error: $e');
      fetchHistory();
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  // --- UI Helpers ---

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
              Icon(
                Icons.admin_panel_settings,
                color: Colors.blue.shade800,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Admin Safety Review',
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
            'The reports below represent safety inspections and issues flagged by staff. '
            'Administrators must verify each report, ensure necessary safety actions are taken, '
            'and resolve any hazards before marking them as completed.',
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

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'First Aid':
        return Icons.medical_services;
      case 'Backpacking':
        return Icons.backpack;
      case 'Landscape':
        return Icons.nature;
      case 'Water Quality':
        return Icons.water_drop;
      default:
        return Icons.category;
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

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Safety Report History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF05179),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchHistory),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              // Added the Admin Notice at the top of the body
              _buildAdminNotice(),

              // --- FILTERS (Month & Year) ---
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedMonth,
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
                        onChanged: (val) {
                          setState(() => selectedMonth = val!);
                          fetchHistory();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedYear,
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
                        onChanged: (val) {
                          setState(() => selectedYear = val!);
                          fetchHistory();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // --- ACCORDION LIST ---
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20, top: 10),
                          itemCount: resourceTypes.length,
                          itemBuilder: (context, index) {
                            final category = resourceTypes[index];
                            final reports = groupedHistory[category] ?? [];

                            final pendingReports =
                                reports
                                    .where(
                                      (r) =>
                                          !(r['status'] ?? '')
                                              .toString()
                                              .toLowerCase()
                                              .contains('completed'),
                                    )
                                    .toList();

                            final count = pendingReports.length;

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
                                ),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      count > 0
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                  child: Icon(
                                    getCategoryIcon(category),
                                    color:
                                        count > 0 ? Colors.red : Colors.green,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  category,
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
                                          "$count Reports",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.keyboard_arrow_down),
                                  ],
                                ),
                                children: [
                                  if (pendingReports.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Text(
                                        "No pending reports.",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  else
                                    ...pendingReports
                                        .map((item) => _buildReportItem(item))
                                        .toList(),
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

  Widget _buildReportItem(Map item) {
    List<TextSpan> _parseDescription(String text) {
      List<TextSpan> spans = [];
      final parts = text.split('**');

      for (int i = 0; i < parts.length; i++) {
        if (i % 2 == 1) {
          spans.add(
            TextSpan(
              text: parts[i],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontStyle: FontStyle.normal,
              ),
            ),
          );
        } else {
          spans.add(TextSpan(text: parts[i]));
        }
      }
      return spans;
    }

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
                  item['title'] ?? 'Safety Report',
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

          if (item['description'] != null &&
              item['description'].toString().isNotEmpty)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
                children: _parseDescription(item['description']),
              ),
            ),

          if (item['photo'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  "https://devcms.com.my/charmsAPI/storage/${item['photo']}",
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (c, o, s) => Container(
                        height: 120,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
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
                        title: const Text("Complete Report?"),
                        content: const Text(
                          "This will mark the report as completed and remove it from this list.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(c);
                              markAsDone(item['id'], item['status'] ?? '');
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
}
