import 'package:charms/HRmodels/payment.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/payments.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRscreens/staff/claim_dashboard.dart';
import 'package:charms/HRscreens/staff/leave_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_myself_screen.dart';
import 'package:charms/HRscreens/staff/staff_notification_screen.dart';
import 'package:charms/HRscreens/staff/staff_payroll_details_screen.dart';
import 'package:charms/HRwidgets/staff/bottom_nav_staff.dart';
//import 'package:charms/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:charms/providers/auth.dart' as app_auth;
//import 'package:charms/screens/auth_screen.dart';
import 'package:charms/utils/logout_helper.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';

class PayrollDashboardScreen extends StatefulWidget {
  final String username;

  const PayrollDashboardScreen({
    super.key,
    required this.username,
  });

  @override
  _PayrollDashboardScreenState createState() => _PayrollDashboardScreenState();
}

class _PayrollDashboardScreenState extends State<PayrollDashboardScreen> {
  int selectedYear = DateTime.now().year;
  bool _isLoading = true;
  List<Payment> _monthlyPayments = [];
  Staff? _currentStaff;
  int _selectedIndex = 2;

  // ── Matches StaffDashboardScreen palette ─────────────────────────────────────
  final Color staffPrimary = const Color(0xFF4F46E5);
  final Color staffBg = const Color(0xFFF8FAFC);
  final Color staffCardBorder = const Color(0xFFE2E8F0);

