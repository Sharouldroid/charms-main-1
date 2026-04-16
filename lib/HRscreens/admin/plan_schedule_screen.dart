import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRscreens/admin/staff_schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';

class PlanScheduleScreen extends StatefulWidget {
  const PlanScheduleScreen({super.key});

  @override
  _PlanScheduleScreeState createState() => _PlanScheduleScreeState();
}

class _PlanScheduleScreeState extends State<PlanScheduleScreen> {
  String _searchQuery = '';
  bool _isAscending = true;
  int _selectedTabIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('InitState called');
    Future.delayed(Duration.zero, () {
      _loadStaffData();
    });
  }

  Future<void> _loadStaffData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<Staffs>(context, listen: false).fetchStaff();
      print('Staff data loaded successfully');
    } catch (error) {
      print('Error loading staff data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load staff data: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            'Manage Schedule',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          bottom: TabBar(
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
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Employees: ${filteredStaff.length}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(_isAscending ? Icons.sort_by_alpha : Icons.sort),
                          onPressed: () {
                            setState(() {
                              _isAscending = !_isAscending;
                            });
                          },
                          tooltip: 'Sort Alphabetically',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search by Name or ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: filteredStaff.isEmpty
                        ? Center(
                            child: Text('No staff found in this category'),
                          )
                        : ListView.builder(
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
    );
  }
}

class StaffListTile extends StatelessWidget {
  final Staff staff;

  const StaffListTile({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          '${staff.firstname} ${staff.lastname}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ID: ${staff.staffId} | ${staff.occupation}'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffScheduleScreen(
                staffId: staff.staffId,
                firstName: staff.firstname,
                lastName:staff.lastname,
                staffType: staff.usertype,),
            ),
          );
        },
      ),
    );
  }
}