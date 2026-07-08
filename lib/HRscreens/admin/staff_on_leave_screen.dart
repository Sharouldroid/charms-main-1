import 'package:charms/HRmodels/leave.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRscreens/admin/manage_leave_screen.dart';
import 'package:charms/HRwidgets/admin/hr_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Read-only "who's on leave" visibility screen, shared by Admin and Staff
// dashboards. Admin gets a shortcut into Manage Leave; staff only get to view.
class StaffOnLeaveScreen extends StatefulWidget {
  final bool isAdmin;
  const StaffOnLeaveScreen({super.key, this.isAdmin = false});

  @override
  State<StaffOnLeaveScreen> createState() => _StaffOnLeaveScreenState();
}

class _StaffOnLeaveScreenState extends State<StaffOnLeaveScreen> {
  final Color primaryBlue = const Color(0xFF2563EB);
  final Color bgColor     = const Color(0xFFF4F7FA);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      Provider.of<Staffs>(context, listen: false).fetchStaff(),
      Provider.of<Leaves>(context, listen: false).fetchLeaves(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Staff? _getStaff(int staffId, List<Staff> staffList) {
    return staffList.cast<Staff?>().firstWhere(
          (s) => s?.staffId == staffId,
          orElse: () => null,
        );
  }

  int _durationDays(Leave leave) => leave.endDate.difference(leave.startDate).inDays + 1;

  bool _isOnLeaveToday(Leave leave) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final start = DateTime(leave.startDate.year, leave.startDate.month, leave.startDate.day);
    final end   = DateTime(leave.endDate.year, leave.endDate.month, leave.endDate.day);
    return !todayOnly.isBefore(start) && !todayOnly.isAfter(end);
  }

  bool _isUpcoming(Leave leave) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final start = DateTime(leave.startDate.year, leave.startDate.month, leave.startDate.day);
    return start.isAfter(todayOnly);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: HRAppBar(
        title: 'STAFF ON LEAVE',
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined, color: Colors.white),
              tooltip: 'Manage Leave',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManageLeaveScreen())),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : Consumer2<Staffs, Leaves>(
              builder: (context, staffsData, leavesData, _) {
                final staffList = staffsData.staffList;
                final approvedLeaves = leavesData.leaves
                    .where((l) => l.status.trim().toLowerCase() == 'approved')
                    .toList();

                final onLeaveToday = approvedLeaves.where(_isOnLeaveToday).toList()
                  ..sort((a, b) => a.startDate.compareTo(b.startDate));
                final upcoming = approvedLeaves.where(_isUpcoming).toList()
                  ..sort((a, b) => a.startDate.compareTo(b.startDate));

                return RefreshIndicator(
                  color: primaryBlue,
                  onRefresh: _fetchData,
                  child: HRPageContainer(
                    child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _sectionHeader('On Leave Today', onLeaveToday.length, Colors.redAccent),
                      const SizedBox(height: 12),
                      if (onLeaveToday.isEmpty)
                        _emptyState('No staff on leave today')
                      else
                        ...onLeaveToday.map((l) => _leaveCard(l, staffList, active: true)),
                      const SizedBox(height: 24),
                      _sectionHeader('Upcoming Leave', upcoming.length, Colors.orange),
                      const SizedBox(height: 12),
                      if (upcoming.isEmpty)
                        _emptyState('No upcoming approved leave')
                      else
                        ...upcoming.map((l) => _leaveCard(l, staffList, active: false)),
                    ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Text('$count',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _emptyState(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.beach_access_outlined, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _leaveCard(Leave leave, List<Staff> staffList, {required bool active}) {
    final staff     = _getStaff(leave.staffId, staffList);
    final staffName = staff != null ? '${staff.firstname} ${staff.lastname}' : 'Staff ID: ${leave.staffId}';
    final photoPath = staff?.filepath;
    final hasPhoto  = photoPath != null && photoPath.isNotEmpty;
    final duration  = _durationDays(leave);
    final df        = DateFormat('dd MMM yyyy');
    final color     = active ? Colors.redAccent : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.1),
                backgroundImage: hasPhoto
                    ? NetworkImage(
                        'https://devcms.com.my/charmsAPI/public/storage/$photoPath')
                    : null,
                child: hasPhoto ? null : Icon(Icons.person_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staffName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                    Text(leave.leaveType,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration:
                    BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('$duration day${duration > 1 ? 's' : ''}',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text('${df.format(leave.startDate)} → ${df.format(leave.endDate)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF334155), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.subject_rounded, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(leave.reason,
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
