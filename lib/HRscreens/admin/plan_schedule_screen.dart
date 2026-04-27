import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRscreens/admin/staff_schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';

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
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    print('InitState called');
    Future.delayed(Duration.zero, () {
      _loadStaffData();
    });
  }

  Future<void> _loadStaffData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<Staffs>(context, listen: false).fetchStaff();
      print('Staff data loaded successfully');
    } catch (error) {
      print('Error loading staff data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load staff data: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    print('Total staff in provider: ${staffProvider.staffList.length}');
    
    final staffList = staffProvider.getStaffByCategory(_selectedTabIndex + 1);
    print('Staff in category ${_selectedTabIndex + 1}: ${staffList.length}');
    
    final filteredStaff = _getFilteredStaff(staffList);

    if (_isAscending) {
      filteredStaff.sort((a, b) => a.firstname.compareTo(b.firstname));
    } else {
      filteredStaff.sort((a, b) => b.firstname.compareTo(a.firstname));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor, // Applied modern background
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'MANAGE SCHEDULE',
            style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.2),
          ),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
                _searchQuery = '';
              });
            },
            tabs: const [
              Tab(child: Text('SEATRU', style: TextStyle(color: Colors.white))),
              Tab(child: Text('CMS', style: TextStyle(color: Colors.white))),
              Tab(child: Text('Intern', style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryBlue))
            : RefreshIndicator(
                color: primaryBlue,
                onRefresh: _loadStaffData,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    
                    // Row 1 — Employee Count & Sort Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Employees',
                                style: TextStyle(
                                    color: Colors.grey.shade600, 
                                    fontSize: 13, 
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${filteredStaff.length} Found',
                                style: const TextStyle(
                                    fontSize: 20, 
                                    fontWeight: FontWeight.bold, 
                                    color: Color(0xFF1E293B)),
                              ),
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
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(_isAscending 
                                  ? Icons.sort_by_alpha_rounded 
                                  : Icons.sort_rounded),
                              color: primaryBlue,
                              onPressed: () {
                                setState(() {
                                  _isAscending = !_isAscending;
                                });
                              },
                              tooltip: 'Sort Alphabetically',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Row 2 — Search Bar
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
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by Name or ID...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Row 3 — Staff List
                    Expanded(
                      child: filteredStaff.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('No staff found',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: filteredStaff.length,
                              itemBuilder: (context, index) {
                                final staff = filteredStaff[index];
                                return StaffListTile(staff: staff);
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class StaffListTile extends StatelessWidget {
  final Staff staff;

  const StaffListTile({super.key, required this.staff});

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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_month_rounded, // Changed to calendar icon to fit scheduling theme
            size: 24,
            color: Colors.blue,
          ),
        ),
        title: Text(
          '${staff.firstname} ${staff.lastname}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'ID: ${staff.staffId} • ${staff.occupation}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.blue,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffScheduleScreen(
                staffId: staff.staffId,
                firstName: staff.firstname,
                lastName: staff.lastname,
                staffType: staff.usertype,
              ),
            ),
          );
        },
      ),
    );
  }
}