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
import 'package:charms/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PayrollDashboardScreen extends StatefulWidget {
  final String username;

  const PayrollDashboardScreen({
    super.key,
    required this.username,
  });

  @override
  _PayrollScreenState createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollDashboardScreen> {
  int selectedYear = DateTime.now().year;
  bool _isLoading = true;
  List<Payment> _monthlyPayments = [];
  Staff? _currentStaff;
  int _selectedIndex = 2;

  final List<String> months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
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

      // ✅ Fetch all data in parallel including leaves/claims for badge
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
    Navigator.of(context).pushNamedAndRemoveUntil(
      DashboardScreen.routeName,
      (route) => false,
    );
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
      appBar: AppBar(
        title: const Text('CHARMS STAFF',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        actions: [
          // ✅ Notification badge — same as dashboard
          Consumer3<Leaves, Claims, Schedules>(
            builder: (context, leaves, claims, schedules, child) {
              int staffId = _currentStaff?.staffId ?? 0;

              int resolvedLeaves = leaves.leaves
                  .where((l) =>
                      l.staffId == staffId && l.status != 'Pending')
                  .length;

              int resolvedClaims = claims.claims
                  .where((c) =>
                      c.staffId == staffId && c.status != 'Pending')
                  .length;

              int assignedSchedules = schedules.schedules
                  .where((s) => s.staffId == staffId)
                  .length;

              int totalNotifications =
                  resolvedLeaves + resolvedClaims + assignedSchedules;

              return IconButton(
                icon: totalNotifications > 0
                    ? Badge(
                        label: Text(totalNotifications.toString()),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.notifications),
                      )
                    : const Icon(Icons.notifications),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payroll',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Text('Year: ',
                              style: TextStyle(fontSize: 16)),
                          DropdownButton<int>(
                            value: selectedYear,
                            items: List.generate(
                                    5, (i) => DateTime.now().year - i)
                                .map((year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year.toString()),
                                    ))
                                .toList(),
                            onChanged: (year) async {
                              setState(() {
                                selectedYear = year!;
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
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: months.length,
                    itemBuilder: (context, index) {
                      final monthName = months[index];
                      final monthIndex = index + 1;
                      final hasPayslip = _monthlyPayments.any(
                        (p) =>
                            p.workDate.month == monthIndex &&
                            p.workDate.year == selectedYear,
                      );

                      return Card(
                        elevation: 3,
                        child: InkWell(
                          onTap: hasPayslip
                              ? () => _viewPayslip(monthName)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  monthName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasPayslip
                                      ? 'View Payslip'
                                      : 'No Payslip',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasPayslip
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                ),
                                Icon(
                                  hasPayslip
                                      ? Icons.description
                                      : Icons.block,
                                  color: hasPayslip
                                      ? Colors.blue
                                      : Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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