import 'package:flutter/material.dart';
import 'package:charms/HRmodels/payment.dart';

class EditPayrollScreen extends StatefulWidget {
  final Payment payment;
  final String staffName;
  final Function(Map<String, dynamic>) onUpdate;

  EditPayrollScreen({
    required this.payment,
    required this.staffName,
    required this.onUpdate,
  });

  @override
  _EditPayrollScreenState createState() => _EditPayrollScreenState();
}

class _EditPayrollScreenState extends State<EditPayrollScreen> {
  late TextEditingController basicPayController;
  late TextEditingController bonusController;
  late TextEditingController deductionController;
  late TextEditingController totalSalaryController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing payment data
    basicPayController = TextEditingController(text: widget.payment.basicPay.toStringAsFixed(2));
    bonusController = TextEditingController(text: widget.payment.totalBonus.toStringAsFixed(2));
    deductionController = TextEditingController(text: widget.payment.totalDeduction.toStringAsFixed(2));
    totalSalaryController = TextEditingController(text: widget.payment.totalSalary.toStringAsFixed(2));
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
      'paymentId': widget.payment.paymentId,
      'staffId': widget.payment.staffId,
      'workDate': widget.payment.workDate,
      'basicPay': double.parse(basicPayController.text),
      'totalBonus': double.parse(bonusController.text),
      'totalDeduction': double.parse(deductionController.text),
      'totalSalary': double.parse(totalSalaryController.text),
    };

    widget.onUpdate(payrollData);
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
        title: Text('Edit Payroll - ${widget.staffName}', 
          style: TextStyle(color: Colors.white),
        ),
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
                      'Period: ${widget.payment.workDate.month}/${widget.payment.workDate.year}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Staff ID: ${widget.payment.staffId}'),
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
              child: Text('Update Payroll', style: TextStyle(color: Colors.white)),
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