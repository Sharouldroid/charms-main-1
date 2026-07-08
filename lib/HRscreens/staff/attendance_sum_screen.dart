import 'package:flutter/material.dart';
import 'package:charms/HRwidgets/staff/hr_staff_theme.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  _AttendanceSummaryScreenState createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  String _selectedYear = '2024';
  String _selectedMonth = '10';
  List<Map<String, dynamic>> _attendanceData = [];

  // Distinct Staff UI Color Palette (Indigo & Slate)
  final Color staffPrimary = const Color(0xFF4F46E5); // Deep Indigo
  final Color staffBg = const Color(0xFFF8FAFC); // Very Light Slate
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _fetchAttendanceSummary(); // Fetch data when the screen loads
  }

  Future<void> _fetchAttendanceSummary() async {
    // Replace this mock data with your actual data fetching logic
    await Future.delayed(const Duration(seconds: 2)); // Simulating network delay

    // Mock data for demonstration
    final data = [
      {
        'month_year': '2024-10',
        'total_days': 22,
        'days_present': 20,
        'days_absent': 1,
        'days_on_leave': 1,
        'days_late': 0,
      },
      {
        'month_year': '2024-09',
        'total_days': 21,
        'days_present': 18,
        'days_absent': 2,
        'days_on_leave': 1,
        'days_late': 0,
      },
      {
        'month_year': '2023-10',
        'total_days': 20,
        'days_present': 19,
        'days_absent': 0,
        'days_on_leave': 1,
        'days_late': 1,
      },
    ];

    setState(() {
      _attendanceData = data;
    });
  }

  List<Map<String, dynamic>> get _filteredData {
    return _attendanceData.where((item) {
      return item['month_year'].startsWith('$_selectedYear-$_selectedMonth');
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: staffBg, // Modern Background
      appBar: const StaffAppBar(title: 'ATTENDANCE SUMMARY'),
      body: StaffPageContainer(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Filter Section
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Dropdown for selecting year
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: staffPrimary),
                      value: _selectedYear,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      items: ['2024', '2023', '2022'].map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedYear = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 16)),
                // Dropdown for selecting month
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: staffPrimary),
                      value: _selectedMonth,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      items: [
                        {'value': '01', 'label': 'January'},
                        {'value': '02', 'label': 'February'},
                        {'value': '03', 'label': 'March'},
                        {'value': '04', 'label': 'April'},
                        {'value': '05', 'label': 'May'},
                        {'value': '06', 'label': 'June'},
                        {'value': '07', 'label': 'July'},
                        {'value': '08', 'label': 'August'},
                        {'value': '09', 'label': 'September'},
                        {'value': '10', 'label': 'October'},
                        {'value': '11', 'label': 'November'},
                        {'value': '12', 'label': 'December'},
                      ].map((month) {
                        return DropdownMenuItem(
                          value: month['value'],
                          child: Text(month['label']!),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedMonth = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text(
              'Summary Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Data Table Section
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: Future.delayed(
                const Duration(seconds: 1),
                () => _filteredData,
              ), // Fetch data
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: staffPrimary),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        const Text('Error loading data', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                } else {
                  final data = snapshot.data ?? [];

                  if (data.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No records found for this period',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias, // Ensures the table corners are rounded
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(staffPrimary.withOpacity(0.05)),
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        dataTextStyle: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500),
                        dividerThickness: 1,
                        columns: const [
                          DataColumn(label: Text('Period')),
                          DataColumn(label: Text('Total Days')),
                          DataColumn(label: Text('Present')),
                          DataColumn(label: Text('Absent')),
                          DataColumn(label: Text('On Leave')),
                          DataColumn(label: Text('Late')),
                        ],
                        rows: data.map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item['month_year'], style: TextStyle(color: staffPrimary, fontWeight: FontWeight.bold))),
                            DataCell(Text(item['total_days'].toString())),
                            DataCell(Text(item['days_present'].toString(), style: const TextStyle(color: Colors.teal))),
                            DataCell(Text(item['days_absent'].toString(), style: const TextStyle(color: Colors.redAccent))),
                            DataCell(Text(item['days_on_leave'].toString(), style: const TextStyle(color: Colors.orange))),
                            DataCell(Text(item['days_late'].toString())),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
        ),
      ),
    );
  }
}