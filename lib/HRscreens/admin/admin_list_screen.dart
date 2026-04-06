import 'package:charms/HRmodels/user.dart';
import 'package:charms/HRproviders/auth.dart';
import 'package:charms/HRproviders/users.dart';
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/admin/manage_staff_screen.dart';
import 'package:charms/HRscreens/admin/myself_screen.dart';
import 'package:charms/HRscreens/admin/notification_screen.dart';
import 'package:charms/HRscreens/auth_screen.dart';
import 'package:charms/HRwidgets/admin/bottom_nav_bar.dart';
import 'package:charms/HRwidgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminListScreen extends StatefulWidget {
  @override
  _AdminListScreenState createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  late String username;
  List<User> _adminUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isAscending = true;
  int _selectedIndex = 2;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];

  @override
  void initState() {
    super.initState();
    username = Provider.of<Auth>(context, listen: false).username;
    _loadAdminUsers();
  }

  Future<void> _loadAdminUsers() async {
    try {
      final usersProvider = Provider.of<Users>(context, listen: false);
      final authProvider = Provider.of<Auth>(context, listen: false);
      
      // FIXED: Updated the API URL to match your production environment
      await usersProvider.fetchUsers(authProvider.hostname);
      
      // Get the data from the response
      final admins = usersProvider.userlist
          .where((user) => user.usertype == 6)
          .toList();

      setState(() {
        _adminUsers = admins;
        _isLoading = false;
      });
    } catch (error) {
      print('Error details: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load admin users: $error')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await Provider.of<Auth>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminDashboard(username: username)));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => ManageStaffScreen()));
        break;
      case 2:
        // Already on this screen
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => MySelfScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<User> filteredAdmins = _adminUsers
        .where((admin) => 
            '${admin.firstname} ${admin.lastname}'.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (_isAscending) {
      filteredAdmins.sort((a, b) => 
          '${a.firstname} ${a.lastname}'.compareTo('${b.firstname} ${b.lastname}'));
    } else {
      filteredAdmins.sort((a, b) => 
          '${b.firstname} ${b.lastname}'.compareTo('${a.firstname} ${a.lastname}'));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('CHARMS ADMIN', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
          }),
        ],
      ),
      drawer: CustomDrawer(
        selectedLanguage: _selectedLanguage,
        languages: _languages,
        onLanguageChanged: (String? newValue) {
          setState(() {
            _selectedLanguage = newValue!;
          });
        },
        onLogOut: _logout,
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
                      Text('Total Admins: ${filteredAdmins.length}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  child: ListView.builder(
                    itemCount: filteredAdmins.length,
                    itemBuilder: (context, index) {
                      var admin = filteredAdmins[index];
                      return StaffListTile(
                        staffId: int.tryParse(admin.id) ?? 0,
                        name: '${admin.firstname} ${admin.lastname}',
                        occupation: admin.occupation,
                        status: 'Active',
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

class StaffListTile extends StatelessWidget {
  final int staffId;
  final String name;
  final String occupation;
  final String status;

  StaffListTile({
    required this.staffId,
    required this.name,
    required this.occupation,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$occupation - Status: $status"),
        onTap: () {
          // Add navigation to details if needed
        },
      ),
    );
  }
}