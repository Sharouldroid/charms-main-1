import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/payments.dart';
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

  // ── Matches AdminDashboard palette ──────────────────────────────────────────
  final Color _bgColor = const Color(0xFFF4F7FA);
  final Color _primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadAdminUsers();
  }

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

      final admins =
          staffsProvider.staffList.where((s) => s.usertype == 6).toList();

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
          MaterialPageRoute(
              builder: (_) => AdminDashboard(username: widget.username)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ManageStaffScreen(username: widget.username)),
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

  void _showAdminDetail(Staff admin) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _primaryBlue.withOpacity(0.12),
              backgroundImage: (admin.filepath != null &&
                      admin.filepath!.isNotEmpty)
                  ? NetworkImage(
                      'https://devcms.com.my/charmsAPI/public/storage/${admin.filepath}')
                  : null,
              child: (admin.filepath == null || admin.filepath!.isEmpty)
                  ? Icon(Icons.person, color: _primaryBlue)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getDisplayName(admin),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow(Icons.account_circle_rounded, 'Username', admin.username),
            const SizedBox(height: 10),
            _dialogRow(Icons.email_rounded, 'Email', admin.email),
            const SizedBox(height: 10),
            _dialogRow(Icons.badge_rounded, 'User Type',
                admin.usertype.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _primaryBlue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
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
      filteredAdmins
          .sort((a, b) => _getDisplayName(a).compareTo(_getDisplayName(b)));
    } else {
      filteredAdmins
          .sort((a, b) => _getDisplayName(b).compareTo(_getDisplayName(a)));
    }

    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text(
          'CHARMS ADMIN',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          Consumer3<Leaves, Payments, Claims>(
            builder: (context, leaves, payments, claims, child) {
              int pendingLeaves =
                  leaves.leaves.where((l) => l.status == 'Pending').length;
              int pendingPayrolls =
                  payments.payments.where((p) => p.status == 'Pending').length;
              int pendingClaims =
                  claims.claims.where((c) => c.status == 'Pending').length;
              int totalPending = pendingLeaves + pendingPayrolls + pendingClaims;

              return IconButton(
                icon: totalPending > 0
                    ? Badge(
                        label: Text(totalPending.toString()),
                        backgroundColor: Colors.redAccent,
                        child: const Icon(
                            Icons.notifications_none_rounded, size: 26),
                      )
                    : const Icon(Icons.notifications_none_rounded, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Back to Dashboard',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : RefreshIndicator(
              color: _primaryBlue,
              onRefresh: _loadAdminUsers,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Page header ──────────────────────────────────
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Admin List 👤',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'All registered administrators',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Stats + Sort row ─────────────────────────────
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _primaryBlue.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.groups_rounded,
                                        size: 18, color: _primaryBlue),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${filteredAdmins.length} Admin${filteredAdmins.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _primaryBlue),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _isAscending = !_isAscending),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isAscending
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        size: 16,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('A–Z',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E293B))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ── Search bar ───────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search by name...',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade400),
                                prefixIcon: Icon(Icons.search_rounded,
                                    color: _primaryBlue),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // ── List ─────────────────────────────────────────────────
                  filteredAdmins.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_search_rounded,
                                    size: 56, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No admins found',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final admin = filteredAdmins[index];
                                return GestureDetector(
                                  onTap: () => _showAdminDetail(admin),
                                  child: Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        radius: 24,
                                        backgroundColor:
                                            _primaryBlue.withOpacity(0.12),
                                        backgroundImage: (admin.filepath !=
                                                    null &&
                                                admin.filepath!.isNotEmpty)
                                            ? NetworkImage(
                                                'https://devcms.com.my/charmsAPI/public/storage/${admin.filepath}')
                                            : null,
                                        child: (admin.filepath == null ||
                                                admin.filepath!.isEmpty)
                                            ? Icon(Icons.person_rounded,
                                                color: _primaryBlue)
                                            : null,
                                      ),
                                      title: Text(
                                        _getDisplayName(admin),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4),
                                        child: Text(
                                          admin.email,
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.10),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Active',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.green),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: filteredAdmins.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}