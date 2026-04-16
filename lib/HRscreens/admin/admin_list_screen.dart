import 'package:charms/HRmodels/user.dart';
import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/HRproviders/users.dart';
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
  List<User> _adminUsers = [];
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
  String _getDisplayName(User user) {
    final fullName = '${user.firstname} ${user.lastname}'.trim();
    return fullName.isNotEmpty ? fullName : user.username;
  }

  Future<void> _loadAdminUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final usersProvider = context.read<Users>();
      final authProvider = Provider.of<hr_auth.Auth>(context, listen: false);

      await usersProvider
          .fetchUsers(authProvider.hostname, token: authProvider.token)
          .timeout(const Duration(seconds: 12));

      final admins = usersProvider.userlist.where((u) => u.usertype == 6).toList();

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
    List<User> filteredAdmins = _adminUsers
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
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationScreen()),
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
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Icon(Icons.person, color: Colors.white),
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