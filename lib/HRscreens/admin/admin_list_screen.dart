import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/payments.dart';
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/admin/manage_staff_screen.dart';
import 'package:charms/HRscreens/admin/myself_screen.dart';
import 'package:charms/HRscreens/admin/notification_screen.dart';
import 'package:charms/HRscreens/admin/staff_details_screen.dart';
import 'package:charms/HRscreens/admin/staff_documents_admin_screen.dart';
import 'package:charms/HRwidgets/admin/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/utils/logout_helper.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/payment_claims.dart';
import 'package:charms/HRproviders/staff_documents.dart';
import 'package:charms/HRwidgets/admin/hr_theme.dart';
import 'package:intl/intl.dart';

class AdminListScreen extends StatefulWidget {
  final String username;
  const AdminListScreen({super.key, required this.username});

  @override
  _AdminListScreenState createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isAscending = true;
  int _selectedIndex = 2;
  Set<int> _activeFilters = {1, 2, 3};

  final Color _bgColor = const Color(0xFFF4F7FA);
  final Color _primaryBlue = const Color(0xFF2563EB);

  static const _categoryConfig = [
    {
      'label': 'SEATRU',
      'category': 1,
      'color': Color(0xFF2563EB),
      'icon': Icons.water,
    },
    {
      'label': 'CMS',
      'category': 2,
      'color': Color(0xFF16A34A),
      'icon': Icons.business,
    },
    {
      'label': 'Intern',
      'category': 3,
      'color': Color(0xFF9333EA),
      'icon': Icons.school,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await context
          .read<Staffs>()
          .fetchStaff()
          .timeout(const Duration(seconds: 12));
    } catch (error) {
      debugPrint('AdminList load error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load staff: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await LogoutHelper.fullLogout(context);
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

  String _getDisplayName(Staff staff) {
    final fullName = '${staff.firstname} ${staff.lastname}'.trim();
    return fullName.isNotEmpty ? fullName : staff.username;
  }

  List<Staff> _getFilteredByCategory(List<Staff> all, int category) {
    if (!_activeFilters.contains(category)) return [];
    return all.where((s) {
      final matchesCategory = s.category == category;
      final matchesSearch =
          '${s.firstname} ${s.lastname} ${s.username} ${s.staffId}'
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _navigateToStaffDetails(Staff staff) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StaffDetailsScreen(staff: staff)),
    );
    if (result == true && mounted) await _loadStaffData();
  }

  // ── Department tag widget ─────────────────────────────────────────────────────
  Widget _buildDepartmentTag(String? department) {
    final String label;
    final Color color;
    final IconData icon;

    if (department == 'Marine Biologist') {
      label = 'Marine Biologist';
      color = const Color(0xFF0891B2);
      icon  = Icons.water_rounded;
    } else if (department == 'Taaras') {
      label = 'Taaras';
      color = const Color(0xFFD97706);
      icon  = Icons.villa_rounded;
    } else {
      label = 'General';
      color = const Color(0xFF64748B);
      icon  = Icons.people_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Part Timer badge ──────────────────────────────────────────────────────────
  Widget _buildPartTimerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 11, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            'Part Timer',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _showStaffDetail(
      Staff staff, Color categoryColor, String categoryLabel) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: categoryColor.withOpacity(0.12),
              backgroundImage:
                  (staff.filepath != null && staff.filepath!.isNotEmpty)
                      ? NetworkImage(
                          'https://devcms.com.my/charmsAPI/public/storage/${staff.filepath}')
                      : null,
              child: (staff.filepath == null || staff.filepath!.isEmpty)
                  ? Icon(Icons.person, color: categoryColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDisplayName(staff),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categoryLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: categoryColor),
                        ),
                      ),
                      _buildDepartmentTag(staff.department),
                      if (staff.isPartTimer) _buildPartTimerBadge(), // ✅
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow(
                Icons.calendar_today_rounded,
                'Joined',
                staff.createdAt != null
                    ? DateFormat('dd MMM yyyy').format(staff.createdAt!)
                    : '—',
            ),
            const SizedBox(height: 10),
            _dialogRow(Icons.account_circle_rounded, 'Username',
                staff.username),
            const SizedBox(height: 10),
            _dialogRow(Icons.email_rounded, 'Email', staff.email),
            const SizedBox(height: 10),
            _dialogRow(Icons.work_rounded, 'Occupation',
                staff.occupation.isNotEmpty ? staff.occupation : '—'),
            const SizedBox(height: 10),
            _dialogRow(Icons.phone_rounded, 'Phone',
                staff.phone.isNotEmpty ? staff.phone : '—'),
            if (staff.isPartTimer) ...[
              const SizedBox(height: 10),
              _dialogRow(Icons.payments_rounded, 'Day Rate',
                  'RM ${staff.dayRate.toStringAsFixed(2)}'), // ✅
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _primaryBlue)),
          ),
          if (staff.isPartTimer)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.folder_shared_rounded, size: 16),
              label: const Text('Documents'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StaffDocumentsAdminScreen(
                      staffId: staff.staffId,
                      staffName: _getDisplayName(staff),
                    ),
                  ),
                );
              },
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Edit'),
            onPressed: () {
              Navigator.pop(context);
              _navigateToStaffDetails(staff);
            },
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = context.watch<Staffs>();
    final allStaff = staffProvider.staffList;

    final totalVisible = _activeFilters
        .map((cat) => _getFilteredByCategory(allStaff, cat).length)
        .fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true,
      appBar: HRAppBar(
        title: 'STAFF LIST',
        automaticallyImplyLeading: false,
        actions: [
          Consumer<PaymentClaims>(
            builder: (context, paymentClaims, _) {
              return Consumer<StaffDocuments>(
                builder: (context, staffDocuments, __) {
              return Consumer6<Leaves, Payments, Claims, ScheduleExchanges, Schedules, Staffs>(
            builder: (context, leaves, payments, claims, exchanges, schedules, staffs, child) {
              final pendingLeaves     = leaves.leaves.where((l) => l.status == 'Pending').length;
              final pendingPayrolls   = payments.payments.where((p) => p.status == 'Pending').length;
              final pendingClaims     = claims.claims.where((c) => c.status == 'Pending').length;
              final pendingExchanges  = exchanges.exchanges.where((e) => e.status == 1).length;
              final rejectedSchedules = schedules.schedules
                  .where((s) => s.acceptanceStatus == 2 && !s.hrDismissed)
                  .length;
              final pendingPaymentClaims = paymentClaims.pendingClaims.length;
              final unviewedDocStaff    = staffDocuments.unviewedStaffIds.length;

              final totalPending = pendingLeaves + pendingPayrolls +
                  pendingClaims + pendingExchanges + rejectedSchedules +
                  pendingPaymentClaims + unviewedDocStaff;

              return IconButton(
                icon: totalPending > 0
                    ? Badge(
                        label: Text(totalPending.toString()),
                        backgroundColor: Colors.redAccent,
                        child: const Icon(Icons.notifications_none_rounded, size: 26),
                      )
                    : const Icon(Icons.notifications_none_rounded, size: 26),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen())),
              );
            },
              );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : RefreshIndicator(
              color: _primaryBlue,
              onRefresh: _loadStaffData,
              child: HRPageContainer(
                child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [

                  // ── Search + Filter header ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Total count + Sort ──────────────────────────────
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.groups_rounded,
                                        size: 18, color: _primaryBlue),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$totalVisible Total Staff',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _primaryBlue),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _isAscending = !_isAscending),
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

                          // ── Search bar ──────────────────────────────────────
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
                                hintText: 'Search staff by name or ID...',
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w500),
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
                          const SizedBox(height: 12),

                          // ── Filter chips ────────────────────────────────────
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: 'All',
                                  isActive: _activeFilters.length == 3,
                                  color: _primaryBlue,
                                  onTap: () => setState(
                                      () => _activeFilters = {1, 2, 3}),
                                ),
                                ...(_categoryConfig.map((config) {
                                  final category = config['category'] as int;
                                  final label = config['label'] as String;
                                  final color = config['color'] as Color;
                                  final isActive =
                                      _activeFilters.contains(category);
                                  return _buildFilterChip(
                                    label: label,
                                    isActive: isActive,
                                    color: color,
                                    onTap: () {
                                      setState(() {
                                        if (isActive) {
                                          if (_activeFilters.length > 1) {
                                            _activeFilters.remove(category);
                                          }
                                        } else {
                                          _activeFilters.add(category);
                                        }
                                      });
                                    },
                                  );
                                })),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // ── Sections: SEATRU → CMS → Intern ──────────────────────
                  for (final config in _categoryConfig) ...[
                    if (_activeFilters.contains(config['category'] as int)) ...[
                      _buildSectionHeader(
                        label: config['label'] as String,
                        category: config['category'] as int,
                        color: config['color'] as Color,
                        icon: config['icon'] as IconData,
                        allStaff: allStaff,
                      ),
                      _buildSectionList(
                        allStaff: allStaff,
                        category: config['category'] as int,
                        color: config['color'] as Color,
                        label: config['label'] as String,
                      ),
                    ],
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // ── Filter chip ───────────────────────────────────────────────────────────────
  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String label,
    required int category,
    required Color color,
    required IconData icon,
    required List<Staff> allStaff,
  }) {
    final count = _getFilteredByCategory(allStaff, category).length;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section list ──────────────────────────────────────────────────────────────
  Widget _buildSectionList({
    required List<Staff> allStaff,
    required int category,
    required Color color,
    required String label,
  }) {
    final filtered = _getFilteredByCategory(allStaff, category);

    filtered.sort((a, b) => _isAscending
        ? _getDisplayName(a).compareTo(_getDisplayName(b))
        : _getDisplayName(b).compareTo(_getDisplayName(a)));

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded,
                    color: Colors.grey.shade300, size: 22),
                const SizedBox(width: 10),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No $label staff match "$_searchQuery"'
                      : 'No $label staff registered',
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final staff = filtered[index];
            return _buildStaffCard(staff, color, label);
          },
          childCount: filtered.length,
        ),
      ),
    );
  }

  // ── Staff card ────────────────────────────────────────────────────────────────
  Widget _buildStaffCard(Staff staff, Color color, String categoryLabel) {
    return GestureDetector(
      onTap: () => _showStaffDetail(staff, color, categoryLabel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.12),
            backgroundImage:
                (staff.filepath != null && staff.filepath!.isNotEmpty)
                    ? NetworkImage(
                        'https://devcms.com.my/charmsAPI/public/storage/${staff.filepath}')
                    : null,
            child: (staff.filepath == null || staff.filepath!.isEmpty)
                ? Icon(Icons.person_rounded, color: color)
                : null,
          ),
          title: Text(
            _getDisplayName(staff),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.occupation.isNotEmpty ? staff.occupation : '—',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),

                // ── Department + Part Timer badges ────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildDepartmentTag(staff.department),
                    if (staff.isPartTimer) _buildPartTimerBadge(), // ✅
                  ],
                ),

                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge_outlined,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'ID: ${staff.staffId}',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.phone_rounded,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      staff.phone.isNotEmpty ? staff.phone : '—',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey.shade400),
        ),
      ),
    );
  }
}