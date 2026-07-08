import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/payments.dart';
import 'package:charms/HRproviders/payment_claims.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/staff_documents.dart';
import 'package:charms/HRscreens/staff/part_timer_documents_screen.dart';
import 'package:charms/HRscreens/staff/part_timer_notification_screen.dart';
import 'package:charms/HRscreens/staff/part_timer_schedule_details_screen.dart';
//import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/utils/logout_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRwidgets/staff/hr_staff_theme.dart';

class PartTimerDashboardScreen extends StatefulWidget {
  final String username;
  const PartTimerDashboardScreen({super.key, required this.username});

  @override
  State<PartTimerDashboardScreen> createState() =>
      _PartTimerDashboardScreenState();
}

class _PartTimerDashboardScreenState extends State<PartTimerDashboardScreen> {
  static const Color _primary    = Color(0xFFF97316);
  static const Color _bg         = Color(0xFFFFF7ED);
  static const Color _cardBorder = Color(0xFFFFE4C4);

  Staff?                     _currentStaff;
  List<Schedule>             _schedules            = [];
  List<Map<String, dynamic>> _payments             = [];
  bool                       _isLoading            = true;
  bool                       _submitting           = false;
  DateTime?                  _lastLogin;
  int                        _unreadNotifications  = 0;
  Map<String, dynamic>       _dashboardData        = {};
  List<String>               _missingDocuments     = [];

  // ── Location helper ────────────────────────────────────────────────────────
  static String _locationName(int loc) {
    switch (loc) {
      case 1:  return 'Chagar Hutang';
      case 2:  return 'Turtle Lab';
      case 3:  return 'UMT';
      default: return 'Unknown';
    }
  }

  String _monthName(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m];
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    debugPrint('=== PartTimer _load() CALLED ===');

    if (!mounted) return;

    // Show loading indicator on every refresh
    setState(() => _isLoading = true);

