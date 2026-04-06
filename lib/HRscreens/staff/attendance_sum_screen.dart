import 'package:flutter/material.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  @override
  _AttendanceSummaryScreenState createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  String _selectedYear = '2024';
  String _selectedMonth = '10';
  List<Map<String, dynamic>> _attendanceData = [];

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
      appBar: AppBar(
        title: const Text('Attendance Summary'),
        backgroundColor: Colors.blue, // Setting AppBar color to blue
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dropdown for selecting year
                DropdownButton<String>(
                  value: _selectedYear,
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
                const SizedBox(width: 20),
                // Dropdown for selecting month
                DropdownButton<String>(
                  value: _selectedMonth,
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
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: Future.delayed(
                const Duration(seconds: 1),
                () => _filteredData,
              ), // Fetch data
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error loading data'),
                  );
                } else {
                  final data = snapshot.data ?? [];

                  if (data.isEmpty) {
                    return const Center(
                      child: Text('No data available'),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Month/Year')),
                        DataColumn(label: Text('Total Days')),
                        DataColumn(label: Text('Days Present')),
                        DataColumn(label: Text('Days Absent')),
                        DataColumn(label: Text('Days On Leave')),
                        DataColumn(label: Text('Days Late')),
                      ],
                      rows: data.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item['month_year'])),
                          DataCell(Text(item['total_days'].toString())),
                          DataCell(Text(item['days_present'].toString())),
                          DataCell(Text(item['days_absent'].toString())),
                          DataCell(Text(item['days_on_leave'].toString())),
                          DataCell(Text(item['days_late'].toString())),
                        ]);
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
