import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRscreens/admin/register_staff_screen.dart';
import 'package:charms/HRscreens/admin/staff_details_screen.dart';
import 'package:charms/HRwidgets/admin/hr_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  String _searchQuery    = '';
  bool _isAscending      = true;
  int _selectedTabIndex  = 0;
  bool _isLoading        = true;
  String? _deptFilter;   // ✅ NEW — null = All

  final Color bgColor     = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  // ✅ NEW — departments list
  static const _departments = ['Marine Biologist', 'Taaras'];

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

  Future<void> _navigateToStaffDetails(Staff staff) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StaffDetailsScreen(staff: staff)),
    );
    if (result == true) {
      if (!mounted) return;
      await context.read<Staffs>().fetchStaff();
    }
  }

  List<Staff> _getFilteredStaff(List<Staff> staffList) {
    return staffList.where((staff) {
      final matchesSearch =
          '${staff.firstname} ${staff.lastname} ${staff.staffId}'
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // ✅ Department filter
      final matchesDept = _deptFilter == null ||
          (_deptFilter == 'General'
              ? (staff.department == null || staff.department!.isEmpty)
              : staff.department == _deptFilter);

      return matchesSearch && matchesDept;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = context.watch<Staffs>();
    final staffList     = staffProvider.getStaffByCategory(_selectedTabIndex + 1);
    final filteredStaff = _getFilteredStaff(staffList);

    filteredStaff.sort((a, b) => _isAscending
        ? a.firstname.compareTo(b.firstname)
        : b.firstname.compareTo(a.firstname));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: HRAppBar(
          title: 'MANAGE STAFF',
          bottomHeight: 48,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
                _searchQuery      = '';
                _deptFilter       = null; // ✅ reset dept filter on tab change
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          Row(
                            children: [
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
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RegisterStaffScreen()),
                                  );
                                  if (result == true) await _loadStaffData();
                                },
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text('Add Staff',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Department sub-filter chips ✅ NEW ────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // "All" chip
                            _deptChip(label: 'All', isActive: _deptFilter == null,
                                onTap: () => setState(() => _deptFilter = null)),
                            // "General" chip
                            _deptChip(label: 'General', isActive: _deptFilter == 'General',
                                onTap: () => setState(() => _deptFilter = 'General')),
                            // Dynamic department chips
                            ..._departments.map((dept) => _deptChip(
                                  label: dept,
                                  isActive: _deptFilter == dept,
                                  onTap: () => setState(() => _deptFilter = dept),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Search ───────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Staff List ───────────────────────────────────────────
                    Expanded(
                      child: filteredStaff.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline_rounded,
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
                                  onTap: () => _navigateToStaffDetails(staff),
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

  // ── Department filter chip ─────────────────────────────────────────────────
  Widget _deptChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? primaryBlue : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : Colors.grey.shade600)),
      ),
    );
  }
}

// ── Staff Tile — now shows department badge ────────────────────────────────────
class StaffListTile extends StatelessWidget {
  final Staff staff;
  final VoidCallback onTap;

  const StaffListTile({super.key, required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDept = staff.department != null && staff.department!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue.withOpacity(0.1),
          backgroundImage: (staff.filepath != null && staff.filepath!.isNotEmpty)
              ? NetworkImage(
                  'https://devcms.com.my/charmsAPI/public/storage/${staff.filepath}')
              : null,
          child: (staff.filepath == null || staff.filepath!.isEmpty)
              ? const Icon(Icons.person_rounded, size: 24, color: Colors.blue)
              : null,
        ),
        title: Text(
          '${staff.firstname} ${staff.lastname}',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155)),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID: ${staff.staffId} • ${staff.occupation.isNotEmpty ? staff.occupation : '—'}',
                style: TextStyle(
                    color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              // ✅ Department badge
              if (hasDept) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    staff.department!,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.blue),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }
}