    try {
      final staffsProv   = Provider.of<Staffs>(context, listen: false);
      final schedProv    = Provider.of<Schedules>(context, listen: false);
      final payProv      = Provider.of<Payments>(context, listen: false);
      final exchangeProv = Provider.of<ScheduleExchanges>(context, listen: false);
      final claimProv    = Provider.of<PaymentClaims>(context, listen: false);
      final docsProv     = Provider.of<StaffDocuments>(context, listen: false);

      // 1 — fetch staff list and find current user
      await staffsProv.fetchStaff();
      final staffList      = staffsProv.staffList;
      final widgetUsername = widget.username.trim().toLowerCase();

      final Staff? staff = staffList.cast<Staff?>().firstWhere(
        (s) => s?.username.trim().toLowerCase() == widgetUsername,
        orElse: () => null,
      );

      if (staff == null) {
        debugPrint('Staff not found for username: ${widget.username}');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      debugPrint('Staff found: ${staff.staffId} / ${staff.username}');

      // 2 — schedules (past 24 h cutoff)
      final allSchedules = await schedProv.fetchSchedulesByStaffId(staff.staffId);
      final cutoff       = DateTime.now().subtract(const Duration(hours: 24));
      final upcoming     = allSchedules
          .where((s) => s.workDate.isAfter(cutoff))
          .toList()
        ..sort((a, b) => a.workDate.compareTo(b.workDate));

      // 3 — payments (for payment history section)
      // Fetch payments for display — last 3 months only
      await payProv.fetchPaymentsByYear(DateTime.now().year);
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final myPayments = payProv.payments
          .where((p) =>
              p.staffId == staff.staffId &&
              p.workDate.isAfter(threeMonthsAgo))
          .toList();

      // 4 — unread exchange notifications
      await exchangeProv.fetchExchangesByStaff(staff.staffId);
      final unread = exchangeProv.exchanges
          .where((e) => e.targetId == staff.staffId && e.status == 0)
          .length;

      // 5 — payment claim dashboard (days worked, running total, claim status)
      final dashboard = await claimProv.fetchDashboard(staff.staffId);

      // 6 — required document upload status (Resume / IC / Bank Statement)
      await docsProv.fetchSubmissions(staff.staffId);
      final missingDocs = StaffDocuments.documentTypes
          .where((type) => docsProv.forType(type) == null)
          .toList();

      debugPrint('=== Dashboard API result ===');
      debugPrint('  keys            : ${dashboard.keys.toList()}');
      debugPrint('  days_worked     : ${dashboard['days_worked_this_month']}');
      debugPrint('  running_total   : ${dashboard['running_total_amount']}');
      debugPrint('  can_submit      : ${dashboard['can_submit_claim']}');
      debugPrint('  current_claim   : ${dashboard['current_claim']}');

      if (!mounted) return;

      setState(() {
        _currentStaff        = staff;
        _schedules           = upcoming;
        _payments            = myPayments
            .map((p) => {
                  'date':     p.workDate,
                  'amount':   p.totalSalary,
                  'status':   p.status,
                  'claim_id': null,
                })
            .toList()
          ..sort((a, b) =>
              (b['date'] as DateTime).compareTo(a['date'] as DateTime));
        _dashboardData       = dashboard;
        _lastLogin           = DateTime.now();
        _unreadNotifications = unread;
        _missingDocuments    = missingDocs;
        _isLoading           = false;
      });

      debugPrint('=== _load() COMPLETE — days: $_daysWorkedThisMonth, total: $_runningTotal ===');

    } catch (e, stack) {
      debugPrint('PartTimer _load() ERROR: $e');
      debugPrint('$stack');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Dashboard getters ──────────────────────────────────────────────────────
  int    get _daysWorkedThisMonth => _dashboardData['days_worked_this_month'] ?? 0;
  double get _runningTotal =>
      ((_dashboardData['running_total_amount'] ?? 0) as num).toDouble();
  bool   get _canSubmitClaim => _dashboardData['can_submit_claim'] == true;

  Map<String, dynamic>? get _currentClaim =>
      _dashboardData['current_claim'] as Map<String, dynamic>?;

  String get _claimStatus {
    if (_currentClaim == null) return 'Not Submitted';
    return _currentClaim!['status']?.toString() ?? 'Pending';
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout() async => LogoutHelper.fullLogout(context);

  // ── Submit claim ───────────────────────────────────────────────────────────
  Future<void> _submitClaim() async {
    if (_currentStaff == null || _submitting) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Payment Claim',
            style: TextStyle(fontWeight: FontWeight.bold)),
       content: Builder(builder: (context) {
  final draftDays = (_dashboardData['draft_days_unclaimed'] ?? 0) as int;
  final draftAmount = draftDays * _currentStaff!.dayRate;
  final alreadyClaimed = _daysWorkedThisMonth - draftDays;

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Submit claim for ${DateFormat('MMMM yyyy').format(DateTime.now())}?',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Unclaimed days:',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text('$draftDays day${draftDays > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Day rate:',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text('RM ${_currentStaff!.dayRate.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total to claim:',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                Text('RM ${draftAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.orange)),
              ],
            ),
          ],
        ),
      ),
      if (alreadyClaimed > 0) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.info_outline_rounded,
              size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$alreadyClaimed day${alreadyClaimed > 1 ? 's' : ''} already claimed separately.',
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey),
            ),
          ),
        ]),
      ],
    ],
  );
}),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);
    try {
      final claimProv = Provider.of<PaymentClaims>(context, listen: false);
      final now       = DateTime.now();
      final result    = await claimProv.submitClaim(
        staffId: _currentStaff!.staffId,
        month:   now.month,
        year:    now.year,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Claim submitted! Awaiting admin approval.'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Failed to submit claim'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showFullHistory() async {
  if (_currentStaff == null) return;

  final payProv = Provider.of<Payments>(context, listen: false);
  // Fetch current year + previous year for full history
  await payProv.fetchPaymentsByYear(DateTime.now().year);

  final allPayments = payProv.payments
      .where((p) => p.staffId == _currentStaff!.staffId)
      .toList()
    ..sort((a, b) => b.workDate.compareTo(a.workDate));

  if (!mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.history_rounded,
                    color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Full Payment History',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B))),
              const Spacer(),
              Text('${allPayments.length} records',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: allPayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No payment records',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: allPayments.length,
                    itemBuilder: (_, i) =>
                        _buildPaymentCard({
                          'date':     allPayments[i].workDate,
                          'amount':   allPayments[i].totalSalary,
                          'status':   allPayments[i].status,
                          'claim_id': null,
                        }),
                  ),
          ),
        ]),
      ),
    ),
  );
}
  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: StaffAppBar(
        title: 'PART TIMER PORTAL',
        backgroundColor: _primary,
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 80,
        roundedBottom: false,
        actions: [
              IconButton(
                icon: const Icon(Icons.folder_shared_rounded,
                    color: Colors.white, size: 24),
                tooltip: 'My Documents',
                onPressed: () {
                  if (_currentStaff == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartTimerDocumentsScreen(
                          staffId: _currentStaff!.staffId),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Stack(clipBehavior: Clip.none, children: [
                  const Icon(Icons.notifications_rounded,
                      color: Colors.white, size: 24),
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          _unreadNotifications > 99
                              ? '99+'
                              : '$_unreadNotifications',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ]),
                tooltip: 'Notifications',
                onPressed: () async {
                  if (_currentStaff == null) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartTimerNotificationScreen(
                          staffId: _currentStaff!.staffId),
                    ),
                  );
                  await _load();
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white, size: 24),
                tooltip: 'Logout',
                onPressed: _logout,
              ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(children: [
                  _buildHeader(),
                  StaffPageContainer(
                  child: Column(children: [
                  const SizedBox(height: 16),
                  if (_missingDocuments.isNotEmpty) ...[
                    _buildDocumentsAlertBanner(),
                    const SizedBox(height: 16),
                  ],
                  _buildStatsRow(),
                  const SizedBox(height: 12),
                  _buildClaimBanner(),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                      'Upcoming Shifts', Icons.calendar_today_rounded),
                  _schedules.isEmpty
                      ? _emptyState(
                          Icons.event_available_rounded,
                          'No upcoming shifts',
                          'Admin will assign shifts soon',
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _schedules.length,
                          itemBuilder: (_, i) =>
                              _buildScheduleCard(_schedules[i]),
                        ),
                  const SizedBox(height: 20),
                 Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.payments_rounded, color: _primary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text('Payment History',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B))),
                      const Spacer(),
                      // ✅ View All button
                      GestureDetector(
                        onTap: () => _showFullHistory(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('View All',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _primary)),
                        ),
                      ),
                    ]),
                  ),
                  _payments.isEmpty
                      ? _emptyState(
                          Icons.receipt_long_rounded,
                          'No payments yet',
                          'Payments appear after you clock out',
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount:
                              _payments.length > 10 ? 10 : _payments.length,
                          itemBuilder: (_, i) =>
                              _buildPaymentCard(_payments[i]),
                        ),
                  const SizedBox(height: 40),
                  ]),
                  ),
                ]),
              ),
            ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final name = _currentStaff != null
        ? '${_currentStaff!.firstname} ${_currentStaff!.lastname}'
        : widget.username;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.only(top: 20, bottom: 28, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage: (_currentStaff?.filepath != null &&
                    _currentStaff!.filepath!.isNotEmpty)
                ? NetworkImage(
                    'https://devcms.com.my/charmsAPI/public/storage/'
                    '${_currentStaff!.filepath}')
                : null,
            child: (_currentStaff?.filepath == null ||
                    _currentStaff!.filepath!.isEmpty)
                ? const Icon(Icons.person_rounded,
                    color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Hello, $name!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Icon(Icons.access_time_rounded,
                      size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Part Timer',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
        ]),
        if (_lastLogin != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.access_time_rounded,
                size: 13, color: Colors.orange.shade100),
            const SizedBox(width: 4),
            Text(
              'Last Login: ${DateFormat('dd MMM yyyy, hh:mm a').format(_lastLogin!)}',
              style: TextStyle(
                  color: Colors.orange.shade100,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ]),
        ],
        if (_currentStaff != null && _currentStaff!.dayRate > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.payments_rounded,
                  size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Day Rate: RM ${_currentStaff!.dayRate.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: _statCard(
            icon: Icons.calendar_today_rounded,
            label: 'Days This Month',
            value: '$_daysWorkedThisMonth',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.payments_rounded,
            label: 'Running Total',
            value: 'RM ${_runningTotal.toStringAsFixed(2)}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.event_note_rounded,
            label: 'Upcoming Shifts',
            value: '${_schedules.length}',
            color: _primary,
          ),
        ),
      ]),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── Documents alert banner ─────────────────────────────────────────────────
  Widget _buildDocumentsAlertBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Action Required: Upload Your Documents',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.red.shade800)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'Please upload the following before you continue: '
            '${_missingDocuments.join(', ')}.',
            style: TextStyle(fontSize: 12.5, color: Colors.red.shade700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (_currentStaff == null) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PartTimerDocumentsScreen(
                        staffId: _currentStaff!.staffId),
                  ),
                );
                await _load();
              },
              icon: const Icon(Icons.upload_rounded, size: 16),
              label: const Text('Upload Now'),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Claim banner ───────────────────────────────────────────────────────────
  Widget _buildClaimBanner() {
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());

    Color    bgColor;
    Color    borderColor;
    Color    textColor;
    IconData icon;
    String   statusLabel;

    switch (_claimStatus) {
      case 'Pending':
        bgColor     = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        textColor   = Colors.orange.shade800;
        icon        = Icons.pending_actions_rounded;
        statusLabel = 'Pending Approval';
        break;
      case 'Approved':
        bgColor     = Colors.teal.shade50;
        borderColor = Colors.teal.shade200;
        textColor   = Colors.teal.shade800;
        icon        = Icons.check_circle_rounded;
        statusLabel = 'Approved';
        break;
      case 'Rejected':
        bgColor     = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor   = Colors.red.shade800;
        icon        = Icons.cancel_rounded;
        statusLabel = 'Rejected';
        break;
      default:
        bgColor     = Colors.blue.shade50;
        borderColor = Colors.blue.shade200;
        textColor   = Colors.blue.shade800;
        icon        = Icons.assignment_rounded;
        statusLabel = 'Submitted';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text('$monthLabel Claim',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: textColor)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _claimStat('Days', '$_daysWorkedThisMonth', textColor),
            const SizedBox(width: 16),
            _claimStat(
                'Total', 'RM ${_runningTotal.toStringAsFixed(2)}', textColor),
          ]),
          if (_claimStatus == 'Rejected' &&
              _currentClaim?['rejection_reason'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _currentClaim!['rejection_reason'].toString(),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.redAccent),
                  ),
                ),
              ]),
            ),
          ],
          if (_canSubmitClaim) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitting ? null : _submitClaim,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label:
                    Text(_submitting ? 'Submitting...' : 'Submit Claim'),
              ),
            ),
          ],
          if (_claimStatus == 'Rejected') ...[
            const SizedBox(height: 8),
            Text(
              'Your work days have been reset. You can submit a new claim next cycle.',
              style: TextStyle(
                  fontSize: 11, color: textColor.withOpacity(0.7)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _claimStat(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500)),
      Text(value,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color)),
    ]);
  }

  // ── Section title ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B))),
      ]),
    );
  }

  // ── Schedule card ──────────────────────────────────────────────────────────
  Widget _buildScheduleCard(Schedule s) {
    final locationName = _locationName(s.workLocation);
    final dateObj      = s.workDate;

    Color  statusColor = Colors.orange;
    String statusText  = '⏳ Pending';
    if (s.acceptanceStatus == 1) {
      statusColor = Colors.green;
      statusText  = '✅ Accepted';
    } else if (s.acceptanceStatus == 2) {
      statusColor = Colors.red;
      statusText  = '❌ Not Accepted';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final attProv = Provider.of<Attendances>(context, listen: false);
          final isClockedIn = await attProv.checkAttendance(
            staffId:    _currentStaff?.staffId ?? 0,
            scheduleId: s.schedId,
          );
          if (!mounted) return;

          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (_) => PartTimerScheduleDetailsScreen(
                location:         locationName,
                workDate:         s.workDate,
                startTime:        s.workStartTime.toString(),
                endTime:          s.workEndTime.toString(),
                status:           isClockedIn ? 'Clocked In' : 'Not clocked in',
                scheduleId:       s.schedId,
                staffId:          _currentStaff?.staffId ?? 0,
                acceptanceStatus: s.acceptanceStatus,
                staffNote:        s.staffNote,
              ),
            ),
          );

          debugPrint('=== Back from ScheduleDetails, result: $result ===');

          // Always reload when returning from schedule details
          // regardless of result value — ensures dashboard is fresh
          await _load();
        },
        child: Row(children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E0),
              borderRadius: BorderRadius.only(
                topLeft:     Radius.circular(16),
                bottomLeft:  Radius.circular(16),
              ),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(_monthName(dateObj.month).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _primary)),
              Text('${dateObj.day}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _primary)),
            ]),
          ),
          Container(width: 1, height: 56, color: _cardBorder),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(locationName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time_rounded,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${s.workStartTime ?? '—'} – ${s.workEndTime ?? '—'}',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusText,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey.shade400),
          ),
        ]),
      ),
    );
  }

  // ── Payment card ───────────────────────────────────────────────────────────
  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final date   = payment['date']   as DateTime;
    final amount = payment['amount'] as double;
    final status = payment['status'] as String? ?? 'draft';

    Color  statusColor;
    String statusLabel;
    Color  statusBg;

    switch (status) {
      case 'published':
        statusColor = Colors.teal;
        statusBg    = Colors.teal.shade50;
        statusLabel = 'Approved';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusBg    = Colors.orange.shade50;
        statusLabel = 'Pending';
        break;
      default:
        statusColor = Colors.grey;
        statusBg    = Colors.grey.shade100;
        statusLabel = 'Draft';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.payments_rounded, color: statusColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(DateFormat('dd MMM yyyy (EEE)').format(date),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text('Day shift payment',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: statusColor)),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor)),
          ),
        ]),
      ]),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _emptyState(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade400)),
        ]),
      ),
    );
  }
}