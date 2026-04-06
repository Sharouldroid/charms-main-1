import 'package:charms/HRmodels/staff.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/staffs.dart';


class ScheduleListScreen extends StatefulWidget {
  final String location;
  final DateTime date;

  const ScheduleListScreen({
    Key? key,
    required this.location,
    required this.date,
  }) : super(key: key);

  @override
  _ScheduleListScreenState createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  bool _sortAscending = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final schedulesProvider = Provider.of<Schedules>(context, listen: false);
      final staffsProvider = Provider.of<Staffs>(context, listen: false);

      await Future.wait([
        schedulesProvider.fetchSchedules(),
        staffsProvider.fetchStaff(),
      ]);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $error')),
      );
    }
    setState(() => _isLoading = false);
  }

  int _getLocationId(String location) {
    switch (location) {
      case 'Chagar Hutang':
        return 1;
      case 'Turtle Lab':
        return 2;
      case 'UMT':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          '${widget.location} Schedules',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
                _sortAscending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() => _sortAscending = !_sortAscending);
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Consumer2<Schedules, Staffs>(
              builder: (context, schedulesProvider, staffsProvider, child) {
                final locationId = _getLocationId(widget.location);
                final formattedDate =
                    DateFormat('yyyy-MM-dd').format(widget.date);

                var schedules = schedulesProvider.schedules
                    .where((schedule) =>
                        schedule.workLocation == locationId &&
                        DateFormat('yyyy-MM-dd').format(schedule.workDate) ==
                            formattedDate)
                    .toList();

                if (_sortAscending) {
                  schedules.sort(
                      (a, b) => a.workStartTime!.compareTo(b.workStartTime!));
                } else {
                  schedules.sort(
                      (a, b) => b.workStartTime!.compareTo(a.workStartTime!));
                }

                if (schedules.isEmpty) {
                  return Center(
                    child:
                        Text('No schedules found for ${widget.location} today'),
                  );
                }

                return ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    // Find matching staff
                    final staff = staffsProvider.staffList.firstWhere(
                        (s) => s.staffId == schedule.staffId,
                        orElse: () => Staff(
                            staffId: schedule.staffId,
                            userId: 0,
                            username: 'Unknown',
                            email: '',
                            usertype: 0,
                            firstname: '',
                            lastname: '',
                            occupation: '',
                            phone: '',
                            category: 0,
                            nationality: '',
                            religion: '',
                            maritalStatus: 0,
                            emergencyName: '',
                            emergencyIc: '',
                            emergencyRelation: '',
                            emergencyGender: 0,
                            emergencyPhone: '',
                            idNum: '',
                            dob: '',
                            address1: '',
                            address2: '',
                            city: '',
                            postcode: 0,
                            state: '',
                            country: ''));
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(staff != null
                            ? '${staff.username} (ID: ${schedule.staffId})'
                            : 'Staff ID: ${schedule.staffId}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Working Hours: ${schedule.workStartTime} - ${schedule.workEndTime}'),
                            Text(
                                'Break Time: ${schedule.breakStartTime} - ${schedule.breakEndTime}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
