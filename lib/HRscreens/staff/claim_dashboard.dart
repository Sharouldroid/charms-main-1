import 'package:charms/HRmodels/claim.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/HRscreens/staff/apply_claim_screen.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/payroll_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRscreens/staff/staff_notification_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
import 'package:charms/HRwidgets/staff/proof_attachment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';
import 'package:charms/utils/logout_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClaimDashboardScreen extends StatefulWidget {
  final String username;
  final int staffId;

  const ClaimDashboardScreen({
    super.key,
    required this.username,
    required this.staffId,
  });

  @override
  State<ClaimDashboardScreen> createState() => _ClaimDashboardScreenState();
}

class _ClaimDashboardScreenState extends State<ClaimDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 3;
  bool _processing   = false;

  DateTime? _fromDate;
  DateTime? _toDate;
  String _activeChip = 'All';

  final Color staffPrimary    = const Color(0xFF4F46E5);
  final Color staffBg         = const Color(0xFFF8FAFC);
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  bool _isProfileIncomplete(BuildContext context) {
    try {
      final auth   = context.read<hr_auth.Auth>();
      final staffs = context.read<Staffs>();
      final Staff staff = staffs.staffList.firstWhere(
        (s) => s.username == auth.username,
        orElse: () => throw Exception('not found'),
      );
      return staff.idNum.isEmpty ||
          staff.phone.isEmpty ||
          staff.nationality.isEmpty ||
          staff.religion.isEmpty ||
          staff.address1.isEmpty ||
          staff.city.isEmpty ||
          staff.state.isEmpty ||
          staff.country.isEmpty ||
          staff.emergencyName.isEmpty ||
          staff.emergencyPhone.isEmpty ||
          staff.dob.isEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClaimData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchClaimData() async =>
      context.read<Claims>().getClaimByStaffId(widget.staffId);

  Future<void> _logout() async => LogoutHelper.fullLogout(context);

  // ✅ Same helper as staff_dashboard_screen
  Future<Map<String, Set<String>>> _loadDismissedIds(int staffId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'leaves':    (prefs.getStringList('dismissed_leaves_$staffId')    ?? []).toSet(),
        'claims':    (prefs.getStringList('dismissed_claims_$staffId')    ?? []).toSet(),
        'schedules': (prefs.getStringList('dismissed_schedules_$staffId') ?? []).toSet(),
        'exchanges': (prefs.getStringList('dismissed_exchanges_$staffId') ?? []).toSet(),
      };
    } catch (_) {
      return {'leaves': {}, 'claims': {}, 'schedules': {}, 'exchanges': {}};
    }
  }

  List<Claim> _applyDateFilter(List<Claim> claims) {
    if (_fromDate == null && _toDate == null) return claims;
    return claims.where((c) {
      final d = c.claimDate;
      if (_fromDate != null) {
        final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        if (d.isBefore(from)) return false;
      }
      if (_toDate != null) {
        final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
        if (d.isAfter(to)) return false;
      }
      return true;
    }).toList();
  }

  void _applyQuickChip(String chip) {
    final now = DateTime.now();
    setState(() {
      _activeChip = chip;
      switch (chip) {
        case 'This Month':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate   = DateTime(now.year, now.month + 1, 0);
          break;
        case 'Last Month':
          final last = DateTime(now.year, now.month - 1);
          _fromDate  = DateTime(last.year, last.month, 1);
          _toDate    = DateTime(now.year, now.month, 0);
          break;
        case 'This Year':
          _fromDate = DateTime(now.year, 1, 1);
          _toDate   = DateTime(now.year, 12, 31);
          break;
        default:
          _fromDate = null;
          _toDate   = null;
      }
    });
  }

  Future<void> _pickFromDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
                primary: staffPrimary,
                onPrimary: Colors.white,
                onSurface: const Color(0xFF1E293B))),
        child: child!,
      ),
    );
    if (p != null) {
      setState(() {
        _fromDate   = p;
        _activeChip = 'Custom';
        if (_toDate != null && _toDate!.isBefore(p)) _toDate = p;
      });
    }
  }

  Future<void> _pickToDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
                primary: staffPrimary,
                onPrimary: Colors.white,
                onSurface: const Color(0xFF1E293B))),
        child: child!,
      ),
    );
    if (p != null) setState(() { _toDate = p; _activeChip = 'Custom'; });
  }

  Future<void> _deleteClaim(Claim claim) async {
    if (_processing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Claim',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to cancel this claim request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep It',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _processing = true);
    try {
      await Provider.of<Claims>(context, listen: false)
          .deleteClaim(claim.claimId);
      await _fetchClaimData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Claim request cancelled successfully'),
          backgroundColor: Colors.teal));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to cancel claim: $e'),
          backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) =>
                StaffDashboardScreen(username: widget.username)));
        break;
      case 1:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => LeaveDashboardScreen(
                username: widget.username, staffId: widget.staffId)));
        break;
      case 2:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) =>
                PayrollDashboardScreen(username: widget.username)));
        break;
      case 3:
        return;
      case 4:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const StaffMySelfScreen()));
        break;
    }
  }

  bool _hasProof(Claim c) =>
      (c.proofFileUrl?.trim().isNotEmpty ?? false) ||
      (c.proofFilePath?.trim().isNotEmpty ?? false) ||
      (c.proofFile?.isNotEmpty ?? false) ||
      (c.proofFileName?.trim().isNotEmpty ?? false);

  void _showClaimDetails(Claim claim) {
    final hasProof = _hasProof(claim);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Claim Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Claim ID', claim.claimId.toString()),
              _detailRow('Type', claim.claimType),
              _detailRow('Amount', 'RM ${claim.amount.toStringAsFixed(2)}',
                  isHighlight: true),
              _detailRow('Date', claim.claimDate.toString().split(' ')[0]),
              _detailRow('Status', claim.status),
              const SizedBox(height: 8),
              const Text('Description:',
                  style: TextStyle(color: Colors.grey, fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(claim.description,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              if (hasProof) ...[
                Text('Attachment: ${claim.proofFileName ?? 'Proof File'}',
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                ProofAttachmentViewer(
                  fileUrl:  claim.proofFileUrl,
                  fileName: claim.proofFileName,
                  fileType: claim.proofFileType,
                ),
              ] else
                Row(children: [
                  Icon(Icons.attachment_rounded, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text('No proof attached.',
                      style: TextStyle(color: Colors.grey.shade500)),
                ]),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: staffPrimary, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 80,
          child: Text('$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                  color: isHighlight ? staffPrimary : const Color(0xFF334155))),
        ),
      ]),
    );
  }

  Widget _buildFilterPanel() {
    final df       = DateFormat('dd MMM yyyy');
    final chips    = ['All', 'This Month', 'Last Month', 'This Year'];
    final isCustom = _fromDate != null || _toDate != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: staffCardBorder),
      ),
      child: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips.map((chip) {
              final isActive = _activeChip == chip;
              return GestureDetector(
                onTap: () => _applyQuickChip(chip),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? staffPrimary : staffPrimary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isActive ? staffPrimary : staffPrimary.withOpacity(0.2)),
                  ),
                  child: Text(chip,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : staffPrimary)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickFromDate,
              child: _datePill(
                  label: _fromDate != null ? df.format(_fromDate!) : 'From date',
                  active: _fromDate != null),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('→',
                style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickToDate,
              child: _datePill(
                  label: _toDate != null ? df.format(_toDate!) : 'To date',
                  active: _toDate != null),
            ),
          ),
          if (isCustom) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _applyQuickChip('All'),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
              ),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _datePill({required String label, required bool active}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? staffPrimary.withOpacity(0.07) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? staffPrimary.withOpacity(0.4) : Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size: 13, color: active ? staffPrimary : Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: active ? staffPrimary : Colors.grey),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _buildClaimCard(Claim claim, {bool showDelete = false}) {
    Color statusColor   = Colors.orange;
    Color statusBgColor = Colors.orange.withOpacity(0.1);
    IconData statusIcon = Icons.pending_actions_rounded;
    if (claim.status == 'Approved') {
      statusColor   = Colors.teal;
      statusBgColor = Colors.teal.withOpacity(0.1);
      statusIcon    = Icons.check_circle_rounded;
    } else if (claim.status == 'Rejected') {
      statusColor   = Colors.redAccent;
      statusBgColor = Colors.redAccent.withOpacity(0.1);
      statusIcon    = Icons.cancel_rounded;
    }
    final hasProof = _hasProof(claim);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: staffCardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showClaimDetails(claim),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.request_quote_rounded,
                    size: 24, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(claim.claimType,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text('RM ${claim.amount.toStringAsFixed(2)}',
                      style: TextStyle(color: staffPrimary, fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(claim.claimDate.toString().split(' ')[0],
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusBgColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(claim.status,
                          style: TextStyle(color: statusColor, fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  if (claim.status == 'Rejected' &&
                      claim.rejectionReason != null &&
                      claim.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Rejection Reason',
                                style: TextStyle(color: Colors.redAccent,
                                    fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(claim.rejectionReason!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                          ]),
                        ),
                      ]),
                    ),
                  ],
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (showDelete)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10)),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      tooltip: 'Cancel Claim',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      onPressed: _processing ? null : () => _deleteClaim(claim),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                      color: staffPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10)),
                  child: IconButton(
                    icon: Icon(hasProof ? Icons.attachment_rounded : Icons.visibility_rounded,
                        color: staffPrimary, size: 20),
                    tooltip: 'View Details',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: () => _showClaimDetails(claim),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildClaimList(List<Claim> claims, {bool showDelete = false}) {
    final filtered = _applyDateFilter(claims);
    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            (_fromDate != null || _toDate != null)
                ? 'No records for selected period'
                : 'No claims found',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          if (_fromDate != null || _toDate != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: () => _applyQuickChip('All'),
                child: const Text('Clear filter')),
          ],
        ]),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _buildClaimCard(filtered[i], showDelete: showDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: staffBg,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: const Text('MY CLAIMS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        backgroundColor: staffPrimary,
        centerTitle: true,
        actions: [
          // ✅ FIXED bell badge
          Consumer4<Leaves, Claims, Schedules, ScheduleExchanges>(
            builder: (context, leaves, claims, schedules, exchanges, child) {
              return FutureBuilder<Map<String, Set<String>>>(
                future: _loadDismissedIds(widget.staffId),
                builder: (context, snapshot) {
                  final dismissed = snapshot.data ?? {
                    'leaves': <String>{}, 'claims': <String>{},
                    'schedules': <String>{}, 'exchanges': <String>{},
                  };
                  final dl = dismissed['leaves']!;
                  final dc = dismissed['claims']!;
                  final ds = dismissed['schedules']!;
                  final de = dismissed['exchanges']!;

                  final total =
                      leaves.leaves.where((l) => l.staffId == widget.staffId &&
                          l.status != 'Pending' && !dl.contains(l.leaveId.toString())).length +
                      claims.claims.where((c) => c.staffId == widget.staffId &&
                          c.status != 'Pending' && !dc.contains(c.claimId.toString())).length +
                      schedules.schedules.where((s) => s.staffId == widget.staffId &&
                          !ds.contains(s.schedId.toString())).length +
                      exchanges.exchanges.where((e) => e.targetId == widget.staffId &&
                          e.status == 0 && !de.contains(e.exchangeId.toString())).length +
                      exchanges.exchanges.where((e) => e.requesterId == widget.staffId &&
                          e.status != 0 && !de.contains(e.exchangeId.toString())).length;

                  return IconButton(
                    icon: total > 0
                        ? Badge(label: Text(total.toString()),
                            backgroundColor: Colors.redAccent,
                            child: const Icon(Icons.notifications_active_rounded))
                        : const Icon(Icons.notifications_none_rounded),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => StaffNotificationScreen(
                              staffId: widget.staffId)));
                      if (mounted) setState(() {});
                    },
                  );
                },
              );
            },
          ),
          IconButton(
              icon: const Icon(Icons.logout_rounded), onPressed: _logout),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(child: Text('Applied',  style: TextStyle(color: Colors.white))),
            Tab(child: Text('Approved', style: TextStyle(color: Colors.white))),
            Tab(child: Text('Rejected', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Consumer<Claims>(
        builder: (_, claimsData, __) {
          final pending  = claimsData.claims.where((c) => c.status == 'Pending').toList();
          final approved = claimsData.claims.where((c) => c.status == 'Approved').toList();
          final rejected = claimsData.claims.where((c) => c.status == 'Rejected').toList();
          return Column(children: [
            _buildFilterPanel(),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildClaimList(pending,  showDelete: true),
                  _buildClaimList(approved),
                  _buildClaimList(rejected),
                ],
              ),
            ),
          ]);
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final submitted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => ApplyClaimScreen(staffId: widget.staffId)),
            );
            if (submitted == true) {
              await _fetchClaimData();
              _tabController.animateTo(0);
            }
          },
          backgroundColor: staffPrimary,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Apply Claim',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex: _selectedIndex,
        onItemTapped:  _onItemTapped,
        showMyselfDot: _isProfileIncomplete(context),
      ),
    );
  }
}