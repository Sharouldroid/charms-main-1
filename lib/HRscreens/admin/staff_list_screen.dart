import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRscreens/admin/register_staff_screen.dart';
import 'package:charms/HRscreens/admin/staff_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  String _searchQuery = '';
  bool _isAscending = true;
  int _selectedTabIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadStaffData);
  }

  Future<void> _loadStaffData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await context.read<Staffs>().fetchStaff();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load staff data: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Staff> _getFilteredStaff(List<Staff> staffList) {
    return staffList.where((staff) {
      final full = '${staff.firstname} ${staff.lastname} ${staff.staffId}'.toLowerCase();
      return full.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = context.watch<Staffs>();
    final staffList = staffProvider.getStaffByCategory(_selectedTabIndex + 1);
    final filteredStaff = _getFilteredStaff(staffList);

    filteredStaff.sort((a, b) => _isAscending
        ? a.firstname.compareTo(b.firstname)
        : b.firstname.compareTo(a.firstname));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Manage Staff', style: TextStyle(color: Colors.white)),
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
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStaffData,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Employees: ${filteredStaff.length}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                           onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterStaffScreen()),
                                );

                                if (result == true) {
                                  await _loadStaffData();
                                }
                              },
                            icon: const Icon(Icons.add, color: Colors.red),
                            label: const Text('Add Staff', style: TextStyle(color: Colors.red)),
                          ),
                          IconButton(
                            icon: Icon(_isAscending ? Icons.sort_by_alpha : Icons.sort),
                            onPressed: () => setState(() => _isAscending = !_isAscending),
                            tooltip: 'Sort Alphabetically',
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search by Name or ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredStaff.isEmpty
                          ? const Center(child: Text('No staff found in this category'))
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
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          '${staff.firstname} ${staff.lastname}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ID: ${staff.staffId} | ${staff.occupation}'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StaffDetailsScreen(staff: staff)),
          );
        },
      ),
    );
  }
}