import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRscreens/admin/staff_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRscreens/admin/register_staff_screen.dart';

class StaffListScreen extends StatefulWidget {
  @override
  _StaffListScreenState createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
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
            'Manage Staff',
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
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterStaffScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.add, color: Colors.red),
                          label: Text('Add Staff', style: TextStyle(color: Colors.red)),
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

  StaffListTile({required this.staff});

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
              builder: (context) => StaffDetailsScreen(staff: staff),
            ),
          );
        },
      ),
    );
  }
}