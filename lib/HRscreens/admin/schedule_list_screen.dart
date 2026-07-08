import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRwidgets/admin/hr_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/staffs.dart';


class ScheduleListScreen extends StatefulWidget {
  final String location;
  final DateTime date;

  const ScheduleListScreen({
    super.key,
    required this.location,
    required this.date,
  });

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
      backgroundColor: HRColors.background,
      appBar: HRAppBar(
        title: '${widget.location} Schedules',
        actions: [
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            ),
            tooltip: 'Sort by start time',
            onPressed: () {
              setState(() => _sortAscending = !_sortAscending);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: HRColors.primary))
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

                return RefreshIndicator(
                  color: HRColors.primary,
                  onRefresh: _loadData,
                  child: HRPageContainer(
                    child: schedules.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: HREmptyState(
                                  icon: Icons.event_busy_rounded,
                                  message:
                                      'No schedules found for\n${widget.location} today',
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                                      gender: 0,
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
                              return _ScheduleTile(
                                staffName: staff.username,
                                staffId: schedule.staffId,
                                workStartTime: schedule.workStartTime,
                                workEndTime: schedule.workEndTime,
                                breakStartTime: schedule.breakStartTime,
                                breakEndTime: schedule.breakEndTime,
                              );
                            },
                          ),
                  ),
                );
              },
            ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final String staffName;
  final int staffId;
  final String? workStartTime;
  final String? workEndTime;
  final String? breakStartTime;
  final String? breakEndTime;

  const _ScheduleTile({
    required this.staffName,
    required this.staffId,
    required this.workStartTime,
    required this.workEndTime,
    required this.breakStartTime,
    required this.breakEndTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: hrCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: HRColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 22, color: HRColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$staffName (ID: $staffId)',
                    style: HRTextStyles.cardTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Working Hours',
                    value: '${workStartTime ?? '—'} - ${workEndTime ?? '—'}',
                  ),
                  const SizedBox(height: 4),
                  _InfoRow(
                    icon: Icons.free_breakfast_rounded,
                    label: 'Break Time',
                    value: '${breakStartTime ?? '—'} - ${breakEndTime ?? '—'}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$label: ', style: HRTextStyles.cardSubtitle),
                TextSpan(
                  text: value,
                  style: HRTextStyles.cardSubtitle.copyWith(
                    color: HRColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