  static const List<String> months = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];

  // Short month labels for the card
  static const List<String> monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _loadPayrollData();
  }

  Future<void> _loadPayrollData() async {
    try {
      final staffsProvider = context.read<Staffs>();
      final leavesProvider = context.read<Leaves>();
      final claimsProvider = context.read<Claims>();

      await Future.wait([
        staffsProvider.fetchStaff(),
        leavesProvider.fetchLeaves(),
        claimsProvider.fetchClaims(),
      ]);

      final staffList = staffsProvider.staffList;
      if (staffList.isNotEmpty) {
        _currentStaff = staffList.firstWhere(
          (staff) => staff.username == widget.username,
          orElse: () => throw Exception('Staff not found'),
        );
        await _fetchPaymentsForYear();
      }
    } catch (error) {
      debugPrint('Error loading payroll data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load payroll data: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPaymentsForYear() async {
    final paymentsProvider = context.read<Payments>();
    try {
      await paymentsProvider.fetchPaymentsByYear(selectedYear);
      if (mounted) {
        setState(() {
          _monthlyPayments = paymentsProvider.payments
              .where((payment) =>
                  payment.staffId == _currentStaff?.staffId &&
                  payment.workDate.year == selectedYear &&
                  payment.status == 'published')
              .toList();
        });
      }
    } catch (error) {
      debugPrint('Error fetching payments: $error');
    }
  }

  void _viewPayslip(String monthName) {
    try {
      final monthIndex = months.indexOf(monthName) + 1;
      final payment = _monthlyPayments.firstWhere(
        (p) => p.workDate.month == monthIndex,
        orElse: () => throw Exception('Payment not found'),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StaffPayrollDetailsScreen(
            month: monthName,
            year: selectedYear,
            staffId: _currentStaff?.staffId.toString() ?? '',
            staffName:
                '${_currentStaff?.firstname} ${_currentStaff?.lastname}',
            workingDays: '22',
            basicPay: payment.basicPay,
            totalBonus: payment.totalBonus,
            totalDeduction: payment.totalDeduction,
            totalSalary: payment.totalSalary,
            staffCategory:  _currentStaff?.category ?? 1,
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payslip data not available for $monthName')),
      );
    }
  }

  Future<void> _logout() async {
  await LogoutHelper.fullLogout(context);
}

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = StaffDashboardScreen(username: widget.username);
        break;
      case 1:
        nextScreen = LeaveDashboardScreen(
          username: widget.username,
          staffId: _currentStaff?.staffId ?? 0,
        );
        break;
      case 2:
        return;
      case 3:
        nextScreen = ClaimDashboardScreen(
          username: widget.username,
          staffId: _currentStaff?.staffId ?? 0,
        );
        break;
      case 4:
        nextScreen = StaffMySelfScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: staffBg,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'STAFF PORTAL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: staffPrimary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        actions: [
          // ── Notification badge — same logic as StaffDashboard ────────────
          Consumer4<Leaves, Claims, Schedules, ScheduleExchanges>(
            builder: (context, leaves, claims, schedules, exchanges, child) {
              int staffId = _currentStaff?.staffId ?? 0;

              int resolvedLeaves = leaves.leaves
                  .where((l) => l.staffId == staffId && l.status != 'Pending')
                  .length;

              int resolvedClaims = claims.claims
                  .where((c) => c.staffId == staffId && c.status != 'Pending')
                  .length;

              int assignedSchedules = schedules.schedules
                  .where((s) => s.staffId == staffId)
                  .length;

              int incomingExchanges = exchanges.exchanges
                  .where((e) => e.targetId == staffId && e.status == 0)
                  .length;

              int myExchangeUpdates = exchanges.exchanges
                  .where((e) => e.requesterId == staffId && e.status != 0)
                  .length;

              int totalNotifications = resolvedLeaves + resolvedClaims +
                  assignedSchedules + incomingExchanges + myExchangeUpdates;

              return IconButton(
                icon: totalNotifications > 0
                    ? Badge(
                        label: Text(totalNotifications.toString()),
                        backgroundColor: Colors.redAccent,
                        child: const Icon(Icons.notifications_active_rounded),
                      )
                    : const Icon(Icons.notifications_none_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffNotificationScreen(
                        staffId: staffId,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Back to Login',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: staffPrimary))
          : Column(
              children: [
                // ── Header banner — mirrors StaffDashboard ───────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                      top: 20, bottom: 24, left: 24, right: 24),
                  decoration: BoxDecoration(
                    color: staffPrimary,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Payroll 💳',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ── Year picker inside header ─────────────────────
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 16, color: Colors.indigo.shade200),
                          const SizedBox(width: 6),
                          Text(
                            'Showing payslips for',
                            style: TextStyle(
                              color: Colors.indigo.shade100,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _YearPicker(
                            selectedYear: selectedYear,
                            onChanged: (year) async {
                              setState(() {
                                selectedYear = year;
                                _isLoading = true;
                              });
                              await _fetchPaymentsForYear();
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Grid section ─────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Monthly Payslips',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 100),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.9,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: months.length,
                            itemBuilder: (context, index) {
                              final monthName = months[index];
                              final shortName = monthsShort[index];
                              final monthIndex = index + 1;
                              final hasPayslip = _monthlyPayments.any(
                                (p) =>
                                    p.workDate.month == monthIndex &&
                                    p.workDate.year == selectedYear,
                              );

                              return _MonthCard(
                                shortName: shortName,
                                fullName: monthName,
                                hasPayslip: hasPayslip,
                                staffPrimary: staffPrimary,
                                cardBorder: staffCardBorder,
                                onTap: hasPayslip
                                    ? () => _viewPayslip(monthName)
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavStaff(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// ── Year picker pill widget ───────────────────────────────────────────────────
class _YearPicker extends StatelessWidget {
  final int selectedYear;
  final ValueChanged<int> onChanged;

  const _YearPicker({required this.selectedYear, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedYear,
          dropdownColor: const Color(0xFF4F46E5),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700),
          icon: const Icon(Icons.expand_more_rounded,
              color: Colors.white, size: 18),
          items: List.generate(5, (i) => DateTime.now().year - i)
              .map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  ))
              .toList(),
          onChanged: (year) {
            if (year != null) onChanged(year);
          },
        ),
      ),
    );
  }
}

// ── Month card widget ─────────────────────────────────────────────────────────
class _MonthCard extends StatelessWidget {
  final String shortName;
  final String fullName;
  final bool hasPayslip;
  final Color staffPrimary;
  final Color cardBorder;
  final VoidCallback? onTap;

  const _MonthCard({
    required this.shortName,
    required this.fullName,
    required this.hasPayslip,
    required this.staffPrimary,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasPayslip ? staffPrimary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPayslip ? staffPrimary.withOpacity(0.35) : cardBorder,
            width: hasPayslip ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Month label ────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasPayslip
                    ? staffPrimary.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                shortName.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: hasPayslip
                      ? staffPrimary
                      : Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Status icon ────────────────────────────────────────────
            Icon(
              hasPayslip
                  ? Icons.description_rounded
                  : Icons.remove_circle_outline_rounded,
              size: 26,
              color: hasPayslip ? staffPrimary : Colors.grey.shade300,
            ),
            const SizedBox(height: 6),

            // ── Status label ───────────────────────────────────────────
            Text(
              hasPayslip ? 'View' : 'N/A',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: hasPayslip
                    ? staffPrimary
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}