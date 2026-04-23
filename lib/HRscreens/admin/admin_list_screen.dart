import 'package:charms/HRmodels/staff.dart'; 
import 'package:charms/HRproviders/staffs.dart'; 
import 'package:charms/HRproviders/claims.dart'; // ✅ Added
import 'package:charms/HRproviders/leaves.dart'; // ✅ Added
import 'package:charms/HRproviders/payments.dart'; // ✅ Added
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/admin/manage_staff_screen.dart';
import 'package:charms/HRscreens/admin/myself_screen.dart';
import 'package:charms/HRscreens/admin/notification_screen.dart';
import 'package:charms/HRwidgets/admin/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/screens/dashboard_screen.dart';

class AdminListScreen extends StatefulWidget {
  final String username;
  const AdminListScreen({super.key, required this.username});

  @override
  _AdminListScreenState createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  List<Staff> _adminUsers = []; 
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isAscending = true;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadAdminUsers();
  }

  // Helper: get display name (username if firstname is empty)
  String _getDisplayName(Staff staff) { 
    final fullName = '${staff.firstname} ${staff.lastname}'.trim();
    return fullName.isNotEmpty ? fullName : staff.username;
  }

  Future<void> _loadAdminUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final staffsProvider = context.read<Staffs>(); 

      await staffsProvider.fetchStaff().timeout(const Duration(seconds: 12));

      // Filter to only show users where usertype == 6 (Admin)
      final admins = staffsProvider.staffList.where((s) => s.usertype == 6).toList();

      if (!mounted) return;
      setState(() {
        _adminUsers = admins;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('AdminList load error: $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load admins. ${error.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    Navigator.of(context).pushNamedAndRemoveUntil(
      DashboardScreen.routeName,
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard(username: widget.username)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ManageStaffScreen(username: widget.username)),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MySelfScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Staff> filteredAdmins = _adminUsers 
        .where((admin) =>
            '${admin.firstname} ${admin.lastname} ${admin.username}'
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();

    if (_isAscending) {
      filteredAdmins.sort((a, b) =>
          _getDisplayName(a).compareTo(_getDisplayName(b)));
    } else {
      filteredAdmins.sort((a, b) =>
          _getDisplayName(b).compareTo(_getDisplayName(a)));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text('CHARMS ADMIN', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          // ✅ Admin Notification Badge
          Consumer3<Leaves, Payments, Claims>(
            builder: (context, leaves, payments, claims, child) {
              int pendingLeaves = leaves.leaves.where((l) => l.status == 'Pending').length;
              int pendingPayrolls = payments.payments.where((p) => p.status == 'Pending').length;
              int pendingClaims = claims.claims.where((c) => c.status == 'Pending').length;

              int totalPending = pendingLeaves + pendingPayrolls + pendingClaims;

              return IconButton(
                icon: totalPending > 0
                    ? Badge(
                        label: Text(totalPending.toString()),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.notifications),
                      )
                    : const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Back to Dashboard',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Admins: ${filteredAdmins.length}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    decoration: const InputDecoration(
                      labelText: 'Search by name',
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
                Expanded(
                  child: filteredAdmins.isEmpty
                      ? const Center(
                          child: Text(
                            'No admin data found',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredAdmins.length,
                          itemBuilder: (context, index) {
                            final admin = filteredAdmins[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  backgroundImage: (admin.filepath != null && admin.filepath!.isNotEmpty)
                                      ? NetworkImage('https://devcms.com.my/charmsAPI/public/storage/${admin.filepath}')
                                      : null,
                                  child: (admin.filepath == null || admin.filepath!.isEmpty)
                                      ? const Icon(Icons.person, color: Colors.white)
                                      : null,
                                ),
                                title: Text(
                                  _getDisplayName(admin),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('${admin.email} - Status: Active'),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text(_getDisplayName(admin)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Username: ${admin.username}'),
                                          Text('Email: ${admin.email}'),
                                          Text('User Type: ${admin.usertype}'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}