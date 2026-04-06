import 'package:flutter/material.dart';

class PayrollFormScreen extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String workingDays;
  final String month;
  final int year;
  final Function(Map<String, dynamic>) onSubmit;

  PayrollFormScreen({
    required this.staffId,
    required this.staffName,
    required this.workingDays,
    required this.month,
    required this.year,
    required this.onSubmit,
  });

  @override
  _PayrollFormScreenState createState() => _PayrollFormScreenState();
}

class _PayrollFormScreenState extends State<PayrollFormScreen> {
  late TextEditingController basicPayController;
  late TextEditingController bonusController;
  late TextEditingController deductionController;
  late TextEditingController totalSalaryController;

  @override
  void initState() {
    super.initState();
    basicPayController = TextEditingController();
    bonusController = TextEditingController();
    deductionController = TextEditingController();
    totalSalaryController = TextEditingController();
  }

  @override
  void dispose() {
    basicPayController.dispose();
    bonusController.dispose();
    deductionController.dispose();
    totalSalaryController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final basicPay = double.tryParse(basicPayController.text) ?? 0.0;
    final bonus = double.tryParse(bonusController.text) ?? 0.0;
    final deduction = double.tryParse(deductionController.text) ?? 0.0;

    final totalSalary = basicPay + bonus - deduction;
    totalSalaryController.text = totalSalary.toStringAsFixed(2);
  }

  void _submitForm() {
    if (!_validateForm()) return;

    final payrollData = {
      'staffId': widget.staffId,
      'staffName': widget.staffName,
      'workingDays': widget.workingDays,
      'month': widget.month,
      'year': widget.year,
      'basicPay': double.parse(basicPayController.text),
      'totalBonus': double.parse(bonusController.text),
      'totalDeduction': double.parse(deductionController.text),
      'totalSalary': double.parse(totalSalaryController.text),
    };

    widget.onSubmit(payrollData);
    Navigator.pop(context);
  }

  bool _validateForm() {
    if (basicPayController.text.isEmpty ||
        bonusController.text.isEmpty ||
        deductionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payroll Form - ${widget.staffName}', style: TextStyle(color: Colors.white),),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Period: ${widget.month} ${widget.year}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Staff ID: ${widget.staffId}'),
                    Text('Working Days: ${widget.workingDays}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildTextField('Basic Pay (RM)', basicPayController),
            SizedBox(height: 12),
            _buildTextField('Total Bonus (RM)', bonusController),
            SizedBox(height: 12),
            _buildTextField('Total Deduction (RM)', deductionController),
            SizedBox(height: 20),
            _buildTextField('Total Salary (RM)', totalSalaryController,
                isReadOnly: true),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculateTotal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Calculate Total',
                  style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  Text('Submit Payroll', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isReadOnly = false}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      readOnly: isReadOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: isReadOnly,
        fillColor: isReadOnly ? Colors.grey[200] : null,
      ),
    );
  }
}
