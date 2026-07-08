import 'package:flutter/material.dart';
import 'package:charms/HRmodels/payment.dart';
import 'package:charms/HRwidgets/admin/hr_theme.dart';
import 'package:intl/intl.dart'; // ✅ Added for nicer date formatting

class EditPayrollScreen extends StatefulWidget {
  final Payment payment;
  final String staffName;
  final Function(Map<String, dynamic>) onUpdate;

  const EditPayrollScreen({
    super.key,
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

  // Modern Color Palette Constants
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

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
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final periodString = DateFormat('MMMM yyyy').format(widget.payment.workDate);

    return Scaffold(
      backgroundColor: bgColor, // Modern background
      appBar: const HRAppBar(title: 'EDIT PAYMENT REPORT'),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: HRPageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // Header Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_document, size: 32, color: primaryBlue),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.staffName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Staff ID: ${widget.payment.staffId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 18, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          'Period: $periodString',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
              child: Text(
                'Earnings & Deductions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            
            _buildTextField('Basic Pay (RM)', basicPayController, Icons.attach_money_rounded),
            const SizedBox(height: 16),
            
            _buildTextField('Total Bonus (RM)', bonusController, Icons.add_circle_outline_rounded, isAddition: true),
            const SizedBox(height: 16),
            
            _buildTextField('Total Deduction (RM)', deductionController, Icons.remove_circle_outline_rounded, isDeduction: true),
            const SizedBox(height: 24),

            // Total Salary Field (Styled distinctly)
            _buildTextField('Total Salary (RM)', totalSalaryController, Icons.account_balance_wallet_rounded, isReadOnly: true),
            
            const SizedBox(height: 32),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: _calculateTotal,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue.withOpacity(0.1),
                foregroundColor: primaryBlue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.calculate_rounded),
              label: const Text(
                'Calculate Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Modern green replacement
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.update_rounded),
              label: const Text(
                'Update Payroll',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
        ),
      ),
    );
  }

  // Modernized helper function to create text fields
  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    IconData icon,
    {bool isReadOnly = false, bool isAddition = false, bool isDeduction = false}
  ) {
    
    // Determine icon color based on field type
    Color iconColor = primaryBlue.withOpacity(0.7);
    if (isAddition) iconColor = Colors.teal;
    if (isDeduction) iconColor = Colors.redAccent;
    if (isReadOnly) iconColor = Colors.grey.shade600;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      readOnly: isReadOnly,
      style: TextStyle(
        fontSize: 16,
        fontWeight: isReadOnly ? FontWeight.bold : FontWeight.normal,
        color: isReadOnly ? primaryBlue : const Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600, 
          fontSize: 14,
          fontWeight: isReadOnly ? FontWeight.bold : FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: iconColor, size: 22),
        filled: true,
        fillColor: isReadOnly ? primaryBlue.withOpacity(0.05) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isReadOnly ? primaryBlue.withOpacity(0.3) : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }
}