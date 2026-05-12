import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRscreens/admin/edit_payroll_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/payments.dart';
import 'package:charms/HRscreens/staff/staff_payroll_details_screen.dart';
import 'package:charms/HRmodels/payment.dart';
import 'package:intl/intl.dart';
import 'payroll_form_screen.dart';

class ManagePayrollScreen extends StatefulWidget {
  const ManagePayrollScreen({super.key});

  @override
  _ManagePayrollScreenState createState() => _ManagePayrollScreenState();
}

class _ManagePayrollScreenState extends State<ManagePayrollScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int selectedYear;
  late String selectedMonth;
  int _selectedCategoryIndex = 0; // 0=SEATRU, 1=CMS, 2=Intern

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  late List<String> years;

  // Category config — maps index to category int used in Staff model
  static const _categories = [
    {'label': 'SEATRU', 'value': 1},
    {'label': 'CMS',    'value': 2},
    {'label': 'Intern', 'value': 3},
  ];

  // Modern Color Palette Constants
  final Color bgColor      = const Color(0xFFF4F7FA);
  final Color primaryBlue  = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    final currentDate = DateTime.now();
    selectedYear  = currentDate.year;
    selectedMonth = DateFormat.MMMM().format(currentDate);
    years = List.generate(10, (i) => (currentDate.year - 5 + i).toString());
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final staffsProvider   = Provider.of<Staffs>(context, listen: false);
    final paymentsProvider = Provider.of<Payments>(context, listen: false);
    await staffsProvider.fetchStaff();
    await paymentsProvider.fetchPaymentsByMonth(
      selectedYear,
      months.indexOf(selectedMonth) + 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Returns only staff matching the selected category tab ──────────────────
  List<Staff> _staffForCategory(List<Staff> all) {
    final categoryValue = _categories[_selectedCategoryIndex]['value'] as int;
    return all.where((s) => s.category == categoryValue).toList();
  }

  void _addPayroll(Staff staff) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayrollFormScreen(
          staffId:     staff.staffId.toString(),
          staffName:   '${staff.firstname} ${staff.lastname}',
          workingDays: '22',
          month:       selectedMonth,
          year:        selectedYear,
          onSubmit: (payrollData) async {
            try {
              final payment = Payment(
                paymentId:      0,
                staffId:        staff.staffId,
                workDate:       DateTime(selectedYear, months.indexOf(selectedMonth) + 1, 1),
                basicPay:       payrollData['basicPay'],
                totalBonus:     payrollData['totalBonus'],
                totalDeduction: payrollData['totalDeduction'],
                totalSalary:    payrollData['totalSalary'],
                pdfPath:        null,
                createdAt:      DateTime.now(),
                status:         'published',
              );
              await Provider.of<Payments>(context, listen: false).addPayment(payment);
              await _loadInitialData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payroll added successfully!')),
              );
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add payroll: $error')),
              );
            }
          },
        ),
      ),
    ).then((_) => _loadInitialData());
  }

  void _viewPayroll(Payment payment) {
    final staffList = Provider.of<Staffs>(context, listen: false).staffList;
    final staff = staffList.firstWhere((s) => s.staffId == payment.staffId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffPayrollDetailsScreen(
          month:          selectedMonth,
          year:           selectedYear,
          staffId:        payment.staffId.toString(),
          staffName:      '${staff.firstname} ${staff.lastname}',
          workingDays:    '-',
          basicPay:       payment.basicPay,
          totalBonus:     payment.totalBonus,
          totalDeduction: payment.totalDeduction,
          totalSalary:    payment.totalSalary,
          staffCategory:  staff.category,
        ),
      ),
    );
  }

  void _editPayroll(Payment payment) {
    final staffList = Provider.of<Staffs>(context, listen: false).staffList;
    final staff = staffList.firstWhere((s) => s.staffId == payment.staffId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPayrollScreen(
          payment:   payment,
          staffName: '${staff.firstname} ${staff.lastname}',
          onUpdate: (payrollData) async {
            try {
              final updatedPayment = Payment(
                paymentId:      payrollData['paymentId'],
                staffId:        payrollData['staffId'],
                workDate:       payrollData['workDate'],
                basicPay:       payrollData['basicPay'],
                totalBonus:     payrollData['totalBonus'],
                totalDeduction: payrollData['totalDeduction'],
                totalSalary:    payrollData['totalSalary'],
                pdfPath:        payment.pdfPath,
                createdAt:      payment.createdAt,
                status:         'published',
              );
              await Provider.of<Payments>(context, listen: false).updatePayment(updatedPayment);
              await _loadInitialData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payroll updated successfully!')),
              );
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update payroll: $error')),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _deletePayroll(Payment payment) async {
    try {
      await Provider.of<Payments>(context, listen: false).deletePayment(payment.paymentId);
      await _loadInitialData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payroll deleted successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete payroll: $error')),
      );
    }
  }

  // ── Category filter chips ──────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List.generate(_categories.length, (i) {
          final isActive = _selectedCategoryIndex == i;
          final label = _categories[i]['label'] as String;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color:  isActive ? primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? primaryBlue : Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04),
                      blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.grey.shade600)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                value: selectedYear,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                items: years.map((y) => DropdownMenuItem(value: int.parse(y), child: Text(y))).toList(),
                onChanged: (value) async {
                  setState(() => selectedYear = value!);
                  await _loadInitialData();
                },
              ),
            ),
          ),
          Container(height: 30, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 16)),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                value: selectedMonth,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (value) async {
                  setState(() => selectedMonth = value!);
                  await _loadInitialData();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return Consumer2<Staffs, Payments>(
      builder: (ctx, staffsData, paymentsData, child) {
        // Filter staff by selected category first
        final categoryStaff = _staffForCategory(staffsData.staffList);

        final publishedIds = paymentsData.payments
            .where((p) =>
                p.workDate.month == (months.indexOf(selectedMonth) + 1) &&
                p.workDate.year  == selectedYear)
            .map((p) => p.staffId)
            .toSet();

        final pendingStaff = categoryStaff
            .where((s) => !publishedIds.contains(s.staffId))
            .toList();

        if (pendingStaff.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('All ${_categories[_selectedCategoryIndex]['label']} payrolls published',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: pendingStaff.length,
          itemBuilder: (context, index) {
            final staff = pendingStaff[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.pending_actions_rounded, size: 24, color: Colors.orange),
                ),
                title: Text('${staff.firstname} ${staff.lastname}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('ID: ${staff.staffId} • ${staff.occupation.isNotEmpty ? staff.occupation : "—"}',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ),
                trailing: ElevatedButton.icon(
                  onPressed: () => _addPayroll(staff),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue, foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPublishedTab() {
    return Consumer2<Staffs, Payments>(
      builder: (ctx, staffsData, paymentsData, child) {
        // Filter staff by selected category, then match payments
        final categoryStaffIds = _staffForCategory(staffsData.staffList)
            .map((s) => s.staffId)
            .toSet();

        final publishedPayments = paymentsData.payments
            .where((p) => categoryStaffIds.contains(p.staffId))
            .toList();

        if (publishedPayments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No published payrolls for ${_categories[_selectedCategoryIndex]['label']}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: publishedPayments.length,
          itemBuilder: (context, index) {
            final payment = publishedPayments[index];
            final Staff? staff = staffsData.staffList.cast<Staff?>().firstWhere(
              (s) => s?.staffId == payment.staffId, orElse: () => null);
            final displayName = staff != null
                ? '${staff.firstname} ${staff.lastname}'
                : 'Staff ID: ${payment.staffId}';

            return Container(
              margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_outline_rounded, size: 24, color: Colors.teal),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          Text('Basic Pay: RM ${payment.basicPay.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('Total Salary: RM ${payment.totalSalary.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: IconButton(
                            icon: const Icon(Icons.visibility_rounded, size: 20, color: Colors.blue),
                            tooltip: 'View',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            onPressed: () => _viewPayroll(payment),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade700),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) async {
                              if (value == 'edit')   _editPayroll(payment);
                              if (value == 'delete') _deletePayroll(payment);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit',
                                  child: Row(children: [
                                    Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit', style: TextStyle(fontWeight: FontWeight.w500)),
                                  ])),
                              const PopupMenuItem(value: 'delete',
                                  child: Row(children: [
                                    Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(fontWeight: FontWeight.w500)),
                                  ])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('MANAGE PAYROLL',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadInitialData,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(child: Text('Pending',   style: TextStyle(color: Colors.white))),
            Tab(child: Text('Published', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildCategoryChips(),   // ✅ SEATRU / CMS / Intern chips
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildPublishedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}