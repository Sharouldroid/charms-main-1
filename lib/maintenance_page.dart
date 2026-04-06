import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';                          
import 'package:charms/utils/responsive_helper.dart';
import 'package:charms/providers/users.dart';                         

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  String selectedFacility = 'Campsite';
  String? selectedMonth;
  String? selectedYear;
  bool _isDownloading = false;

  final List<String> facilities = [
    'Campsite',
    'Kitchen',
    'Quarters',
    'Outdoor Classroom',
    'Water Sport Area',
    'Office',
    'BalaiSaf (Surau)',
    'Replacement Items',
  ];

  final Map<String, IconData> facilityIcons = {
    'Campsite': Icons.park,
    'Kitchen': Icons.kitchen,
    'Quarters': Icons.house,
    'Outdoor Classroom': Icons.school,
    'Water Sport Area': Icons.water,
    'Office': Icons.apartment,
    'BalaiSaf (Surau)': Icons.mosque,
    'Replacement Items': Icons.change_circle,
  };

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

  List<String> availableMonths = [];
  List<String> availableYears = [];

  int monthNameToNumber(String month) => months.indexOf(month) + 1;

  String flutterFacilityKey(String selected) {
    if (selected == 'BalaiSaf (Surau)') return 'balaisafsurau';
    return selected
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('(', '')
        .replaceAll(')', '');
  }

  @override
  void initState() {
    super.initState();
    fetchAvailableDates();
  }

  // ---------------------- FETCH AVAILABLE MONTHS/YEARS ----------------------
  Future<void> fetchAvailableDates() async {
    final facilityKey = flutterFacilityKey(selectedFacility);
    final url =
        "https://devcms.com.my/charmsAPI/api/maintenance/available-dates?facility=$facilityKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final monthsFromApi = List<int>.from(data['months'] ?? []);
        final yearsFromApi = List<int>.from(data['years'] ?? []);

        setState(() {
          availableMonths =
              monthsFromApi.isNotEmpty
                  ? monthsFromApi.map((m) => months[m - 1]).toList()
                  : months;

          availableYears =
              yearsFromApi.isNotEmpty
                  ? yearsFromApi.map((y) => y.toString()).toList()
                  : [DateTime.now().year.toString()];

          selectedMonth =
              availableMonths.isNotEmpty ? availableMonths.first : null;
          selectedYear =
              availableYears.isNotEmpty ? availableYears.first : null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed to fetch dates: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error fetching dates: $e")));
    }
  }

  // ---------------------- DOWNLOAD REPORT ----------------------
  Future<void> _saveReport() async {
    if (selectedYear == null ||
        selectedMonth == null ||
        selectedFacility.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Please select facility, month, and year"),
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    final facilityKey = flutterFacilityKey(selectedFacility);
    final monthNumber = monthNameToNumber(selectedMonth!);
    final url =
        'https://devcms.com.my/charmsAPI/api/maintenance/report?facility=$facilityKey&year=$selectedYear&month=$monthNumber';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final fileName =
            '${facilityKey}_report_${DateTime.now().millisecondsSinceEpoch}.html';
        final filePath = '${dir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Report saved: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to download: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error downloading report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  // ---------------------- FACILITY CARD ----------------------
  Widget buildFacilityCard(String label, IconData icon) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final iconSize = ResponsiveHelper.getIconSize(context, baseSize: 40);
    final fontSize = isTablet ? 16.0 : 14.0;
    final cardPadding = isTablet ? 20.0 : 16.0;

    return GestureDetector(
      onTap: () {
        if (label == 'Replacement Items') {
          Navigator.pushNamed(context, '/replacementitems');
        } else {
          Navigator.pushNamed(
            context,
            '/${label.toLowerCase().replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '')}',
          );
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------- REMINDER SECTION ----------------------
  Widget _buildReminderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF05179).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF05179).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notification_important, color: Color(0xFFF05179)),
              SizedBox(width: 8),
              Text(
                'Post-Slot Requirement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF05179),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'The following areas MUST be checked after every volunteer slot finish:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                [
                      'Campsite',
                      'Kitchen',
                      'Quarters',
                      'Outdoor Classroom',
                      'Water Sport Area',
                      'Office',
                      'Surau',
                    ]
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFF05179).withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------- BUILD ----------------------
  @override
  Widget build(BuildContext context) {
    // ✅ Get user role
    final user = Provider.of<Users>(context, listen: false).userlist.first;
    final int role = user.usertype;   // e.g., 9 = Marine Biologist

    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    final spacing = ResponsiveHelper.getSpacing(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maintenance Page',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF05179),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReminderSection(),
                const SizedBox(height: 24),

                GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isTablet ? 1.3 : 1.1,
                  children:
                      facilities.map((f) {
                        final icon = facilityIcons[f] ?? Icons.build;
                        return buildFacilityCard(f, icon);
                      }).toList(),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Facility Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF05179),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: selectedFacility,
                  isExpanded: true,
                  items:
                      facilities
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedFacility = v!;
                      selectedMonth = null;
                      selectedYear = null;
                    });
                    fetchAvailableDates();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedMonth,
                        isExpanded: true,
                        hint: const Text('Select Month'),
                        items:
                            availableMonths
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => selectedMonth = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedYear,
                        isExpanded: true,
                        hint: const Text('Select Year'),
                        items:
                            availableYears
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => selectedYear = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _saveReport,
                  icon:
                      _isDownloading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.download, color: Colors.white),
                  label: Text(
                    _isDownloading ? "Saving..." : "Download Report",
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
                const SizedBox(height: 16),

                // ✅ History button – only shown if role is NOT Marine Biologist (9)
                if (role != 9)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/transactionhistory');
                    },
                    icon: const Icon(Icons.history, color: Colors.white),
                    label: const Text(
                      'View Maintenance History',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black45,
                    ),
                  ),
                // No extra button removed – the original is now conditional
              ],
            ),
          ),
        ),
      ),
    );
  }
}