import 'package:flutter/material.dart';

class PayrollDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> payrollRecord;

  PayrollDetailsScreen({required this.payrollRecord});

  @override
  _PayrollDetailsScreenState createState() => _PayrollDetailsScreenState();
}

class _PayrollDetailsScreenState extends State<PayrollDetailsScreen> {
  late TextEditingController basicPayController;
  late TextEditingController grossPayController;
  late TextEditingController netSalaryController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the current payroll record data
    basicPayController = TextEditingController(text: widget.payrollRecord['basicPay'].toString());
    grossPayController = TextEditingController(text: widget.payrollRecord['grossPay'].toString());
    netSalaryController = TextEditingController(text: widget.payrollRecord['netSalary'].toString());
  }

  @override
  void dispose() {
    basicPayController.dispose();
    grossPayController.dispose();
    netSalaryController.dispose();
    super.dispose();
  }

  // Save the updated payroll details
  void _publishPayroll() {
    // Publish logic goes here (e.g., update database or notify staff)
    print('Payroll published for ${widget.payrollRecord['staffName']}');
    // For now, just showing the updated data
    print('Updated Basic Pay: ${basicPayController.text}');
    print('Updated Gross Pay: ${grossPayController.text}');
    print('Updated Net Salary: ${netSalaryController.text}');
    // You can use a dialog to show a confirmation message to the admin
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payroll Details for ${widget.payrollRecord['staffName']}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: basicPayController,
              decoration: InputDecoration(labelText: 'Basic Pay'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: grossPayController,
              decoration: InputDecoration(labelText: 'Gross Pay'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: netSalaryController,
              decoration: InputDecoration(labelText: 'Net Salary'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _publishPayroll,
              child: Text('Publish to Staff'),
            ),
          ],
        ),
      ),
    );
  }
}
