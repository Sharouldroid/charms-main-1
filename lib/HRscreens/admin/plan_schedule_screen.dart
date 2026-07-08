import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRscreens/admin/staff_schedule_screen.dart';
import 'package:charms/HRscreens/staff/StaffScheduleHistoryScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRwidgets/admin/hr_theme.dart';

class PlanScheduleScreen extends StatefulWidget {
  const PlanScheduleScreen({super.key});

  @override
  _PlanScheduleScreenState createState() => _PlanScheduleScreenState();
}

class _PlanScheduleScreenState extends State<PlanScheduleScreen> {
  String _searchQuery = '';
  bool _isAscending = true;
  int _selectedTabIndex = 0;
  bool _isLoading = true;

  // Modern Color Palette Constants
  final Color bgColor      = const Color(0xFFF4F7FA);
  final Color primaryBlue  = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _loadStaffData);
  }

  Future<void> _loadStaffData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await Provider.of<Staffs>(context, listen: false).fetchStaff();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load staff data: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Staff> _getFilteredStaff(List<Staff> staffList) {
    return staffList
        .where((staff) =>
            '${staff.firstname} ${staff.lastname} ${staff.userId}'
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<Staffs>(context);
    final staffList     = staffProvider.getStaffByCategory(_selectedTabIndex + 1);
    final filteredStaff = _getFilteredStaff(staffList);

    if (_isAscending) {
      filteredStaff.sort((a, b) => a.firstname.compareTo(b.firstname));
    } else {
      filteredStaff.sort((a, b) => b.firstname.compareTo(a.firstname));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: HRAppBar(
          title: 'MANAGE SCHEDULE',
          bottomHeight: 48,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal),
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
                _searchQuery = '';
              });
            },
            tabs: const [
              Tab(child: Text('SEATRU', style: TextStyle(color: Colors.white))),
              Tab(child: Text('CMS',    style: TextStyle(color: Colors.white))),
              Tab(child: Text('Intern', style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryBlue))
            : RefreshIndicator(
                color: primaryBlue,
                onRefresh: _loadStaffData,
                child: HRPageContainer(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // ── Count + Sort ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Employees',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text('${filteredStaff.length} Found',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B))),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(_isAscending
                                  ? Icons.sort_by_alpha_rounded
                                  : Icons.sort_rounded),
                              color: primaryBlue,
                              onPressed: () =>
                                  setState(() => _isAscending = !_isAscending),
                              tooltip: 'Sort Alphabetically',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Search bar ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by Name or ID...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search_rounded,
                                color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Staff list ───────────────────────────────────────────
                    Expanded(
                      child: filteredStaff.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_busy_rounded,
                                      size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('No staff found',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: filteredStaff.length,
                              itemBuilder: (context, index) {
                                final staff = filteredStaff[index];
                                return StaffListTile(
                                  staff: staff,
                                  primaryBlue: primaryBlue,
                                );
                              },
                            ),
                    ),
                  ],
                ),
                ),
              ),
      ),
    );
  }
}

// ── Staff tile with Schedule + History buttons ────────────────────────────────
class StaffListTile extends StatelessWidget {
  final Staff staff;
  final Color primaryBlue;

  const StaffListTile({
    super.key,
    required this.staff,
    required this.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  size: 24, color: Colors.blue),
            ),
            const SizedBox(width: 14),

            // ── Name + ID ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${staff.firstname} ${staff.lastname}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${staff.staffId} • ${staff.occupation.isNotEmpty ? staff.occupation : "—"}',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // ── History button ─────────────────────────────────────────────
            Tooltip(
              message: 'Schedule History',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StaffScheduleHistoryScreen(
                      staffId:  staff.staffId,
                      username: staff.username,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.history_toggle_off_rounded,
                      size: 18, color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Schedule button ────────────────────────────────────────────
            Tooltip(
              message: 'Manage Schedule',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StaffScheduleScreen(
                      staffId:   staff.staffId,
                      firstName: staff.firstname,
                      lastName:  staff.lastname,
                      staffType: staff.usertype,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryBlue.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: primaryBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}