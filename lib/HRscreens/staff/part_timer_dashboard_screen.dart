import 'package:charms/HRmodels/schedule.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/payments.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/HRscreens/staff/staff_schedule_details_screen.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/utils/logout_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PartTimerDashboardScreen extends StatefulWidget {
  final String username;
  const PartTimerDashboardScreen({super.key, required this.username});

  @override
  State<PartTimerDashboardScreen> createState() =>
      _PartTimerDashboardScreenState();
}

class _PartTimerDashboardScreenState extends State<PartTimerDashboardScreen> {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color _primary   = Color(0xFFF97316); // orange — distinct from staff blue
  static const Color _bg        = Color(0xFFFFF7ED);
  static const Color _cardBorder = Color(0xFFFFE4C4);

  Staff?          _currentStaff;
  List<Schedule>  _schedules   = [];
  List<Map<String, dynamic>> _payments = [];
  bool            _isLoading   = true;
  DateTime?       _lastLogin;
  bool            _mounted     = true;

  // ── Location helpers (same as rest of app) ────────────────────────────────
  static String _locationName(int loc) {
    switch (loc) {
      case 1: return 'Chagar Hutang';
      case 2: return 'Turtle Lab';
      case 3: return 'UMT';
      default: return 'Unknown';
    }
  }

  String _monthName(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _load() async {
    if (!_mounted) return;
    try {
      final staffsProvider   = Provider.of<Staffs>(context, listen: false);
      final schedProv        = Provider.of<Schedules>(context, listen: false);
      final payProv          = Provider.of<Payments>(context, listen: false);
      final auth             = Provider.of<hr_auth.Auth>(context, listen: false);

      await staffsProvider.fetchStaff();

      final staffList = staffsProvider.staffList;
      if (staffList.isNotEmpty) {
        _currentStaff = staffList.firstWhere(
          (s) => s.username == auth.username,
          orElse: () => throw Exception('Staff not found'),
        );

        // Fetch schedules
        final all = await schedProv.fetchSchedulesByStaffId(_currentStaff!.staffId);
        final cutoff = DateTime.now().subtract(const Duration(hours: 24));

        // Fetch payments for this year
        await payProv.fetchPaymentsByYear(DateTime.now().year);
        final myPayments = payProv.payments
            .where((p) => p.staffId == _currentStaff!.staffId)
            .toList();

        if (_mounted) {
          setState(() {
            _schedules = all
                .where((s) => s.workDate.isAfter(cutoff))
                .toList()
              ..sort((a, b) => a.workDate.compareTo(b.workDate));
            _payments  = myPayments
                .map((p) => {
                      'date':   p.workDate,
                      'amount': p.totalSalary,
                      'status': p.status,
                    })
                .toList()
              ..sort((a, b) =>
                  (b['date'] as DateTime).compareTo(a['date'] as DateTime));
            _lastLogin = DateTime.now();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('PartTimer load error: $e');
      if (_mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async => LogoutHelper.fullLogout(context);

  // ── Total earned this month ────────────────────────────────────────────────
  double get _earnedThisMonth {
    final now = DateTime.now();
    return _payments
        .where((p) {
          final d = p['date'] as DateTime;
          return d.month == now.month && d.year == now.year;
        })
        .fold(0.0, (sum, p) => sum + (p['amount'] as double));
  }

  // ── Total days worked this month ──────────────────────────────────────────
  int get _daysWorkedThisMonth {
    final now = DateTime.now();
    return _payments
        .where((p) {
          final d = p['date'] as DateTime;
          return d.month == now.month && d.year == now.year;
        })
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
            appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: _primary,
        toolbarHeight: 120,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row with title and icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PART TIMER PORTAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 24),
                      tooltip: 'My Profile',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffMySelfScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 24),
                      tooltip: 'Logout',
                      onPressed: _logout,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom row with greeting and last login
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   'Hello, ${_currentStaff != null ? _currentStaff!.firstname : widget.username}!',
                //   style: const TextStyle(
                //     color: Colors.white,
                //     fontSize: 24,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                const SizedBox(height: 4),
                if (_lastLogin != null)
                  Row(
                    children: [
                      const SizedBox(width: 6),
                      Text(
                        'Last Login: ${DateFormat('dd MMM yyyy, hh:mm a').format(_lastLogin!)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const SizedBox(width: 6),
                      // Text(
                      //   'Part Timer',
                      //   style: TextStyle(
                      //     color: Colors.white.withOpacity(0.9),
                      //     fontSize: 12,
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(children: [

                  // ── Header banner ───────────────────────────────────────
                  _buildHeader(),

                  const SizedBox(height: 16),

                  // ── Stats row ───────────────────────────────────────────
                  _buildStatsRow(),

                  const SizedBox(height: 20),

                  // ── Upcoming schedules ──────────────────────────────────
                  _buildSectionTitle(
                      'Upcoming Shifts', Icons.calendar_today_rounded),
                  _schedules.isEmpty
                      ? _emptyState(
                          Icons.event_available_rounded,
                          'No upcoming shifts',
                          'Admin will assign shifts soon')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _schedules.length,
                          itemBuilder: (_, i) =>
                              _buildScheduleCard(_schedules[i]),
                        ),

                  const SizedBox(height: 20),

                  // ── Payment history ─────────────────────────────────────
                  _buildSectionTitle(
                      'Payment History', Icons.payments_rounded),
                  _payments.isEmpty
                      ? _emptyState(
                          Icons.receipt_long_rounded,
                          'No payments yet',
                          'Payments appear after you clock out')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _payments.length > 10
                              ? 10
                              : _payments.length,
                          itemBuilder: (_, i) =>
                              _buildPaymentCard(_payments[i]),
                        ),

                  const SizedBox(height: 40),
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
      padding: const EdgeInsets.only(
          top: 20, bottom: 28, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: (_currentStaff?.filepath != null &&
                    _currentStaff!.filepath!.isNotEmpty)
                ? NetworkImage(
                    'https://devcms.com.my/charmsAPI/public/storage/${_currentStaff!.filepath}')
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
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
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
            label: 'Earned This Month',
            value: 'RM ${_earnedThisMonth.toStringAsFixed(2)}',
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

  // ── Section title ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
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

    Color statusColor   = Colors.orange;
    String statusText   = '⏳ Pending';
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
              staffId: _currentStaff?.staffId ?? 0,
              scheduleId: s.schedId);
          if (!mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StaffScheduleDetailsScreen(
                location:         locationName,
                workDate:         s.workDate,
                assignedStaff:    [_currentStaff?.firstname ?? ''],
                startTime:        s.workStartTime.toString(),
                endTime:          s.workEndTime.toString(),
                startBreak:       s.breakStartTime.toString(),
                endBreak:         s.breakEndTime.toString(),
                status:           isClockedIn ? 'Clocked In' : 'Not clocked in',
                scheduleId:       s.schedId,
                staffId:          _currentStaff?.staffId ?? 0,
                acceptanceStatus: s.acceptanceStatus,
                staffNote:        s.staffNote,
                staffUsertype:    _currentStaff?.usertype ?? 7
              ),
            ),
          );
          if (result != null && result['refreshDashboard'] == true) {
            await _load();
          }
        },
        child: Row(children: [
          // Date block
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E0),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16)),
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
          // Content
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
    final date   = payment['date'] as DateTime;
    final amount = payment['amount'] as double;

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
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.payments_rounded,
              color: Colors.green, size: 20),
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
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Colors.green)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Paid',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.green)),
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