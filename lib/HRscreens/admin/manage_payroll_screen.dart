import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRscreens/admin/edit_payroll_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/payments.dart';
import 'package:charms/HRscreens/staff/staff_payroll_details_screen.dart';
import 'package:charms/HRmodels/payment.dart';
import 'payroll_form_screen.dart';

class ManagePayrollScreen extends StatefulWidget {
  @override
  _ManagePayrollScreenState createState() => _ManagePayrollScreenState();
}

class _ManagePayrollScreenState extends State<ManagePayrollScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedYear = 2024;
  String selectedMonth = 'January';

  final List<String> years =
      List.generate(10, (index) => (2024 + index).toString());
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final staffsProvider = Provider.of<Staffs>(context, listen: false);
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

  void _addPayroll(Staff staff) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayrollFormScreen(
          staffId: staff.staffId.toString(),
          staffName: '${staff.firstname} ${staff.lastname}',
          workingDays: '22', // You might want to calculate this
          month: selectedMonth,
          year: selectedYear,
          onSubmit: (payrollData) async {
            try {
              final payment = Payment(
                paymentId: 0,
                staffId: staff.staffId,
                workDate: DateTime(
                    selectedYear, months.indexOf(selectedMonth) + 1, 1),
                basicPay: payrollData['basicPay'],
                totalBonus: payrollData['totalBonus'],
                totalDeduction: payrollData['totalDeduction'],
                totalSalary: payrollData['totalSalary'],
                pdfPath: null,
                createdAt: DateTime.now(),
                status: 'published', // Set initial status
              );

              await Provider.of<Payments>(context, listen: false)
                  .addPayment(payment);
              await _loadInitialData();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payroll added successfully!')),
              );
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add payroll: $error')),
              );
            }
          },
        ),
      ),
    );
  }

  void _viewPayroll(Payment payment) async {
    // Get the staff details from the Staffs provider
    final staffsProvider = Provider.of<Staffs>(context, listen: false);
    final staffList = staffsProvider.staffList;
    final staff = staffList.firstWhere((s) => s.staffId == payment.staffId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffPayrollDetailsScreen(
          month: selectedMonth,
          year: selectedYear,
          staffId: payment.staffId.toString(),
          staffName: '${staff.firstname} ${staff.lastname}',
          workingDays: '-',
          basicPay: payment.basicPay,
          totalBonus: payment.totalBonus,
          totalDeduction: payment.totalDeduction,
          totalSalary: payment.totalSalary,
        ),
      ),
    );
  }

  void _editPayroll(Payment payment) {
  final staffsProvider = Provider.of<Staffs>(context, listen: false);
  final staff = staffsProvider.staffList.firstWhere((s) => s.staffId == payment.staffId);
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditPayrollScreen(
        payment: payment,
        staffName: '${staff.firstname} ${staff.lastname}',
        onUpdate: (payrollData) async {
          try {
            final updatedPayment = Payment(
              paymentId: payrollData['paymentId'],
              staffId: payrollData['staffId'],
              workDate: payrollData['workDate'],
              basicPay: payrollData['basicPay'],
              totalBonus: payrollData['totalBonus'],
              totalDeduction: payrollData['totalDeduction'],
              totalSalary: payrollData['totalSalary'],
              pdfPath: payment.pdfPath,
              createdAt: payment.createdAt,
              status: 'published',
            );

            await Provider.of<Payments>(context, listen: false)
                .updatePayment(updatedPayment);
            await _loadInitialData();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payroll updated successfully!')),
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
      await Provider.of<Payments>(context, listen: false)
          .deletePayment(payment.paymentId);
      await _loadInitialData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payroll deleted successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete payroll: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        title: Text('Manage Payroll', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(child: Text('Pending', style: TextStyle(color: Colors.white))),
            Tab(
                child:
                    Text('Published', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
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

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<int>(
            value: selectedYear,
            items: years.map((year) {
              return DropdownMenuItem(
                value: int.parse(year),
                child: Text(year),
              );
            }).toList(),
            onChanged: (value) async {
              setState(() => selectedYear = value!);
              await _loadInitialData();
            },
          ),
          SizedBox(width: 20),
          DropdownButton<String>(
            value: selectedMonth,
            items: months.map((month) {
              return DropdownMenuItem(
                value: month,
                child: Text(month),
              );
            }).toList(),
            onChanged: (value) async {
              setState(() => selectedMonth = value!);
              await _loadInitialData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return Consumer2<Staffs, Payments>(
      builder: (ctx, staffsData, paymentsData, child) {
        final staffList = staffsData.staffList;

        // Debug prints to verify data
        print('Selected Month: $selectedMonth, Year: $selectedYear');
        print(
            'All Payments: ${paymentsData.payments.map((p) => 'StaffID: ${p.staffId}, Month: ${p.workDate.month}')}');

        // Filter payments for current month and year
        final publishedPaymentsForMonth = paymentsData.payments
            .where((payment) {
              final isCurrentMonth =
                  payment.workDate.month == (months.indexOf(selectedMonth) + 1);
              final isCurrentYear = payment.workDate.year == selectedYear;
              return isCurrentMonth && isCurrentYear;
            })
            .map((payment) => payment.staffId)
            .toList();

        // Filter out staff with published payrolls
        final pendingStaff = staffList
            .where(
                (staff) => !publishedPaymentsForMonth.contains(staff.staffId))
            .toList();

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: pendingStaff.length,
          itemBuilder: (context, index) {
            final staff = pendingStaff[index];
            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('${staff.firstname} ${staff.lastname}'),
                subtitle: Text('ID: ${staff.staffId} | ${staff.occupation}'),
                trailing: ElevatedButton(
                  onPressed: () => _addPayroll(staff),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Add Payroll'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPublishedTab() {
    return Consumer<Payments>(
      builder: (ctx, paymentsData, child) {
        print('Total payments: ${paymentsData.payments.length}');

        final publishedPayments = paymentsData.payments;
        print('Published payments: ${publishedPayments.length}');

        return publishedPayments.isEmpty
            ? Center(child: Text('No published payrolls yet'))
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: publishedPayments.length,
                itemBuilder: (context, index) {
                  final payment = publishedPayments[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('Staff ID: ${payment.staffId}'),
                      subtitle: Text(
                        'Basic Pay: RM ${payment.basicPay.toStringAsFixed(2)}\n'
                        'Total Salary: RM ${payment.totalSalary.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.visibility),
                            onPressed: () => _viewPayroll(payment),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editPayroll(payment),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _deletePayroll(payment),
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
}
